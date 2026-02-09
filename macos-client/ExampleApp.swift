import Cocoa

/// Example macOS App with WesWorldReporter integration
/// This demonstrates how to set up and use crash logging in a real app

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    var window: NSWindow?
    var mainViewController: MainViewController?
    
    // MARK: - App Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. SETUP: Initialize crash handlers FIRST
        setupCrashReporting()
        
        // 2. CREATE: Main window and controller
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "ww-fx-dropout"
        window.makeKeyAndOrderFront(nil)
        
        let mainVC = MainViewController()
        window.contentViewController = mainVC
        
        self.window = window
        self.mainViewController = mainVC
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 3. CLEANUP: Flush any pending logs before exit
        Task {
            await WesWorldReporter.shared.flushPendingLogs()
        }
    }
    
    // MARK: - Crash Reporting Setup
    
    private func setupCrashReporting() {
        // Initialize reporter with configuration
        let reporter = WesWorldReporter.shared
        
        // Enable automatic crash handling
        reporter.setupCrashHandlers()
        
        // Optional: Log app launch
        Task {
            await reporter.logInfo(
                "App launched",
                additionalInfo: [
                    "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                    "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
                ]
            )
        }
    }
}

// MARK: - Main View Controller

class MainViewController: NSViewController {
    
    // MARK: - UI Elements
    
    private let label = NSTextField(labelWithString: "ww-fx-dropout")
    private let stackView = NSStackView()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        self.view = NSView()
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        // Title
        label.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        label.alignment = .center
        
        // Stack view
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons
        let testLogButton = NSButton(title: "Log Test Message", target: self, action: #selector(logTestMessage))
        let testErrorButton = NSButton(title: "Log Test Error", target: self, action: #selector(logTestError))
        let crashButton = NSButton(title: "Trigger Crash (Testing)", target: self, action: #selector(triggerTestCrash))
        
        // Add to stack
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(NSView()) // Spacer
        stackView.addArrangedSubview(testLogButton)
        stackView.addArrangedSubview(testErrorButton)
        stackView.addArrangedSubview(crashButton)
        stackView.addArrangedSubview(NSView()) // Spacer
        
        view.addSubview(stackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func logTestMessage() {
        Task {
            await WesWorldReporter.shared.logInfo(
                "User triggered test message",
                additionalInfo: [
                    "action": "test_message",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )
        }
        
        showAlert(title: "Logged", message: "Info message sent to WesWorld Logs")
    }
    
    @objc private func logTestError() {
        // Simulate an error
        enum TestError: Error {
            case fileNotFound
            case invalidData
        }
        
        Task {
            await WesWorldReporter.shared.logError(
                "Test error from user action",
                TestError.fileNotFound,
                additionalInfo: [
                    "action": "test_error",
                    "errorType": "fileNotFound"
                ]
            )
        }
        
        showAlert(title: "Logged", message: "Error message sent to WesWorld Logs")
    }
    
    @objc private func triggerTestCrash() {
        // Show warning first
        let alert = NSAlert()
        alert.messageText = "Trigger Test Crash?"
        alert.informativeText = "This will intentionally crash the app. The crash report will be sent to WesWorld Logs.\n\nMake sure the logging server is running."
        alert.addButton(withTitle: "Crash App")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            // Intentional crash for testing
            fatalError("Test crash triggered by user")
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Advanced Usage Example

class FileOperationHandler {
    
    /// Example: Logging file operations
    func processFile(at url: URL) async {
        do {
            print("Processing file: \(url.lastPathComponent)")
            let data = try Data(contentsOf: url)
            
            // Log success
            await WesWorldReporter.shared.logInfo(
                "File processed successfully",
                additionalInfo: [
                    "filename": url.lastPathComponent,
                    "filesize": "\(data.count) bytes"
                ]
            )
            
        } catch {
            // Log error
            await WesWorldReporter.shared.logError(
                "Failed to process file",
                error,
                additionalInfo: [
                    "filename": url.lastPathComponent,
                    "filepath": url.path,
                    "errorType": String(describing: type(of: error))
                ]
            )
        }
    }
    
    /// Example: Logging performance issues
    func performHeavyOperation() async {
        let startTime = Date()
        
        // Do work...
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        if elapsed > 5.0 {
            // Warn if takes too long
            await WesWorldReporter.shared.logWarning(
                "Heavy operation took longer than expected",
                additionalInfo: [
                    "duration": String(format: "%.2fs", elapsed),
                    "operation": "heavyOperation"
                ]
            )
        }
    }
    
    /// Example: Network error handling
    func fetchData(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            await WesWorldReporter.shared.logWarning(
                "Invalid URL provided",
                additionalInfo: ["url": urlString]
            )
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    await WesWorldReporter.shared.logWarning(
                        "Non-200 HTTP response",
                        additionalInfo: [
                            "statusCode": "\(httpResponse.statusCode)",
                            "url": urlString
                        ]
                    )
                } else {
                    // Success
                    await WesWorldReporter.shared.logInfo(
                        "Data fetched successfully",
                        additionalInfo: ["bytes": "\(data.count)"]
                    )
                }
            }
        } catch {
            await WesWorldReporter.shared.logError(
                "Network request failed",
                error,
                additionalInfo: ["url": urlString]
            )
        }
    }
}

// MARK: - Usage Notes

/*
 
 INTEGRATION CHECKLIST:
 
 1. ✅ Copy WesWorldReporter.swift to your project
 2. ✅ Call `WesWorldReporter.shared.setupCrashHandlers()` in AppDelegate.applicationDidFinishLaunching()
 3. ✅ Use `await WesWorldReporter.shared.logError()` for errors
 4. ✅ Use `await WesWorldReporter.shared.logInfo()` for info logs
 5. ✅ Use `await WesWorldReporter.shared.logWarning()` for warnings
 6. ✅ Call `flushPendingLogs()` before app termination
 
 CONFIGURATION:
 
 - Set WW_LOGS_URL environment variable for server endpoint
 - Set WW_LOGS_API_KEY environment variable for API authentication
 - Or use logging-config.json in app bundle (not tracked in git)
 
 TESTING:
 
 1. Start local server:
    cd ww-logs-1 && make dev
 
 2. Set environment variables:
    export WW_LOGS_URL="http://localhost:8787/api/logs"
    export WW_LOGS_API_KEY="ww-fx-dropout-prod-2026-01-01"
 
 3. Run the app and test buttons
 
 4. View logs at: http://localhost:8787
    Password: WesWorld2026
 
 DEPLOYMENT:
 
 1. Deploy WesWorld Logs to Cloudflare:
    make deploy
 
 2. Update environment variables in your app distribution
 
 3. Store API key securely (not in source code)
 
 */
