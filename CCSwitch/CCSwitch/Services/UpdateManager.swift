import Foundation
import SwiftUI
import AppKit

/// 基于 GitHub Releases 的更新管理器
class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()
    
    @Published var canCheckForUpdates = true
    @Published var lastUpdateCheckDate: Date?
    @Published var isChecking = false
    @Published var latestRelease: UpdateInfo?
    
    // 配置项
    @AppStorage("SUEnableAutomaticChecks") var automaticallyChecksForUpdates = true
    @AppStorage("SUAutomaticallyUpdate") var automaticallyDownloadsAndInstallsUpdates = false
    
    private let githubRepo = "huangdijia/ccswitch-mac"
    
    /// 检查更新
    /// - Parameter isManual: 是否为用户手动触发。手动触发时会显示“已是最新”或“错误”弹窗。
    func checkForUpdates(isManual: Bool = false) {
        guard !isChecking else { return }
        
        isChecking = true
        let urlString = "https://api.github.com/repos/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else {
            isChecking = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isChecking = false
                self.lastUpdateCheckDate = Date()
                
                if let error = error {
                    if isManual { self.showErrorAlert(error.localizedDescription) }
                    return
                }
                
                guard let data = data else {
                    if isManual { self.showErrorAlert("No data received from GitHub") }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let message = json["message"] as? String, (response as? HTTPURLResponse)?.statusCode != 200 {
                             if isManual { self.showErrorAlert(message) }
                             return
                        }
                        
                        guard let tagName = json["tag_name"] as? String else {
                            if isManual { self.showNoUpdateAlert() }
                            return
                        }
                        
                        let version = tagName.replacingOccurrences(of: "v", with: "")
                        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                        
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
                            
                            self.latestRelease = UpdateInfo(
                                version: version,
                                releaseNotes: body,
                                downloadUrl: downloadUrl,
                                isPrerelease: json["prerelease"] as? Bool ?? false
                            )
                            
                            self.showUpdateAlert()
                        } else {
                            if isManual {
                                self.showNoUpdateAlert()
                            }
                        }
                    }
                } catch {
                    if isManual { self.showErrorAlert(error.localizedDescription) }
                }
            }
        }.resume()
    }
    
    private func showUpdateAlert() {
        guard let release = latestRelease else { return }
        
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
    
    private func showErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("update_check_failed", comment: "")
        alert.informativeText = message
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