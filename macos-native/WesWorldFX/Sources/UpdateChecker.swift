import Foundation
import AppKit

class UpdateChecker: NSObject, NSUserNotificationCenterDelegate {
    static let shared = UpdateChecker()
    
    private let repoOwner = "wesworldio"
    private let repoName = "ww-fx-dropout"
    private let currentVersion = "2.1.0"
    
    override private init() {
        super.init()
        // Set up notification delegate to handle notification interactions
        NSUserNotificationCenter.default.delegate = self
    }
    
    // MARK: - NSUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        if notification.activationType == .actionButtonClicked {
            // Action button clicked (Download or View Release)
            if let downloadUrl = userInfo["downloadUrl"] as? String,
               let url = URL(string: downloadUrl) {
                NSWorkspace.shared.open(url)
            } else if let releaseUrl = userInfo["releaseUrl"] as? String,
                      let url = URL(string: releaseUrl) {
                NSWorkspace.shared.open(url)
            }
        } else if notification.activationType == .contentsClicked {
            // Notification body clicked - open release page
            if let releaseUrl = userInfo["releaseUrl"] as? String,
               let url = URL(string: releaseUrl) {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        // Always present notifications, even if the app is in focus
        return true
    }
    
    func checkForUpdates(showNoUpdateAlert: Bool = false) {
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL for update check")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Update check failed: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from update check")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String,
                   let htmlUrl = json["html_url"] as? String,
                   let assets = json["assets"] as? [[String: Any]],
                   let releaseNotes = json["body"] as? String {
                    
                    let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                    
                    if self.isNewerVersion(latestVersion, than: self.currentVersion) {
                        // Find DMG asset
                        var downloadUrl: String?
                        for asset in assets {
                            if let name = asset["name"] as? String,
                               name.hasSuffix(".dmg"),
                               let browserDownloadUrl = asset["browser_download_url"] as? String {
                                downloadUrl = browserDownloadUrl
                                break
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.showUpdateAlert(
                                latestVersion: latestVersion,
                                releaseUrl: htmlUrl,
                                downloadUrl: downloadUrl,
                                releaseNotes: releaseNotes
                            )
                        }
                    } else if showNoUpdateAlert {
                        DispatchQueue.main.async {
                            self.showNoUpdateAlert()
                        }
                    } else {
                        print("App is up to date (v\(self.currentVersion))")
                    }
                }
            } catch {
                print("Failed to parse update response: \(error)")
            }
        }.resume()
    }
    
    private func isNewerVersion(_ version1: String, than version2: String) -> Bool {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxLength {
            let v1 = i < v1Components.count ? v1Components[i] : 0
            let v2 = i < v2Components.count ? v2Components[i] : 0
            
            if v1 > v2 { return true }
            if v1 < v2 { return false }
        }
        
        return false
    }
    
    private func showUpdateAlert(latestVersion: String, releaseUrl: String, downloadUrl: String?, releaseNotes: String) {
        // Use macOS notification instead of modal alert - subtle and non-intrusive
        let notification = NSUserNotification()
        notification.title = "Update Available"
        notification.subtitle = "WesWorld FX v\(latestVersion)"
        notification.informativeText = "A new version is available. Click to download or visit the release page."
        notification.soundName = nil // Silent notification
        
        // Set action buttons for the notification
        if let downloadUrl = downloadUrl {
            notification.actionButtonTitle = "Download"
            notification.otherButtonTitle = "Later"
            notification.userInfo = ["downloadUrl": downloadUrl, "releaseUrl": releaseUrl]
        } else {
            notification.actionButtonTitle = "View Release"
            notification.otherButtonTitle = "Later"
            notification.userInfo = ["releaseUrl": releaseUrl]
        }
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func showNoUpdateAlert() {
        // Subtle notification for "no update available" - only shown if user explicitly checked
        let notification = NSUserNotification()
        notification.title = "App is Up to Date"
        notification.informativeText = "You're running the latest version (\(currentVersion))."
        notification.soundName = nil // Silent notification
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}
