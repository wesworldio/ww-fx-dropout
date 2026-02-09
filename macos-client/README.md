# macOS Client Example

This directory contains example code for submitting crash logs from a macOS application to the WesWorld Logs system.

## Quick Test

The simplest way to test the system:

```bash
# From the project root
make client-example
```

## Files

- `test-client.swift` - Standalone Swift script that submits a test crash log
- `CrashReporter.swift` - Drop-in class for real macOS apps

## Usage in Your App

### Option 1: Standalone Script (for testing)

```bash
cd examples/macos-client
swift test-client.swift
```

### Option 2: Integration in Real App

Copy `CrashReporter.swift` to your Xcode project and use it like this:

```swift
import Foundation

// In your app delegate or crash handler
let reporter = CrashReporter(
    serverURL: "https://your-worker.workers.dev/api/logs",
    productName: "YourAppName",
    version: "1.0.0"
)

// When a crash occurs
let crashLog = """
Your crash log here...
Stack traces, error messages, etc.
"""

Task {
    try? await reporter.submitLog(
        logs: crashLog,
        metadata: [
            "crashTime": ISO8601DateFormatter().string(from: Date()),
            "userId": "user-123"
        ]
    )
}
```

## Automatic Crash Reporting

For automatic crash reporting in a real macOS app, integrate with `NSSetUncaughtExceptionHandler`:

```swift
import Foundation
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let crashReporter = CrashReporter(
        serverURL: "https://your-worker.workers.dev/api/logs",
        productName: "YourApp",
        version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    )
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupCrashHandler()
    }
    
    func setupCrashHandler() {
        NSSetUncaughtExceptionHandler { exception in
            let crashLog = """
            Exception: \(exception.name.rawValue)
            Reason: \(exception.reason ?? "Unknown")
            
            Stack Trace:
            \(exception.callStackSymbols.joined(separator: "\n"))
            """
            
            Task {
                try? await self.crashReporter.submitLog(logs: crashLog)
            }
        }
        
        // Also handle signals
        signal(SIGSEGV) { signal in
            let crashLog = "Segmentation fault (SIGSEGV)"
            // In signal handler, use synchronous submission
            print("Crash detected, saving log...")
            // Save to file and submit on next launch
        }
    }
}
```

## Best Practices

### 1. Submit on Next Launch

Don't submit logs immediately during a crash - the app might be in an unstable state. Instead:

```swift
// On crash:
func saveCrashLog(_ log: String) {
    let logFile = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("pending-crash.log")
    
    try? log.write(to: logFile, atomically: true, encoding: .utf8)
}

// On next launch:
func submitPendingCrashLogs() async {
    let logFile = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("pending-crash.log")
    
    guard FileManager.default.fileExists(atPath: logFile.path),
          let log = try? String(contentsOf: logFile) else {
        return
    }
    
    try? await crashReporter.submitLog(logs: log)
    try? FileManager.default.removeItem(at: logFile)
}
```

### 2. User Privacy

Always inform users about crash reporting:

```swift
func askPermission() -> Bool {
    let alert = NSAlert()
    alert.messageText = "Help Improve YourApp"
    alert.informativeText = "Would you like to automatically send crash reports? This helps us fix bugs faster."
    alert.addButton(withTitle: "Allow")
    alert.addButton(withTitle: "Don't Allow")
    
    return alert.runModal() == .alertFirstButtonReturn
}

// Store preference
UserDefaults.standard.set(askPermission(), forKey: "crashReportingEnabled")
```

### 3. Rate Limiting

Don't spam the server:

```swift
func shouldSubmitLog() -> Bool {
    let lastSubmission = UserDefaults.standard.double(forKey: "lastCrashSubmission")
    let now = Date().timeIntervalSince1970
    
    // Only submit once per hour
    if now - lastSubmission < 3600 {
        return false
    }
    
    UserDefaults.standard.set(now, forKey: "lastCrashSubmission")
    return true
}
```

### 4. Add Context

Include helpful debugging info:

```swift
func getDebugContext() -> [String: String] {
    return [
        "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
        "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
        "locale": Locale.current.identifier,
        "timezone": TimeZone.current.identifier,
        "windowCount": "\(NSApplication.shared.windows.count)",
        "activeWindow": NSApplication.shared.keyWindow?.title ?? "None"
    ]
}
```

## Testing

Test with the development server:

```bash
# Terminal 1: Start server
make dev

# Terminal 2: Submit test log
cd examples/macos-client
swift test-client.swift
```

Then open http://localhost:8787 to see the log in the dashboard.

## Production Setup

1. Update the server URL in your app:

```swift
let reporter = CrashReporter(
    serverURL: "https://logs.wesworld.com/api/logs",  // Your production URL
    productName: "YourApp",
    version: "1.0.0"
)
```

2. Add error handling:

```swift
do {
    try await reporter.submitLog(logs: crashLog)
} catch {
    // Log locally or retry later
    print("Failed to submit crash log: \(error)")
}
```

3. Consider adding authentication if needed (see API docs)

## Troubleshooting

### "Connection refused"

Make sure the dev server is running: `make dev`

### "Invalid response"

Check the server logs: `make logs`

### "No internet connection"

Queue logs for later submission:

```swift
func queueLog(_ log: String) {
    var queue = UserDefaults.standard.stringArray(forKey: "pendingLogs") ?? []
    queue.append(log)
    UserDefaults.standard.set(queue, forKey: "pendingLogs")
}
```

## Resources

- [Apple's Crash Reporting Guide](https://developer.apple.com/documentation/xcode/diagnosing-issues-using-crash-reports-and-device-logs)
- [NSSetUncaughtExceptionHandler Documentation](https://developer.apple.com/documentation/foundation/1409609-nssetuncaughtexceptionhandler)
- [WesWorld Logs API Documentation](../../docs/api.md)
