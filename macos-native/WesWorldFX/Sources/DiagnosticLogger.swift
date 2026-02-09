import Foundation
import AppKit

/// Comprehensive diagnostic logging system for WesWorldFX
/// Logs crashes, errors, performance metrics, and system information
class DiagnosticLogger {
    static let shared = DiagnosticLogger()
    
    private let fileManager = FileManager.default
    private let logQueue = DispatchQueue(label: "com.wesworldfx.logging", attributes: .concurrent)
    private var logFileURL: URL
    private var sessionStartTime: Date
    
    // MARK: - Initialization
    
    private init() {
        // Create logs directory in Application Support
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let logsDirectory = appSupportURL.appendingPathComponent("WesWorldFX/Logs", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create logs directory: \(error)")
        }
        
        // Create session log file with timestamp
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        let sessionID = UUID().uuidString.prefix(8)
        
        logFileURL = logsDirectory.appendingPathComponent("WesWorldFX_\(timestamp)_\(sessionID).log")
        sessionStartTime = Date()
        
        // Write initial diagnostic header
        writeSessionHeader()
        
        // Set up crash handler
        setupCrashHandler()
    }
    
    // MARK: - Public API
    
    /// Log an info message
    func info(_ message: String, category: String = "INFO") {
        log(level: "INFO", category: category, message: message)
    }
    
    /// Log a warning message
    func warning(_ message: String, category: String = "WARNING") {
        log(level: "WARN", category: category, message: message)
    }
    
    /// Log an error message
    func error(_ message: String, error: Error? = nil, category: String = "ERROR") {
        var fullMessage = message
        if let error = error {
            fullMessage += "\n  Error Details: \(error.localizedDescription)"
            let nsError = error as NSError
            fullMessage += "\n  Domain: \(nsError.domain), Code: \(nsError.code)"
            if let userInfo = nsError.userInfo as? [String: Any], !userInfo.isEmpty {
                fullMessage += "\n  User Info: \(userInfo)"
            }
        }
        log(level: "ERROR", category: category, message: fullMessage)
        
        // Submit to WesWorld logging system
        if let error = error {
            Task {
                await WesWorldReporter.shared.logError(message, error, additionalInfo: ["category": category])
            }
        }
    }
    
    /// Log a critical error (crash-level)
    func critical(_ message: String, error: Error? = nil, stackTrace: [String]? = nil) {
        var fullMessage = message
        if let error = error {
            fullMessage += "\n  Exception: \(error.localizedDescription)"
        }
        if let stackTrace = stackTrace {
            fullMessage += "\n  Stack Trace:\n    " + stackTrace.joined(separator: "\n    ")
        }
        log(level: "CRITICAL", category: "CRASH", message: fullMessage)
        
        // Submit critical errors to WesWorld immediately
        if let error = error {
            Task {
                await WesWorldReporter.shared.logError(message, error, additionalInfo: ["level": "critical"])
            }
        } else {
            Task {
                await WesWorldReporter.shared.logWarning(fullMessage, additionalInfo: ["level": "critical"])
            }
        }
    }
    
    /// Log performance metrics
    func logPerformance(operation: String, duration: TimeInterval, details: [String: Any]? = nil) {
        var message = "\(operation) took \(String(format: "%.3f", duration))ms"
        if let details = details {
            for (key, value) in details {
                message += "\n  \(key): \(value)"
            }
        }
        log(level: "PERF", category: "PERFORMANCE", message: message)
    }
    
    /// Log system status snapshot
    func logSystemStatus() {
        let cpuUsage = getCPUUsage()
        let memoryUsage = getMemoryUsage()
        let systemInfo = getSystemInfo()
        
        var message = "System Status:\n"
        message += "  CPU Usage: \(String(format: "%.1f", cpuUsage))%\n"
        message += "  Memory Usage: \(String(format: "%.1f", memoryUsage.usedPercent))% (\(formatBytes(memoryUsage.usedBytes))/\(formatBytes(memoryUsage.totalBytes)))\n"
        message += "  System: \(systemInfo)\n"
        message += "  Uptime: \(formatUptime())"
        
        log(level: "STATUS", category: "SYSTEM", message: message)
    }
    
    /// Log camera status
    func logCameraStatus(status: String, details: [String: Any]? = nil) {
        var message = "Camera: \(status)"
        if let details = details {
            for (key, value) in details {
                message += "\n  \(key): \(value)"
            }
        }
        log(level: "INFO", category: "CAMERA", message: message)
    }
    
    /// Log filter operation
    func logFilterOperation(filterName: String, duration: TimeInterval, frameCount: Int = 1) {
        let fps = 1000.0 / duration // ms to fps
        let message = "\(filterName): \(String(format: "%.3f", duration))ms (\(String(format: "%.1f", fps)) fps)"
        log(level: "PERF", category: "FILTER", message: message)
    }
    
    /// Get the log file URL for external access
    func getLogFileURL() -> URL {
        return logFileURL
    }
    
    /// Open logs directory in Finder
    func openLogsInFinder() {
        let logsDirectory = logFileURL.deletingLastPathComponent()
        NSWorkspace.shared.open(logsDirectory)
    }
    
    /// Get recent logs (last N lines)
    func getRecentLogs(lineCount: Int = 100) -> String {
        guard let content = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            return "Unable to read log file"
        }
        
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        let recentLines = lines.suffix(lineCount)
        return recentLines.joined(separator: "\n")
    }
    
    // MARK: - Private Implementation
    
    private func writeSessionHeader() {
        var header = "═══════════════════════════════════════════════════════════════\n"
        header += "WesWorldFX Debug Log Session\n"
        header += "═══════════════════════════════════════════════════════════════\n"
        header += "Session Start: \(Date())\n"
        header += "Session ID: \(logFileURL.lastPathComponent)\n"
        header += "App Version: \(getAppVersion())\n"
        header += "Build: \(getBuildNumber())\n"
        
        let systemInfo = getSystemInfo()
        header += "System: \(systemInfo)\n"
        
        let memoryInfo = getMemoryUsage()
        header += "Total RAM: \(formatBytes(memoryInfo.totalBytes))\n"
        
        header += "═══════════════════════════════════════════════════════════════\n\n"
        
        logQueue.async(flags: .barrier) {
            do {
                try header.write(to: self.logFileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to write log header: \(error)")
            }
        }
    }
    
    private func log(level: String, category: String, message: String) {
        logQueue.async(flags: .barrier) {
            let timestamp = self.formatTimestamp()
            let logLine = "[\(timestamp)] [\(level)] [\(category)] \(message)\n"
            
            // Write to file
            self.writeLogLine(logLine)
            
            // Also print to console during development
            print(logLine.trimmingCharacters(in: .newlines))
        }
    }
    
    private func writeLogLine(_ line: String) {
        do {
            if let fileHandle = FileHandle(forWritingAtPath: logFileURL.path) {
                fileHandle.seekToEndOfFile()
                if let data = line.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                // File doesn't exist yet, create it
                try line.write(toFile: logFileURL.path, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
    
    private func setupCrashHandler() {
        // Set up uncaught exception handler
        NSSetUncaughtExceptionHandler { exception in
            DiagnosticLogger.shared.critical(
                "Uncaught Exception",
                error: NSError(domain: exception.name.rawValue, code: 0),
                stackTrace: exception.callStackSymbols
            )
        }
    }
    
    // MARK: - System Information Helpers
    
    func getCPUUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount: mach_msg_type_number_t = 0
        
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)
        
        if threadsResult == KERN_SUCCESS {
            if let threadsList = threadsList {
                for index in 0..<threadsCount {
                    var threadInfo = thread_basic_info()
                    var count = mach_msg_type_number_t(THREAD_INFO_MAX)
                    
                    let infoResult = withUnsafeMutablePointer(to: &threadInfo) { pointer in
                        thread_info(
                            threadsList[Int(index)],
                            thread_flavor_t(THREAD_BASIC_INFO),
                            UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: integer_t.self),
                            &count
                        )
                    }
                    
                    if infoResult == KERN_SUCCESS {
                        let cpuUsage = Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                        totalUsageOfCPU += cpuUsage
                    }
                }
                
                vm_deallocate(
                    mach_task_self_,
                    vm_address_t(bitPattern: threadsList),
                    vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride)
                )
            }
        }
        
        return totalUsageOfCPU
    }
    
    func getMemoryUsage() -> (usedBytes: UInt64, totalBytes: UInt64, usedPercent: Double) {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size)/4
        
        _ = withUnsafeMutablePointer(to: &info) { pointer in
            task_info(
                mach_task_self_,
                task_flavor_t(TASK_VM_INFO),
                UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: integer_t.self),
                &count
            )
        }
        
        var totalMemory: UInt64 = 0
        if let hostBasicInfo = ProcessInfo.processInfo.physicalMemory as UInt64? {
            totalMemory = hostBasicInfo
        }
        
        let usedMemory = UInt64(info.phys_footprint)
        let usedPercent = totalMemory > 0 ? (Double(usedMemory) / Double(totalMemory)) * 100.0 : 0
        
        return (usedMemory, totalMemory, usedPercent)
    }
    
    private func getSystemInfo() -> String {
        let processInfo = ProcessInfo.processInfo
        let model = getMacModel()
        return "\(model) macOS \(processInfo.operatingSystemVersionString)"
    }
    
    func getMacModel() -> String {
        var modelIdentifier = ""
        let task = Process()
        task.launchPath = "/usr/sbin/sysctl"
        task.arguments = ["hw.model"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let parts = output.split(separator: ":")
                if parts.count > 1 {
                    modelIdentifier = String(parts[1]).trimmingCharacters(in: .whitespaces)
                }
            }
        } catch {
            modelIdentifier = "Unknown"
        }
        
        return modelIdentifier
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private func formatTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
    private func formatUptime() -> String {
        let uptime = Date().timeIntervalSince(sessionStartTime)
        let hours = Int(uptime / 3600)
        let minutes = Int((uptime.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(uptime.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - System Monitoring Extension

extension DiagnosticLogger {
    /// Periodically log system status
    func startPeriodicMonitoring(interval: TimeInterval = 60) {
        DispatchQueue.global().asyncAfter(deadline: .now() + interval) { [weak self] in
            self?.logSystemStatus()
            self?.startPeriodicMonitoring(interval: interval)
        }
    }
}
