import Foundation
import SwiftUI
import AppKit

/// 基于 GitHub Releases 的更新管理器
@MainActor
class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()
    
    @Published var canCheckForUpdates = true
    @Published var lastUpdateCheckDate: Date?
    @Published var isChecking = false
    @Published var latestRelease: UpdateInfo?
    @Published var lastError: Error?
    
    // 配置项
    @AppStorage("SUEnableAutomaticChecks") var automaticallyChecksForUpdates = true
    @AppStorage("SUAutomaticallyUpdate") var automaticallyDownloadsAndInstallsUpdates = false
    
    private let githubRepo = "huangdijia/ccswitch-mac"
    
    override private init() {
        super.init()
    }
    
    /// 检查更新 (异步版本)
    func checkForUpdates() async {
        guard !isChecking else { return }
        
        isChecking = true
        lastError = nil
        defer { isChecking = false }
        
        let urlString = "https://api.github.com/repos/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else { 
            lastError = NSError(domain: "UpdateManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return 
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("CCSwitch/\(AppInfo.version)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            lastUpdateCheckDate = Date()
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = json["message"] as? String, (response as? HTTPURLResponse)?.statusCode != 200 {
                    let friendlyMessage: String
                    if message.contains("rate limit exceeded") {
                        friendlyMessage = NSLocalizedString("error_rate_limit", comment: "GitHub API rate limit exceeded")
                    } else {
                        friendlyMessage = message
                    }
                    
                    let error = NSError(domain: "UpdateManager", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: friendlyMessage])
                    self.lastError = error
                    Logger.shared.error("Update check API error: \(message)")
                    return
                }
                
                guard let tagName = json["tag_name"] as? String else {
                    lastError = NSError(domain: "UpdateManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No tag_name found in response"])
                    return
                }
                
                let version = tagName.replacingOccurrences(of: "v", with: "")
                let currentVersion = AppInfo.version
                
                if version.compare(currentVersion, options: .numeric) == .orderedDescending {
                    let body = json["body"] as? String ?? ""
                    let htmlUrl = json["html_url"] as? String ?? ""
                    
                    var downloadUrlString = htmlUrl
                    if let assets = json["assets"] as? [[String: Any]] {
                        for asset in assets {
                            if let name = asset["name"] as? String,
                               (name.hasSuffix(".dmg") || name.hasSuffix(".zip")),
                               let browserDownloadUrl = asset["browser_download_url"] as? String {
                                downloadUrlString = browserDownloadUrl
                                break
                            }
                        }
                    }
                    
                    let downloadUrl = URL(string: downloadUrlString) ?? URL(string: htmlUrl)!
                    
                    latestRelease = UpdateInfo(
                        version: version,
                        releaseNotes: body,
                        downloadUrl: downloadUrl,
                        isPrerelease: json["prerelease"] as? Bool ?? false
                    )
                } else {
                    latestRelease = nil
                }
            }
        } catch {
            self.lastError = error
            Logger.shared.error("Update check failed", error: error)
        }
    }
    
    /// 兼容旧代码的同步/带参数版本
    func checkForUpdates(isManual: Bool) {
        Task {
            await checkForUpdates()
            if isManual {
                if let error = lastError {
                    showErrorAlert(error: error)
                } else if let release = latestRelease {
                    showUpdateAlert(release: release)
                } else {
                    showNoUpdateAlert()
                }
            }
        }
    }
    
    private func showUpdateAlert(release: UpdateInfo) {
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("update_available_title", comment: ""), release.version)
        alert.informativeText = "\(NSLocalizedString("update_available_msg", comment: ""))\n\n\(NSLocalizedString("release_notes_label", comment: ""))\n\(release.releaseNotes)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("download_now", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("later", comment: ""))
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(release.downloadUrl)
        }
    }
    
    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("up_to_date_title", comment: "")
        alert.informativeText = NSLocalizedString("up_to_date_msg", comment: "")
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("ok", comment: ""))
        alert.runModal()
    }

    private func showErrorAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("update_check_failed", comment: "")
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("ok", comment: ""))
        alert.runModal()
    }
}

struct UpdateInfo {
    let version: String
    let releaseNotes: String
    let downloadUrl: URL
    let isPrerelease: Bool
}