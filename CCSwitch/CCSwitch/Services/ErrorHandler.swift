import Foundation
import Cocoa

// MARK: - Error Handler
class ErrorHandler {
    static let shared = ErrorHandler()

    private init() {}

    // MARK: - Public Methods
    func handle(_ error: Error, operation: String = "Unknown operation") {
        Logger.shared.logError(error.localizedDescription, operation: operation)

        // 根据错误类型决定是否显示用户提示
        if shouldShowUserAlert(for: error) {
            showErrorAlert(error: error, operation: operation)
        }
    }

    func handleConfigError(_ error: ConfigError, operation: String) {
        Logger.shared.error("Config error in \(operation): \(error.localizedDescription)")

        let message: String
        let informativeText: String

        switch error {
        case .configNotLoaded:
            message = "配置加载失败"
            informativeText = "无法加载 CCSwitch 配置文件。请检查配置文件是否存在且格式正确。"
        case .vendorNotFound:
            message = "供应商未找到"
            informativeText = "指定的供应商不存在。请检查供应商配置。"
        case .vendorAlreadyExists:
            message = "供应商已存在"
            informativeText = "无法添加供应商，该 ID 已被使用。请使用不同的 ID。"
        case .cannotRemoveLastVendor:
            message = "无法删除最后一个供应商"
            informativeText = "至少需要保留一个供应商配置。"
        case .corruptedConfig:
            message = "配置文件损坏"
            informativeText = "配置文件格式错误。请手动修复或删除配置文件后重新配置。"
        case .operationNotSupported:
            message = "操作不支持"
            informativeText = "当前配置格式为只读，不支持修改供应商。"
        }

        showAlert(message: message, informativeText: informativeText)
    }

    func handleBackupError(_ error: BackupError, operation: String) {
        Logger.shared.error("Backup error in \(operation): \(error.localizedDescription)")

        let message: String
        let informativeText: String

        switch error {
        case .invalidBackupFile:
            message = "无效的备份文件"
            informativeText = "选择的文件不是有效的备份文件。"
        case .backupNotFound:
            message = "备份文件未找到"
            informativeText = "无法找到指定的备份文件。"
        case .restoreFailed:
            message = "恢复失败"
            informativeText = "恢复配置时发生错误。请检查备份文件完整性。"
        }

        showAlert(message: message, informativeText: informativeText)
    }

    // MARK: - Private Methods
    private func shouldShowUserAlert(for error: Error) -> Bool {
        // 根据错误类型和用户设置决定是否显示提示
        if UserDefaults.standard.bool(forKey: "disableErrorAlerts") {
            return false
        }

        // 某些错误类型需要总是显示
        if error is ConfigError || error is BackupError {
            return true
        }

        // 文件系统权限错误
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoPermissionError {
            return true
        }

        return false
    }

    private func showErrorAlert(error: Error, operation: String) {
        let nsError = error as NSError

        var message: String
        var informativeText: String

        if nsError.domain == NSCocoaErrorDomain {
            switch nsError.code {
            case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
                message = "权限不足"
                informativeText = "应用没有足够的权限访问配置文件。请检查文件权限。"
            case NSFileReadNoSuchFileError:
                message = "文件未找到"
                informativeText = "无法找到指定的配置文件。"
            case NSFileWriteFileExistsError:
                message = "文件已存在"
                informativeText = "目标文件已存在，无法覆盖。"
            default:
                message = "操作失败"
                informativeText = error.localizedDescription
            }
        } else {
            message = "发生错误"
            informativeText = "在执行 \"\(operation)\" 时发生错误：\n\(error.localizedDescription)"
        }

        showAlert(message: message, informativeText: informativeText)
    }

    private func showAlert(message: String, informativeText: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = informativeText
            alert.alertStyle = .critical
            alert.addButton(withTitle: "确定")

            // 如果是配置相关错误，提供查看配置文件的选项
            if message.contains("配置") {
                alert.addButton(withTitle: "查看配置文件")
                let response = alert.runModal()
                if response == .alertSecondButtonReturn {
                    NSWorkspace.shared.selectFile(CCSConfig.configFile.path, inFileViewerRootedAtPath: "")
                }
            } else {
                alert.runModal()
            }
        }
    }
}

// MARK: - Error Reporting
extension ErrorHandler {
    func reportIssue(description: String) {
        let alert = NSAlert()
        alert.messageText = "报告问题"
        alert.informativeText = "请描述您遇到的问题："
        alert.addButton(withTitle: "发送报告")
        alert.addButton(withTitle: "取消")

        let textView = NSTextView()
        textView.string = description
        textView.isEditable = true
        textView.font = NSFont.systemFont(ofSize: 12)

        alert.accessoryView = NSScrollView()
        (alert.accessoryView as? NSScrollView)?.documentView = textView
        alert.accessoryView?.frame = NSRect(x: 0, y: 0, width: 400, height: 200)

        if alert.runModal() == .alertFirstButtonReturn {
            let issueDescription = textView.string
            sendIssueReport(description: issueDescription)
        }
    }

    private func sendIssueReport(description: String) {
        // 收集系统信息
        let info = collectSystemInfo()
        let fullReport = """
        Issue Description:
        \(description)

        System Information:
        \(info)

        Logs:
        \(Logger.shared.getLogContents())
        """

        // 创建报告文件
        do {
            let reportDir = CCSConfig.configDirectory.appendingPathComponent("reports")
            try reportDir.ensureDirectoryExists()

            let timestamp = ISO8601DateFormatter().string(from: Date())
            let reportFile = reportDir.appendingPathComponent("issue-\(timestamp).txt")
            try fullReport.write(to: reportFile, atomically: true, encoding: .utf8)

            let alert = NSAlert()
            alert.messageText = "报告已保存"
            alert.informativeText = "问题报告已保存到：\(reportFile.path)"
            alert.alertStyle = .informational
            alert.runModal()

            // 打开报告文件所在目录
            NSWorkspace.shared.selectFile(reportFile.path, inFileViewerRootedAtPath: "")
        } catch {
            let alert = NSAlert()
            alert.messageText = "保存失败"
            alert.informativeText = "无法保存问题报告：\(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    private func collectSystemInfo() -> String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let appVersion = AppInfo.version

        return """
        macOS Version: \(osVersion)
        App Version: \(appVersion)
        """
    }
}