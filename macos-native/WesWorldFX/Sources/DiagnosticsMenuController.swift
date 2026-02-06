import AppKit

/// Menu item for accessing debug logs and diagnostics
class DiagnosticsMenuController {
    static let shared = DiagnosticsMenuController()
    
    func setupMenuItems(in menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())
        
        // Debug Submenu
        let debugMenu = NSMenu(title: "Debug")
        debugMenu.addItem(withTitle: "View Debug Logs", action: #selector(viewDebugLogs), keyEquivalent: "")
        debugMenu.addItem(withTitle: "Open Logs Folder", action: #selector(openLogsFolder), keyEquivalent: "")
        debugMenu.addItem(NSMenuItem.separator())
        debugMenu.addItem(withTitle: "Copy System Info to Clipboard", action: #selector(copySystemInfo), keyEquivalent: "")
        debugMenu.addItem(withTitle: "Copy Recent Logs to Clipboard", action: #selector(copyRecentLogs), keyEquivalent: "")
        debugMenu.addItem(NSMenuItem.separator())
        debugMenu.addItem(withTitle: "Show Current Memory Usage", action: #selector(showMemoryUsage), keyEquivalent: "")
        debugMenu.addItem(withTitle: "Show CPU Usage", action: #selector(showCPUUsage), keyEquivalent: "")
        
        let debugMenuItem = NSMenuItem(title: "Debug", action: nil, keyEquivalent: "")
        debugMenuItem.submenu = debugMenu
        menu.addItem(debugMenuItem)
    }
    
    @objc private func viewDebugLogs() {
        let logURL = DiagnosticLogger.shared.getLogFileURL()
        let alert = NSAlert()
        alert.messageText = "Debug Log"
        alert.informativeText = "Log file: \(logURL.lastPathComponent)\n\nRecent logs (last 50 lines):"
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Open in Finder")
        alert.addButton(withTitle: "Copy to Clipboard")
        
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.string = DiagnosticLogger.shared.getRecentLogs(lineCount: 50)
        textView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        scrollView.documentView = textView
        
        alert.accessoryView = scrollView
        
        let response = alert.runModal()
        
        if response == NSApplication.ModalResponse(rawValue: 1001) {
            DiagnosticLogger.shared.openLogsInFinder()
        } else if response == NSApplication.ModalResponse(rawValue: 1002) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(DiagnosticLogger.shared.getRecentLogs(lineCount: 100), forType: .string)
        }
    }
    
    @objc private func openLogsFolder() {
        DiagnosticLogger.shared.openLogsInFinder()
    }
    
    @objc private func copySystemInfo() {
        var info = "WesWorldFX System Information\n"
        info += "════════════════════════════════════════\n"
        
        let processInfo = ProcessInfo.processInfo
        info += "App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        info += "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")\n"
        info += "OS: \(processInfo.operatingSystemVersionString)\n"
        info += "Machine Model: \(getMacModel())\n"
        info += "Processor Count: \(processInfo.processorCount)\n"
        info += "Active Processor Count: \(processInfo.activeProcessorCount)\n"
        info += "Physical Memory: \(formatBytes(processInfo.physicalMemory))\n"
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info, forType: .string)
        
        showNotification(title: "Copied!", message: "System info copied to clipboard")
    }
    
    @objc private func copyRecentLogs() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(DiagnosticLogger.shared.getRecentLogs(lineCount: 200), forType: .string)
        
        showNotification(title: "Copied!", message: "Last 200 log lines copied to clipboard")
    }
    
    @objc private func showMemoryUsage() {
        let memInfo = getMemoryInfo()
        let alert = NSAlert()
        alert.messageText = "Memory Usage"
        alert.informativeText = memInfo
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func showCPUUsage() {
        let cpuUsage = getCPUUsage()
        let alert = NSAlert()
        alert.messageText = "CPU Usage"
        alert.informativeText = String(format: "Current CPU Usage: %.1f%%", cpuUsage)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func getMacModel() -> String {
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
    
    private func getMemoryInfo() -> String {
        var info = ""
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size)/4
        
        _ = withUnsafeMutablePointer(to: &taskInfo) { pointer in
            task_info(
                mach_task_self_,
                task_flavor_t(TASK_VM_INFO),
                UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: integer_t.self),
                &count
            )
        }
        
        let usedMemory = UInt64(taskInfo.phys_footprint)
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let usedPercent = (Double(usedMemory) / Double(totalMemory)) * 100.0
        
        info += "Used Memory: \(formatBytes(usedMemory))\n"
        info += "Total Available: \(formatBytes(totalMemory))\n"
        info += "Used: \(String(format: "%.1f%%", usedPercent))"
        
        return info
    }
    
    private func getCPUUsage() -> Double {
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
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func showNotification(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
