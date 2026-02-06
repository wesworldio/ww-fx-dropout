import Foundation
import AppKit

class UpdateChecker {
    static let shared = UpdateChecker()
    
    private let repoOwner = "wesworldio"
    private let repoName = "ww-fx-dropout"
    private var currentVersion: String {
        // Try to get version from Info.plist first
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        
        // Fallback: read from build-info.json
        if let buildInfoPath = Bundle.main.resourceURL?.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("build-info.json").path,
           let data = try? Data(contentsOf: URL(fileURLWithPath: buildInfoPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let version = json["version"] as? String {
            return version
        }
        
        return "2.1.3" // Hardcoded fallback
    }
    
    private init() {}
    
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
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Version \(latestVersion) is now available. You have version \(currentVersion).\n\nWhat's New:\n\(releaseNotes.prefix(200))\(releaseNotes.count > 200 ? "..." : "")"
        alert.alertStyle = .informational
        
        if let downloadUrl = downloadUrl {
            alert.addButton(withTitle: "Download Update")
            alert.addButton(withTitle: "View Release Notes")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn: // Download
                if let url = URL(string: downloadUrl) {
                    NSWorkspace.shared.open(url)
                }
            case .alertSecondButtonReturn: // Release Notes
                if let url = URL(string: releaseUrl) {
                    NSWorkspace.shared.open(url)
                }
            default:
                break
            }
        } else {
            alert.addButton(withTitle: "View Release")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                if let url = URL(string: releaseUrl) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "No Updates Available"
        alert.informativeText = "You are running the latest version (\(currentVersion))."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
