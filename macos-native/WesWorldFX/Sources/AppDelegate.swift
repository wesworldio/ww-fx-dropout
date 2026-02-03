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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Application did finish launching")
        
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
    
    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Camera Access Required"
                    alert.informativeText = "WesWorld FX needs camera access to work. Please enable it in System Settings > Privacy & Security > Camera."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
}
