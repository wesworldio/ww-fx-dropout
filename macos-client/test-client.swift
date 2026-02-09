#!/usr/bin/env swift

import Foundation

// MARK: - Configuration

let serverURL = "http://localhost:8787/api/logs"
let productName = "TestMacApp"
let productVersion = "1.0.0"

// MARK: - Log Submission

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

struct LogResponse: Codable {
    let status: String
    let id: String
}

func getDeviceInfo() -> DeviceInfo {
    let processInfo = ProcessInfo.processInfo
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    let modelString = String(cString: model)
    
    let os = processInfo.operatingSystemVersionString
    
    // Get memory info
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
    let result = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
        }
    }
    
    let memoryGB = result == KERN_SUCCESS ? 
        String(format: "%.0fGB", Double(processInfo.physicalMemory) / 1024 / 1024 / 1024) : 
        "Unknown"
    
    // Get processor info
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

func getDeviceId() -> String {
    // Try to get unique device ID from system
    // This is a simple implementation - in production you might want something more sophisticated
    if let serial = getSystemSerialNumber() {
        return serial
    }
    
    // Fallback to a unique identifier based on MAC address
    return UUID().uuidString
}

func getSystemSerialNumber() -> String? {
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

func submitLog(logs: String, metadata: [String: String] = [:]) async throws {
    guard let url = URL(string: serverURL) else {
        throw NSError(domain: "InvalidURL", code: -1)
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let submission = LogSubmission(
        product: productName,
        version: productVersion,
        platform: "macOS",
        deviceId: getDeviceId(),
        deviceInfo: getDeviceInfo(),
        logs: logs,
        metadata: metadata
    )
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    request.httpBody = try encoder.encode(submission)
    
    print("📤 Submitting log to \(serverURL)...")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NSError(domain: "InvalidResponse", code: -1)
    }
    
    if httpResponse.statusCode == 202 {
        let logResponse = try JSONDecoder().decode(LogResponse.self, from: data)
        print("✅ Log submitted successfully!")
        print("   Status: \(logResponse.status)")
        print("   Log ID: \(logResponse.id)")
    } else {
        print("❌ Failed to submit log")
        print("   Status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Response: \(responseString)")
        }
        throw NSError(domain: "SubmissionFailed", code: httpResponse.statusCode)
    }
}

// MARK: - Crash Log Example

let exampleCrashLog = """
Fatal Error: Index out of bounds

Thread 0 Crashed:
0   TestMacApp                      0x0000000100e4c8b4 specialized Array.subscript.getter + 52
1   TestMacApp                      0x0000000100e4c6d0 DataProcessor.process() + 224
2   TestMacApp                      0x0000000100e4c124 MainController.handleData() + 148
3   TestMacApp                      0x0000000100e4bc8c closure #1 in MainController.start() + 124
4   TestMacApp                      0x0000000100e4bb54 thunk for @escaping @callee_guaranteed () -> () + 20

Stack trace:
  at DataProcessor.swift:42
  at MainController.swift:156
  at AppDelegate.swift:89

Exception Type: EXC_BAD_INSTRUCTION (SIGILL)
Exception Codes: 0x0000000000000001, 0x0000000000000000
Exception Note: EXC_CORPSE_NOTIFY

Thread 0 name: Dispatch queue: com.apple.main-thread
Thread 0:
0   libswiftCore.dylib            0x00007fff2e4a5890 _swift_runtime_on_report + 0
1   TestMacApp                    0x0000000100e4c8b4 specialized Array.subscript.getter + 52
"""

let metadata = [
    "crashTime": ISO8601DateFormatter().string(from: Date()),
    "uptime": "3245",
    "memoryUsage": "1.2GB",
    "cpuUsage": "45%",
    "threadCount": "12"
]

// MARK: - Main

Task {
    do {
        try await submitLog(logs: exampleCrashLog, metadata: metadata)
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
    exit(0)
}

RunLoop.main.run()
