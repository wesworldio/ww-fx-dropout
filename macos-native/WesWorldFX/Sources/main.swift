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

func setupMenuBar() {
    let mainMenu = NSMenu()
    
    // App Menu
    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)
    
    let appMenu = NSMenu()
    appMenuItem.submenu = appMenu
    
    appMenu.addItem(withTitle: "About WesWorld FX", action: #selector(AppDelegate.showAbout(_:)), keyEquivalent: "")
    appMenu.addItem(NSMenuItem.separator())
    appMenu.addItem(withTitle: "Quit WesWorld FX", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    
    // Filters Menu
    let filtersMenuItem = NSMenuItem()
    filtersMenuItem.title = "Filters"
    mainMenu.addItem(filtersMenuItem)
    
    let filtersMenu = NSMenu(title: "Filters")
    filtersMenuItem.submenu = filtersMenu
    
    filtersMenu.addItem(withTitle: "Create Custom Bulge Filter...", action: #selector(AppDelegate.openBulgeEditor(_:)), keyEquivalent: "b")
    filtersMenu.addItem(NSMenuItem.separator())
    filtersMenu.addItem(withTitle: "Manage Custom Filters...", action: #selector(AppDelegate.manageBulgeFilters(_:)), keyEquivalent: "m")
    filtersMenu.addItem(withTitle: "Import Custom Filters...", action: #selector(AppDelegate.importBulgeFilters(_:)), keyEquivalent: "")
    filtersMenu.addItem(withTitle: "Export Custom Filters...", action: #selector(AppDelegate.exportBulgeFilters(_:)), keyEquivalent: "")
    filtersMenu.addItem(NSMenuItem.separator())
    filtersMenu.addItem(withTitle: "Reload Bundled Bulge Filters", action: #selector(AppDelegate.reloadBundledBulgeFilters(_:)), keyEquivalent: "r")
    
    // Window Menu
    let windowMenuItem = NSMenuItem()
    windowMenuItem.title = "Window"
    mainMenu.addItem(windowMenuItem)
    
    let windowMenu = NSMenu(title: "Window")
    windowMenuItem.submenu = windowMenu
    
    windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
    windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
    
    app.mainMenu = mainMenu
}
