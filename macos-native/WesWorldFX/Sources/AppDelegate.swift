//
//  AppDelegate.swift
//  WesWorld FX - Native Mac Edition
//
//  High-performance camera filters using Metal and AVFoundation
//

import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    var cameraViewController: CameraViewController!
    
    // MARK: - Build Info Helper
    
    private func getBuildVersionString() -> String {
        // Try to read build-info.json from the app bundle's Resources directory
        if let buildInfoURL = Bundle.main.url(forResource: "build-info", withExtension: "json") {
            do {
                let data = try Data(contentsOf: buildInfoURL)
                if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let version = jsonDict["version"] as? String ?? "2.1.4"
                    let buildNumber = jsonDict["buildNumber"] as? Int ?? 210
                    return "Version \(version) (Build \(buildNumber))"
                }
            } catch {
                print("Error reading build-info.json: \(error)")
            }
        }
        return "Version 2.1.4 (Build 210)"
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Clean up old cache and preferences if launching a new version
        performCacheCleanupIfNeeded()
        // Initialize crash reporting FIRST
        WesWorldReporter.shared.setupCrashHandlers()
        
            // Explicitly log app open event to remote log server
            Task {
                await WesWorldReporter.shared.logInfo("WesWorldFX app opened", additionalInfo: ["event": "app_opened"])
            }
        // Initialize diagnostic logger
        DiagnosticLogger.shared.info("Application did finish launching", category: "LIFECYCLE")
        DiagnosticLogger.shared.startPeriodicMonitoring(interval: 60) // Log system status every minute
        
        print("Application did finish launching")
        
        // Set up debug menu
        setupDebugMenu()
        
        // Check for updates on launch (after a short delay to let the app fully load)
        // DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        //     UpdateChecker.shared.checkForUpdates()
        // }
        
        // Activate the app - CRITICAL for window visibility
        NSApp.setActivationPolicy(.regular)
        print("Activation policy set to .regular")
        DiagnosticLogger.shared.info("Activation policy set to .regular", category: "LIFECYCLE")
        
        NSApp.activate(ignoringOtherApps: true)
        print("App activated")
        DiagnosticLogger.shared.info("App activated", category: "LIFECYCLE")
        
        // Request camera permissions
        requestCameraAccess()
        
        // Create main window with explicit screen positioning
        let contentRect = NSRect(x: 100, y: 100, width: 1280, height: 720)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "WesWorld FX"
        window.isReleasedWhenClosed = false
        window.backgroundColor = .black
        window.acceptsMouseMovedEvents = true
        
        print("Window created: \(window.frame)")
        
        // Create and set camera view controller
        cameraViewController = CameraViewController()
        window.contentViewController = cameraViewController
        
        print("View controller set")
        
        // Make window visible with multiple strategies
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.makeMain()
        window.level = .floating  // Temporarily float to ensure visibility
        
        print("Window should be visible now at level: \(window.level.rawValue)")
        print("Window is visible: \(window.isVisible)")
        print("Window is on screen: \(window.isOnActiveSpace)")
        
        // Reset to normal level after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.window.level = .normal
            print("Window level reset to normal")
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Log app termination
        DiagnosticLogger.shared.info("Application will terminate", category: "LIFECYCLE")
        
            // Explicitly log app close event to remote log server
            Task {
                await WesWorldReporter.shared.logInfo("WesWorldFX app closed", additionalInfo: ["event": "app_closed"])
            }
        // Flush any pending crash logs
        Task {
            await WesWorldReporter.shared.flushPendingLogs()
        }
        
        // Clean up camera and Metal resources
        cameraViewController?.cleanup()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @objc func showAbout(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "WesWorld FX"
        alert.informativeText = "\(getBuildVersionString())\n\nNative macOS camera filters with Metal GPU acceleration.\n\n© 2026 WesWorld"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Check for Updates...")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            UpdateChecker.shared.checkForUpdates(showNoUpdateAlert: true)
        }
    }
    
    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                DiagnosticLogger.shared.warning("Camera access denied by user", category: "CAMERA")
                
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Camera Access Required"
                    alert.informativeText = "WesWorld FX needs camera access to work. Please enable it in System Settings > Privacy & Security > Camera."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            } else {
                DiagnosticLogger.shared.info("Camera access granted", category: "CAMERA")
            }
        }
    }
    
    private func setupDebugMenu() {
        let mainMenu = NSApplication.shared.mainMenu ?? NSMenu()
        DiagnosticsMenuController.shared.setupMenuItems(in: mainMenu)
        NSApplication.shared.mainMenu = mainMenu
    }}