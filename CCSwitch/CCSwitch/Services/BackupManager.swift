import Foundation

// MARK: - Backup Manager
class BackupManager {
    static let shared = BackupManager()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    private let maxBackups: Int = 10

    private init() {}

    // MARK: - Backup Operations
    func backupCurrentSettings() throws {
        let sourceURL = ClaudeSettings.configFile

        // 检查源文件是否存在
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            return // 没有配置文件，无需备份
        }

        // 创建备份文件名
        let timestamp = dateFormatter.string(from: Date())
        let backupURL = ClaudeSettings.configDirectory
            .appendingPathComponent("settings.json.bak-\(timestamp)")

        // 执行备份
        try FileManager.default.copyItem(at: sourceURL, to: backupURL)

        // 清理旧备份
        try cleanupOldBackups()

        print("Configuration backed up to: \(backupURL.lastPathComponent)")
    }

    func restoreFromBackup(_ backupURL: URL) throws {
        // 验证备份文件
        guard backupURL.lastPathComponent.hasPrefix("settings.json.bak-") else {
            throw BackupError.invalidBackupFile
        }

        // 备份当前配置（在恢复之前）
        try backupCurrentSettings()

        // 恢复配置
        let targetURL = ClaudeSettings.configFile
        try ClaudeSettings.configDirectory.ensureDirectoryExists()

        // 如果目标文件存在，先删除
        if FileManager.default.fileExists(atPath: targetURL.path) {
            try FileManager.default.removeItem(at: targetURL)
        }

        try FileManager.default.copyItem(at: backupURL, to: targetURL)

        print("Configuration restored from: \(backupURL.lastPathComponent)")
    }

    // MARK: - Backup Management
    func getAllBackups() throws -> [URL] {
        let directory = ClaudeSettings.configDirectory
        guard FileManager.default.fileExists(atPath: directory.path) else {
            return []
        }

        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )

        let backupFiles = files.filter { $0.lastPathComponent.hasPrefix("settings.json.bak-") }

        // 按创建时间排序（最新的在前）
        let sortedBackups = try backupFiles.sorted { url1, url2 in
            let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            return date1 > date2
        }

        return sortedBackups
    }

    func deleteBackup(_ backupURL: URL) throws {
        guard backupURL.lastPathComponent.hasPrefix("settings.json.bak-") else {
            throw BackupError.invalidBackupFile
        }

        try FileManager.default.removeItem(at: backupURL)
        print("Backup deleted: \(backupURL.lastPathComponent)")
    }

    func deleteAllBackups() throws {
        let backups = try getAllBackups()
        for backup in backups {
            try FileManager.default.removeItem(at: backup)
        }
        print("All backups deleted")
    }

    // MARK: - Private Methods
    private func cleanupOldBackups() throws {
        let backups = try getAllBackups()

        // 保留最新的 maxBackups 个备份
        if backups.count > maxBackups {
            let oldBackups = Array(backups.dropFirst(maxBackups))
            for oldBackup in oldBackups {
                try FileManager.default.removeItem(at: oldBackup)
            }
        }
    }
}

// MARK: - Backup Error
enum BackupError: Error, LocalizedError {
    case invalidBackupFile
    case backupNotFound
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .invalidBackupFile:
            return "无效的备份文件"
        case .backupNotFound:
            return "未找到备份文件"
        case .restoreFailed:
            return "恢复配置失败"
        }
    }
}