import Foundation
import SwiftUI
import Sparkle

/// 状态机枚举
enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case downloading(progress: Double)
    case installing
    case awaitingRelaunch(version: String)
    case error(String)
    
    var isChecking: Bool {
        if case .checking = self { return true }
        return false
    }
    
    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
}

/// 基于 Sparkle 2 的更新管理器
@MainActor
class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()
    
    @Published var state: UpdateState = .idle
    @Published var lastUpdateCheckDate: Date?
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private var updater: SPUUpdater?
    private var updaterController: SPUStandardUpdaterController?
    
    // 配置项桥接
    @AppStorage("SUEnableAutomaticChecks") var automaticallyChecksForUpdates = true {
        didSet { updater?.automaticallyChecksForUpdates = automaticallyChecksForUpdates }
    }
    @AppStorage("SUAutomaticallyUpdate") var automaticallyDownloadsAndInstallsUpdates = false {
        didSet { updater?.automaticallyDownloadsAndInstallsUpdates = automaticallyDownloadsAndInstallsUpdates }
    }
    @AppStorage("SULastCheckDate") private var lastCheckDateValue: Double = 0
    
    override private init() {
        super.init()
        
        // 初始化 Sparkle 控制器
        // 使用 self 作为 userDriverDelegate 以便捕获进度
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
        self.updater = updaterController?.updater
        
        // 同步配置
        self.updater?.automaticallyChecksForUpdates = automaticallyChecksForUpdates
        self.updater?.automaticallyDownloadsAndInstallsUpdates = automaticallyDownloadsAndInstallsUpdates
        
        if lastCheckDateValue > 0 {
            self.lastUpdateCheckDate = Date(timeIntervalSince1970: lastCheckDateValue)
        }
    }
    
    /// 检查更新
    func checkForUpdates(isManual: Bool = false) async {
        guard state == .idle || state == .upToDate || state == .error("") else { return }
        
        if isManual {
            state = .checking
            // 手动触发检查
            updater?.checkForUpdates()
        } else {
            // 后台自动检查
            updater?.checkForUpdatesInBackground()
        }
    }
    
    /// 兼容非 async 调用
    func checkForUpdates(isManual: Bool = false) {
        Task {
            await checkForUpdates(isManual: isManual)
        }
    }
    
    /// 立即重启以完成更新
    func relaunch() {
        updater?.relaunchApplication()
    }
}

// MARK: - SPUUpdaterDelegate
extension UpdateManager: SPUUpdaterDelegate {
    
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        Task { @MainActor in
            // 发现更新，进入下载状态
            self.state = .downloading(progress: 0)
            Logger.shared.info("Found valid update: \(item.displayVersionString)")
        }
    }
    
    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        Task { @MainActor in
            self.lastUpdateCheckDate = Date()
            self.lastCheckDateValue = Date().timeIntervalSince1970
            
            // 只有在手动检查时才进入 upToDate 状态并弹窗
            if self.state == .checking {
                self.state = .upToDate
                self.alertTitle = NSLocalizedString("up_to_date_title", comment: "")
                self.alertMessage = NSLocalizedString("up_to_date_msg", comment: "")
                self.showAlert = true
            } else {
                self.state = .idle
            }
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        Task { @MainActor in
            self.state = .installing
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock installHandler: @escaping () -> Void) {
        Task { @MainActor in
            // 安装完成，等待重启
            self.state = .awaitingRelaunch(version: item.displayVersionString)
            self.alertTitle = NSLocalizedString("update_successful_title", comment: "")
            self.alertMessage = String(format: NSLocalizedString("update_successful_msg", comment: ""), item.displayVersionString)
            self.showAlert = true
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        Task { @MainActor in
            let nsError = error as NSError
            // 忽略“用户取消”或“没有更新”引发的错误提示
            if nsError.domain == SUSparkleErrorDomain && 
               (nsError.code == Int(SUError.noUpdateError.rawValue) || nsError.code == Int(SUError.userRejectedUpdateError.rawValue)) {
                if self.state == .checking {
                    self.updaterDidNotFindUpdate(updater)
                } else {
                    self.state = .idle
                }
                return
            }
            
            self.state = .error(error.localizedDescription)
            self.alertTitle = NSLocalizedString("update_check_failed", comment: "")
            self.alertMessage = error.localizedDescription
            self.showAlert = true
            Logger.shared.error("Update failed", error: error)
        }
    }
}

// MARK: - SPUStandardUserDriverDelegate
extension UpdateManager: SPUStandardUserDriverDelegate {
    
    nonisolated func userDriver(_ userDriver: SPUStandardUserDriver, didUpdateDownloadProgressWith progress: Double) {
        Task { @MainActor in
            self.state = .downloading(progress: progress)
        }
    }
    
    nonisolated func userDriver(_ userDriver: SPUStandardUserDriver, willDisplayUpdate item: SUAppcastItem, reply: @escaping (SPUUserUpdateChoice) -> Void) {
        // 当发现更新并准备显示 UI 时触发
        // 如果我们要全自动，可以直接回复 .install
        // 除非用户关闭了“自动下载安装”
        if self.automaticallyDownloadsAndInstallsUpdates {
            reply(.install)
        } else {
            // 否则遵循 Sparkle 默认行为（弹出标准窗口）
            reply(.show)
        }
    }
}