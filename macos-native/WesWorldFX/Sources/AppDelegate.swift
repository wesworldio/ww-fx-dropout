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
    
    // UserDefaults keys for camera permission persistence
    private let cameraPermissionLastAskedKey = "WesWorldFX_CameraPermissionLastAsked"
    private let cameraPermissionGrantedKey = "WesWorldFX_CameraPermissionGranted"
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Application did finish launching")
        
        // Check for updates on launch (after a short delay to let the app fully load)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UpdateChecker.shared.checkForUpdates()
        }
        
        // Activate the app - CRITICAL for window visibility
        NSApp.setActivationPolicy(.regular)
        print("Activation policy set to .regular")
        
        NSApp.activate(ignoringOtherApps: true)
        print("App activated")
        
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
        // Clean up camera and Metal resources
        cameraViewController?.cleanup()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @objc func showAbout(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "WesWorld FX"
        alert.informativeText = "Version 2.1.0\n\nNative macOS camera filters with Metal GPU acceleration.\n\n© 2026 WesWorld"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Check for Updates...")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            UpdateChecker.shared.checkForUpdates(showNoUpdateAlert: true)
        }
    }
    
    @objc func openBulgeEditor(_ sender: Any?) {
        cameraViewController?.openBulgeEditor()
    }
    
    @objc func manageBulgeFilters(_ sender: Any?) {
        cameraViewController?.manageBulgeFilters()
    }
    
    @objc func importBulgeFilters(_ sender: Any?) {
        BulgeFilterManager.shared.importFiltersDialog()
        cameraViewController?.updateFilterList()
    }
    
    @objc func exportBulgeFilters(_ sender: Any?) {
        BulgeFilterManager.shared.exportAllFilters()
    }

    @objc func reloadBundledBulgeFilters(_ sender: Any?) {
        BulgeFilterManager.shared.reloadBundledEffects()
        cameraViewController?.updateFilterList()
    }
    
    private func requestCameraAccess() {
        // Check current authorization status
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Log current state
        let statusString = {
            switch currentStatus {
            case .authorized: return "authorized"
            case .denied: return "denied"
            case .restricted: return "restricted"
            case .notDetermined: return "notDetermined"
            @unknown default: return "unknown"
            }
        }()
        
        print("Camera permission status: \(statusString)")
        
        // Load previously saved permission state
        let defaults = UserDefaults.standard
        
        switch currentStatus {
        case .authorized:
            // Permission already granted by user
            print("Camera access already authorized by system")
            defaults.set(true, forKey: cameraPermissionGrantedKey)
            defaults.set(Date(), forKey: cameraPermissionLastAskedKey)
            
        case .denied:
            // User previously denied camera access
            print("Camera access was denied")
            showCameraDeniedAlert()
            
        case .restricted:
            // Camera access is restricted (parental controls, MDM, etc.)
            print("Camera access is restricted")
            showCameraRestrictedAlert()
            
        case .notDetermined:
            // First time asking for permission
            print("Requesting camera access from user")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    let defaults = UserDefaults.standard
                    defaults.set(granted, forKey: self?.cameraPermissionGrantedKey ?? "WesWorldFX_CameraPermissionGranted")
                    defaults.set(Date(), forKey: self?.cameraPermissionLastAskedKey ?? "WesWorldFX_CameraPermissionLastAsked")
                    
                    print("Camera access request result: \(granted ? "granted" : "denied")")
                    
                    if !granted {
                        self?.showCameraDeniedAlert()
                    }
                }
            }
        @unknown default:
            print("Unknown camera permission status")
        }
    }
    
    private func showCameraDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Camera Access Required"
        alert.informativeText = "WesWorld FX needs camera access to work.\n\nTo enable camera access:\n1. Open System Settings\n2. Go to Privacy & Security > Camera\n3. Find and enable WesWorld FX"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Continue Without Camera")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Privacy & Security > Camera
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func showCameraRestrictedAlert() {
        let alert = NSAlert()
        alert.messageText = "Camera Access Restricted"
        alert.informativeText = "Camera access is restricted on this system, possibly due to parental controls or device management policies. Please contact your system administrator."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
