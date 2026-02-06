//
//  main.swift
//  WesWorld FX
//
//  Main entry point
//

import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)

// Manually run the event loop instead of NSApplicationMain to avoid storyboard loading
app.run()
