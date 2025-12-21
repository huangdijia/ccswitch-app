import Foundation
import SwiftUI
import AppKit

/// 基于 GitHub Releases 的更新管理器
@MainActor
class UpdateManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = UpdateManager()
    
    @Published var canCheckForUpdates = true
    @Published var lastUpdateCheckDate: Date?
    @Published var isChecking = false
    @Published var latestRelease: UpdateInfo?
    @Published var lastError: Error?
    
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var installationStatus: String?
    
    private var downloadTask: URLSessionDownloadTask?
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()
    
    // 配置项
    @AppStorage("SUEnableAutomaticChecks") var automaticallyChecksForUpdates = true
    @AppStorage("SUAutomaticallyUpdate") var automaticallyDownloadsAndInstallsUpdates = false
    @AppStorage("SULastCheckDate") private var lastCheckDateValue: Double = 0
    @AppStorage("SULastCheckETag") private var lastCheckETag: String = ""
    
    private let githubRepo = "huangdijia/ccswitch-mac"
    private let checkInterval: TimeInterval = 3600 // 1 hour
    
    override private init() {
        super.init()
    }
    
    // MARK: - Download & Install
    
    func downloadAndInstallUpdate(release: UpdateInfo) {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0
        installationStatus = NSLocalizedString("downloading", comment: "")
        
        let task = downloadSession.downloadTask(with: release.downloadUrl)
        self.downloadTask = task
        task.resume()
    }
    
    // URLSessionDownloadDelegate
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent("CCSwitch_Update.zip")
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            Task { @MainActor in
                self.installationStatus = NSLocalizedString("installing", comment: "")
                self.installUpdate(at: destinationURL)
            }
        } catch {
            Task { @MainActor in
                self.isDownloading = false
                self.lastError = error
                self.showErrorAlert(error: error)
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            Task { @MainActor in
                self.downloadProgress = progress
            }
        }
    }
    
    private func installUpdate(at localURL: URL) {
        let appPath = Bundle.main.bundlePath
        let tempExtractDir = FileManager.default.temporaryDirectory.appendingPathComponent("CCSwitch_Extracted")
        
        do {
            if FileManager.default.fileExists(atPath: tempExtractDir.path) {
                try FileManager.default.removeItem(at: tempExtractDir)
            }
            try FileManager.default.createDirectory(at: tempExtractDir, withIntermediateDirectories: true)
            
            // 使用 ditto 解压
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-x", "-k", localURL.path, tempExtractDir.path]
            try process.run()
            process.waitUntilExit()
            
            // 找到解压后的 .app
            let contents = try FileManager.default.contentsOfDirectory(at: tempExtractDir, includingPropertiesForKeys: nil)
            guard let newAppBundle = contents.first(where: { $0.pathExtension == "app" }) else {
                throw NSError(domain: "UpdateManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find .app in update package"])
            }
            
            // 准备更新脚本
            let scriptPath = FileManager.default.temporaryDirectory.appendingPathComponent("install_update.sh").path
            let script = """
            #!/bin/bash
            sleep 1
            rm -rf "\(appPath)"
            cp -R "\(newAppBundle.path)" "\(appPath)"
            open "\(appPath)"
            """
            
            try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
            
            // 运行更新脚本并退出
            let scriptProcess = Process()
            scriptProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
            scriptProcess.arguments = [scriptPath]
            try scriptProcess.run()
            
            NSApplication.shared.terminate(nil)
            
        } catch {
            self.isDownloading = false
            self.lastError = error
            self.showErrorAlert(error: error)
        }
    }
    
    /// 检查更新 (异步版本)
    func checkForUpdates(isManual: Bool = false) async {
        guard !isChecking else { return }
        
        // 非手动检查时，检查时间间隔
        if !isManual {
            let lastCheck = Date(timeIntervalSince1970: lastCheckDateValue)
            if Date().timeIntervalSince(lastCheck) < checkInterval {
                return
            }
        }
        
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
        
        // 添加 ETag 支持以节省额度
        if !isManual && !lastCheckETag.isEmpty {
            request.setValue(lastCheckETag, forHTTPHeaderField: "If-None-Match")
        }
        
        request.timeoutInterval = 15
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            // 更新最后检查时间
            lastCheckDateValue = Date().timeIntervalSince1970
            lastUpdateCheckDate = Date()
            
            // 304 Not Modified 表示内容没变
            if httpResponse?.statusCode == 304 {
                Logger.shared.info("Update check: 304 Not Modified")
                return
            }
            
            // 保存新的 ETag
            if let etag = httpResponse?.allHeaderFields["Etag"] as? String {
                lastCheckETag = etag
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = json["message"] as? String, httpResponse?.statusCode != 200 {
                    let friendlyMessage: String
                    if message.contains("rate limit exceeded") {
                        friendlyMessage = NSLocalizedString("error_rate_limit", comment: "GitHub API rate limit exceeded")
                    } else {
                        friendlyMessage = message
                    }
                    
                    let error = NSError(domain: "UpdateManager", code: httpResponse?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: friendlyMessage])
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
            await checkForUpdates(isManual: isManual)
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
        
        let updateTitle = release.downloadUrl.pathExtension == "zip" ? NSLocalizedString("update_now", comment: "") : NSLocalizedString("download_now", comment: "")
        alert.addButton(withTitle: updateTitle)
        alert.addButton(withTitle: NSLocalizedString("later", comment: ""))
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if release.downloadUrl.pathExtension == "zip" {
                downloadAndInstallUpdate(release: release)
            } else {
                NSWorkspace.shared.open(release.downloadUrl)
            }
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