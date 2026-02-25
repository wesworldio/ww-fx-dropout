import Foundation
import AppKit
import UserNotifications

class UpdateChecker: NSObject, UNUserNotificationCenterDelegate {
    static let shared = UpdateChecker()
    
    private let repoOwner = "wesworldio"
    private let repoName = "ww-fx-dropout"
    private let currentVersion = "2.1.0"
    private let notificationsEnabled: Bool
    
    override private init() {
        if let bundleId = Bundle.main.bundleIdentifier, !bundleId.isEmpty {
            notificationsEnabled = true
        } else {
            notificationsEnabled = false
        }
        super.init()
        guard notificationsEnabled else {
            print("⚠️  Notifications disabled (no app bundle identifier)")
            return
        }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            } else if !granted {
                print("Notification authorization not granted")
            }
        }
        let downloadAction = UNNotificationAction(
            identifier: "UpdateChecker.Download",
            title: "Download",
            options: [.foreground]
        )
        let viewReleaseAction = UNNotificationAction(
            identifier: "UpdateChecker.ViewRelease",
            title: "View Release",
            options: [.foreground]
        )
        let laterAction = UNNotificationAction(
            identifier: "UpdateChecker.Later",
            title: "Later",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "UpdateChecker.UpdateAvailable",
            actions: [downloadAction, viewReleaseAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let downloadUrl = userInfo["downloadUrl"] as? String
        let releaseUrl = userInfo["releaseUrl"] as? String
        
        switch response.actionIdentifier {
        case "UpdateChecker.Download":
            if let downloadUrl, let url = URL(string: downloadUrl) {
                NSWorkspace.shared.open(url)
            } else if let releaseUrl, let url = URL(string: releaseUrl) {
                NSWorkspace.shared.open(url)
            }
        case "UpdateChecker.ViewRelease", UNNotificationDefaultActionIdentifier:
            if let releaseUrl, let url = URL(string: releaseUrl) {
                NSWorkspace.shared.open(url)
            }
        default:
            break
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
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
        guard notificationsEnabled else {
            print("Update available: v\(latestVersion) - \(releaseUrl)")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Update Available"
        content.subtitle = "WesWorld FX v\(latestVersion)"
        content.body = "A new version is available. Click to download or visit the release page."
        content.userInfo = ["releaseUrl": releaseUrl]
        content.categoryIdentifier = "UpdateChecker.UpdateAvailable"
        if let downloadUrl = downloadUrl {
            content.userInfo["downloadUrl"] = downloadUrl
        }
        
        let request = UNNotificationRequest(
            identifier: "UpdateChecker.UpdateAvailable",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver update notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func showNoUpdateAlert() {
        guard notificationsEnabled else {
            print("App is up to date (v\(currentVersion))")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "App is Up to Date"
        content.body = "You're running the latest version (\(currentVersion))."
        
        let request = UNNotificationRequest(
            identifier: "UpdateChecker.NoUpdate",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver no-update notification: \(error.localizedDescription)")
            }
        }
    }
}
