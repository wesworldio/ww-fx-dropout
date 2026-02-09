// AppDelegate+CacheCleanup.swift
// On first launch of a new version, remove old cached data and preferences
import Foundation

extension AppDelegate {
    func performCacheCleanupIfNeeded() {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let defaults = UserDefaults.standard
        let lastVersion = defaults.string(forKey: "WesWorldFX_LastVersion") ?? ""
        if lastVersion != currentVersion {
            // Remove old cache and preferences
            let fileManager = FileManager.default
            let home = NSHomeDirectory()
            let paths = [
                home + "/Library/Application Support/WesWorldFX",
                home + "/Library/Application Support/wesworld-fx-desktop",
                home + "/Library/Preferences/WesWorldFX.plist",
                home + "/Library/Preferences/io.wesworld.fx.plist",
                home + "/Library/Containers/io.wesworld.fx.native"
            ]
            for path in paths {
                if fileManager.fileExists(atPath: path) {
                    try? fileManager.removeItem(atPath: path)
                }
            }
            defaults.set(currentVersion, forKey: "WesWorldFX_LastVersion")
            defaults.synchronize()
        }
    }
}
