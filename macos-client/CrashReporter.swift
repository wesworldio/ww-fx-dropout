import Foundation

/// CrashReporter - Submit crash logs to WesWorld Logs
///
/// Drop this class into your macOS app to easily submit crash reports.
///
/// Usage:
/// ```swift
/// let reporter = CrashReporter(
///     serverURL: "https://your-worker.workers.dev/api/logs",
///     productName: "YourApp",
///     version: "1.0.0"
/// )
///
/// Task {
///     try await reporter.submitLog(logs: crashLogString)
/// }
/// ```
@available(macOS 10.15, *)
public class CrashReporter {
    
    // MARK: - Configuration
    
    public let serverURL: String
    public let productName: String
    public let version: String
    public var timeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    public init(serverURL: String, productName: String, version: String) {
        self.serverURL = serverURL
        self.productName = productName
        self.version = version
    }
    
    // MARK: - Public API
    
    /// Submit a crash log to the server
    /// - Parameters:
    ///   - logs: The crash log content (string or structured data)
    ///   - metadata: Optional metadata to include
    /// - Throws: Network or encoding errors
    public func submitLog(logs: String, metadata: [String: String] = [:]) async throws {
        try await submitLog(logs: logs, metadata: metadata, retryCount: 0)
    }
    
    /// Submit a structured log entry
    /// - Parameters:
    ///   - logs: The log data as a dictionary
    ///   - metadata: Optional metadata to include
    /// - Throws: Network or encoding errors
    public func submitLog(logs: [String: Any], metadata: [String: String] = [:]) async throws {
        let jsonData = try JSONSerialization.data(withJSONObject: logs)
        let logsString = String(data: jsonData, encoding: .utf8) ?? ""
        try await submitLog(logs: logsString, metadata: metadata)
    }
    
    // MARK: - Private Implementation
    
    private func submitLog(logs: String, metadata: [String: String], retryCount: Int) async throws {
        guard let url = URL(string: serverURL) else {
            throw CrashReporterError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        
        let submission = LogSubmission(
            product: productName,
            version: version,
            platform: "macOS",
            deviceId: getDeviceId(),
            deviceInfo: getDeviceInfo(),
            logs: logs,
            metadata: metadata
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(submission)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CrashReporterError.invalidResponse
            }
            
            if httpResponse.statusCode == 202 {
                // Success
                let logResponse = try JSONDecoder().decode(LogResponse.self, from: data)
                print("[CrashReporter] Log submitted: \(logResponse.id)")
            } else if httpResponse.statusCode >= 500 && retryCount < 3 {
                // Retry on server errors
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                try await submitLog(logs: logs, metadata: metadata, retryCount: retryCount + 1)
            } else {
                throw CrashReporterError.submissionFailed(statusCode: httpResponse.statusCode)
            }
        } catch let error as CrashReporterError {
            throw error
        } catch {
            throw CrashReporterError.networkError(error)
        }
    }
    
    private func getDeviceInfo() -> DeviceInfo {
        let processInfo = ProcessInfo.processInfo
        
        // Model
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let modelString = String(cString: model)
        
        // OS version
        let os = processInfo.operatingSystemVersionString
        
        // Memory
        let memoryGB = String(format: "%.0fGB", 
                             Double(processInfo.physicalMemory) / 1024 / 1024 / 1024)
        
        // Processor
        var processorBrand = [CChar](repeating: 0, count: 256)
        var brandSize = 256
        sysctlbyname("machdep.cpu.brand_string", &processorBrand, &brandSize, nil, 0)
        let processor = String(cString: processorBrand)
        
        return DeviceInfo(
            model: modelString,
            os: os,
            memory: memoryGB,
            processor: processor
        )
    }
    
    private func getDeviceId() -> String {
        // Try to get system serial number for unique device ID
        if let serial = getSystemSerialNumber() {
            return serial
        }
        
        // Fallback to UUID
        return UUID().uuidString
    }
    
    private func getSystemSerialNumber() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: "\n") {
                    if line.contains("Serial Number") {
                        if let serial = line.components(separatedBy: ": ").last {
                            return serial.trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    // MARK: - Data Models
    
    private struct LogSubmission: Codable {
        let product: String
        let version: String
        let platform: String
        let deviceId: String
        let deviceInfo: DeviceInfo
        let logs: String
        let metadata: [String: String]
    }
    
    private struct DeviceInfo: Codable {
        let model: String
        let os: String
        let memory: String
        let processor: String
    }
    
    private struct LogResponse: Codable {
        let status: String
        let id: String
    }
}

// MARK: - Errors

public enum CrashReporterError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case submissionFailed(statusCode: Int)
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .submissionFailed(let code):
            return "Log submission failed with status code: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Convenience Extensions

@available(macOS 10.15, *)
extension CrashReporter {
    
    /// Install an uncaught exception handler that submits crashes
    /// Call this early in your app lifecycle
    public func installExceptionHandler() {
        NSSetUncaughtExceptionHandler { [weak self] exception in
            guard let self = self else { return }
            
            let crashLog = """
            Exception: \(exception.name.rawValue)
            Reason: \(exception.reason ?? "Unknown")
            
            Stack Trace:
            \(exception.callStackSymbols.joined(separator: "\n"))
            """
            
            // Save to file for next launch (don't submit during crash)
            self.savePendingLog(crashLog)
        }
    }
    
    /// Submit any pending logs from previous crashes
    /// Call this at app startup
    public func submitPendingLogs() async {
        let pendingLogs = loadPendingLogs()
        
        for log in pendingLogs {
            do {
                try await submitLog(logs: log)
                removePendingLog(log)
            } catch {
                print("[CrashReporter] Failed to submit pending log: \(error)")
            }
        }
    }
    
    // MARK: - Persistence
    
    private func savePendingLog(_ log: String) {
        let fileURL = getPendingLogsDirectory()
            .appendingPathComponent("\(UUID().uuidString).log")
        
        try? log.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func loadPendingLogs() -> [String] {
        let directory = getPendingLogsDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        
        return files.compactMap { url in
            try? String(contentsOf: url, encoding: .utf8)
        }
    }
    
    private func removePendingLog(_ log: String) {
        let directory = getPendingLogsDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        
        for file in files {
            if let content = try? String(contentsOf: file, encoding: .utf8),
               content == log {
                try? FileManager.default.removeItem(at: file)
                break
            }
        }
    }
    
    private func getPendingLogsDirectory() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        
        let directory = appSupport
            .appendingPathComponent(productName)
            .appendingPathComponent("PendingCrashLogs")
        
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        
        return directory
    }
}
