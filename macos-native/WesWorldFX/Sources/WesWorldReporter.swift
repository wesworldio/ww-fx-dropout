import Foundation

/// Complete crash reporting and error logging solution for ww-fx-dropout
/// 
/// Usage in AppDelegate:
/// ```swift
/// let reporter = WesWorldReporter.shared
/// reporter.setupCrashHandlers()
/// ```
/// 
/// Logging an error:
/// ```swift
/// Task {
///     try? await WesWorldReporter.shared.logError("Operation failed", error)
/// }
/// ```

class WesWorldReporter {
    // MARK: - Singleton
    
    static let shared = WesWorldReporter()
    
    // MARK: - Properties
    
    private let serverURL: String
    private let productName = "ww-fx-dropout"
    private let version: String
    private let apiKey: String
    private let offlineCache: OfflineLogCache
    private var logQueue: LogQueue?
    
    // MARK: - Initialization
    
    init(
        serverURL: String? = nil,
        apiKey: String? = nil,
        version: String = "2.1.3 (Build 210)"
    ) {
        // Try to load from config file first, then environment variables, then defaults
        let config = Self.loadConfig()
        self.serverURL = serverURL ?? config?.serverURL ?? ProcessInfo.processInfo.environment["WW_LOGS_URL"] ?? "https://ww-logs.wesworld.workers.dev/api/logs"
        self.apiKey = apiKey ?? config?.apiKey ?? ProcessInfo.processInfo.environment["WW_LOGS_API_KEY"] ?? "ww-fx-dropout-prod-2026-01-01"
        self.version = version
        do {
            self.offlineCache = try OfflineLogCache()
            self.logQueue = LogQueue(
                crashReporter: self,
                maxQueueSize: 50
            )
        } catch {
            print("⚠️  Failed to initialize offline cache: \(error)")
            self.offlineCache = try! OfflineLogCache() // Force initialization
        }
        print("✅ WesWorld Reporter initialized")
        print("   Server: \(self.serverURL)")
        print("   Product: \(productName) v\(version)")
    }
    
    // MARK: - Configuration
    
    private static func loadConfig() -> LoggingConfig? {
        guard let url = Bundle.main.url(forResource: "logging-config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(LoggingConfig.self, from: data) else {
            return nil
        }
        return config
    }
    
    private struct LoggingConfig: Codable {
        let serverURL: String
        let apiKey: String
    }
    
    // MARK: - Setup
    
    /// Call this in applicationDidFinishLaunching to enable crash handling
    func setupCrashHandlers() {
        NSSetUncaughtExceptionHandler { exception in
            WesWorldReporter.shared.handleUncaughtException(exception)
        }
        
        // Handle common signals
        signal(SIGSEGV) { _ in
            WesWorldReporter.shared.saveLogSynchronously("SIGSEGV: Segmentation fault")
        }
        signal(SIGBUS) { _ in
            WesWorldReporter.shared.saveLogSynchronously("SIGBUS: Bus error")
        }
        
        // Try to submit any pending logs from previous crashes
        submitPendingLogs()
        
        print("✅ WesWorld crash handlers initialized")
    }
    
    // MARK: - Exception Handling
    
    private func handleUncaughtException(_ exception: NSException) {
        let crashLog = formatCrashLog(exception)
        saveLogSynchronously(crashLog)
        
        // Try to submit synchronously if possible
        print("💥 Unhandled exception caught: \(exception.name.rawValue)")
        print("   Reason: \(exception.reason ?? "Unknown")")
        print("   Log saved for submission on next launch")
    }
    
    // MARK: - Logging Methods
    
    /// Submit a crash log
    func logCrash(
        exception: NSException,
        additionalInfo: [String: String] = [:]
    ) async {
        let crashLog = formatCrashLog(exception)
        
        do {
            var metadata: [String: String] = [
                "exceptionName": exception.name.rawValue,
                "reason": exception.reason ?? "Unknown"
            ]
            metadata.merge(additionalInfo) { (_, new) in new }
            
            try await submitLog(
                logs: crashLog,
                logType: "crash",
                metadata: metadata
            )
        } catch {
            saveLogSynchronously(crashLog)
            print("⚠️  Failed to submit crash, saved locally: \(error)")
        }
    }
    
    /// Submit an error log
    func logError(
        _ message: String,
        _ error: Error,
        additionalInfo: [String: String] = [:]
    ) async {
        let errorLog = formatErrorLog(message, error)
        
        do {
            var metadata: [String: String] = [
                "errorType": "\(type(of: error))",
                "message": message
            ]
            metadata.merge(additionalInfo) { (_, new) in new }
            
            try await submitLog(
                logs: errorLog,
                logType: "error",
                metadata: metadata
            )
        } catch {
            print("⚠️  Failed to submit error log: \(error)")
        }
    }
    
    /// Submit a warning log
    func logWarning(
        _ message: String,
        additionalInfo: [String: String] = [:]
    ) async {
        let warningLog = formatWarningLog(message)
        
        do {
            try await submitLog(
                logs: warningLog,
                logType: "warning",
                metadata: additionalInfo
            )
        } catch {
            print("⚠️  Failed to submit warning log: \(error)")
        }
    }
    
    /// Submit an info log
    func logInfo(
        _ message: String,
        additionalInfo: [String: String] = [:]
    ) async {
        let infoLog = formatInfoLog(message)
        
        do {
            try await submitLog(
                logs: infoLog,
                logType: "info",
                metadata: additionalInfo
            )
        } catch {
            // Don't spam errors for info logs, just queue them
            logQueue?.addLog(infoLog)
        }
    }
    
    // MARK: - Private Log Submission
    
    fileprivate func submitLog(
        logs: String,
        logType: String,
        metadata: [String: String]
    ) async throws {
        guard let url = URL(string: serverURL) else {
            throw LoggingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 10
        
        var submissionMetadata: [String: String] = [
            "logType": logType,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        submissionMetadata.merge(metadata) { (_, new) in new }
        
        let submission = LogSubmission(
            product: productName,
            version: version,
            platform: "macOS",
            deviceId: getDeviceId(),
            deviceInfo: getDeviceInfo(),
            logs: logs,
            metadata: submissionMetadata
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(submission)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LoggingError.invalidResponse
        }
        
        guard httpResponse.statusCode == 202 else {
            if let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw LoggingError.serverError(errorBody.error)
            }
            throw LoggingError.submissionFailed(httpResponse.statusCode)
        }
    }
    
    // MARK: - Formatting
    
    private func formatCrashLog(_ exception: NSException) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: Date())
        let bundleId = Bundle.main.bundleIdentifier ?? "Unknown"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown"
        let stackTrace = exception.callStackSymbols.joined(separator: "\n")
        
        return """
        CRASH REPORT
        ============
        
        Time: \(timestamp)
        App: \(bundleId)
        Version: \(appVersion)
        Device: \(getDeviceId())
        
        Exception: \(exception.name.rawValue)
        Reason: \(exception.reason ?? "Unknown")
        
        Stack Trace:
        \(stackTrace)
        """
    }
    
    private func formatErrorLog(_ message: String, _ error: Error) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: Date())
        
        return """
        ERROR LOG
        =========
        
        Time: \(timestamp)
        
        Message: \(message)
        Error: \(error.localizedDescription)
        
        Details:
        \(String(describing: error))
        """
    }
    
    private func formatWarningLog(_ message: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: Date())
        
        return """
        WARNING LOG
        ===========
        
        Time: \(timestamp)
        
        Message: \(message)
        """
    }
    
    private func formatInfoLog(_ message: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: Date())
        
        return """
        INFO LOG
        ========
        
        Time: \(timestamp)
        
        Message: \(message)
        """
    }
    
    // MARK: - Device Information
    
    private func getDeviceInfo() -> DeviceInfo {
        let processInfo = ProcessInfo.processInfo
        
        // Get model
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let modelString = String(cString: model)
        
        // Get OS version
        let os = processInfo.operatingSystemVersionString
        
        // Get memory
        let memoryGB = String(format: "%.0fGB", Double(processInfo.physicalMemory) / 1024 / 1024 / 1024)
        
        // Get processor
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
        if let serial = getSystemSerialNumber() {
            return serial
        }
        
        let defaults = UserDefaults.standard
        let key = "com.wesworld.ww-fx-dropout.deviceId"
        
        if let stored = defaults.string(forKey: key) {
            return stored
        }
        
        let newId = UUID().uuidString
        defaults.set(newId, forKey: key)
        return newId
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
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            
            for line in output.components(separatedBy: "\n") {
                if line.contains("Serial Number") {
                    if let serial = line.components(separatedBy: ": ").last {
                        return serial.trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    // MARK: - Pending Logs
    
    private func submitPendingLogs() {
        Task {
            do {
                let pendingURLs = try offlineCache.getPendingLogs()
                
                for url in pendingURLs {
                    do {
                        let content = try String(contentsOf: url, encoding: .utf8)
                        try await submitLog(
                            logs: content,
                            logType: "pending",
                            metadata: [:]
                        )
                        try offlineCache.removePendingLog(url)
                        print("✅ Submitted pending log: \(url.lastPathComponent)")
                    } catch {
                        print("⚠️  Failed to submit pending log: \(error)")
                    }
                }
            } catch {
                print("⚠️  Failed to retrieve pending logs: \(error)")
            }
        }
    }
    
    func saveLogSynchronously(_ logContent: String) {
        do {
            try offlineCache.savePendingLog(logContent)
        } catch {
            print("❌ Failed to save log: \(error)")
        }
    }
    
    // MARK: - Manual Flush
    
    func flushPendingLogs() async {
        logQueue?.flushLogs()
        submitPendingLogs()
    }
}

// MARK: - Data Models

struct LogSubmission: Codable {
    let product: String
    let version: String
    let platform: String
    let deviceId: String
    let deviceInfo: DeviceInfo
    let logs: String
    let metadata: [String: String]
}

struct DeviceInfo: Codable {
    let model: String
    let os: String
    let memory: String
    let processor: String
}

struct ErrorResponse: Codable {
    let error: String
}

enum LoggingError: Error {
    case invalidURL
    case invalidResponse
    case submissionFailed(Int)
    case serverError(String)
}

// MARK: - Log Queue

class LogQueue {
    private var pendingLogs: [String] = []
    private let crashReporter: WesWorldReporter
    private let maxQueueSize: Int
    
    init(crashReporter: WesWorldReporter, maxQueueSize: Int = 50) {
        self.crashReporter = crashReporter
        self.maxQueueSize = maxQueueSize
    }
    
    func addLog(_ log: String) {
        pendingLogs.append(log)
        
        if pendingLogs.count >= maxQueueSize {
            flushLogs()
        }
    }
    
    func flushLogs() {
        guard !pendingLogs.isEmpty else { return }
        
        let combined = pendingLogs.joined(separator: "\n---\n")
        pendingLogs.removeAll()
        
        Task {
            do {
                try await crashReporter.submitLog(
                    logs: combined,
                    logType: "batch",
                    metadata: [:]
                )
            } catch {
                crashReporter.saveLogSynchronously(combined)
            }
        }
    }
}

// MARK: - Offline Cache

class OfflineLogCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() throws {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        cacheDirectory = appSupport.appendingPathComponent("ww-fx-dropout/logs")
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func savePendingLog(_ log: String) throws {
        let timestamp = Date().timeIntervalSince1970
        let filename = "log-\(timestamp).json"
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        try log.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func getPendingLogs() throws -> [URL] {
        try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix("log-") }
    }
    
    func removePendingLog(_ url: URL) throws {
        try fileManager.removeItem(at: url)
    }
}
