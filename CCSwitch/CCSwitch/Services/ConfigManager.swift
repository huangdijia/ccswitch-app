import Foundation
import Cocoa

// MARK: - Configuration Manager
class ConfigManager {
    static let shared = ConfigManager()

    private var currentConfig: CCSConfig?
    private var observers: [ConfigObserver] = []

    private init() {}

    // MARK: - Initialization
    func initialize() {
        loadOrCreateConfig()
    }

    func cleanup() {
        observers.removeAll()
    }

    // MARK: - Configuration Loading
    func loadOrCreateConfig() {
        do {
            // 确保配置目录存在
            try CCSConfig.ensureConfigDirectoryExists()

            // 尝试加载现有配置
            if let config = CCSConfig.loadFromFile() {
                currentConfig = config

                // 验证当前供应商是否存在于供应商列表中
                if !config.vendors.contains(where: { $0.id == config.current }) {
                    currentConfig = config
                }

                Logger.shared.logConfigLoad(config.current)
                notifyObservers(.configLoaded)
            } else {
                // 配置文件不存在或格式错误
                Logger.shared.warn("Configuration file not found or invalid format")
                currentConfig = nil
                notifyObservers(.configLoaded)
            }
        } catch {
            Logger.shared.error("Failed to load configuration: \(error)")
            currentConfig = nil
            notifyObservers(.configLoaded)
        }
    }

    // MARK: - Configuration Saving
    private func saveConfig(_ config: CCSConfig) throws {
        try CCSConfig.ensureConfigDirectoryExists()
        let data = try JSONEncoder().encode(config)
        try data.write(to: CCSConfig.configFile)
    }

    // MARK: - Public Interface
    var currentVendor: Vendor? {
        guard let config = currentConfig else { return nil }
        return config.vendors.first { $0.id == config.current }
    }

    var allVendors: [Vendor] {
        return currentConfig?.vendors ?? []
    }

    func switchToVendor(with id: String) throws {
        guard let config = currentConfig else {
            throw ConfigError.configNotLoaded
        }

        guard let vendor = config.vendors.first(where: { $0.id == id }) else {
            throw ConfigError.vendorNotFound
        }

        // 备份当前 Claude 配置
        try BackupManager.shared.backupCurrentSettings()

        // 更新 Claude 设置 - 使用环境变量方式
        try updateClaudeSettingsFromProfile(config.profiles[id])

        // 记录日志
        Logger.shared.logVendorSwitch(from: config.current, to: id)

        // 显示通知
        if UserDefaults.standard.bool(forKey: "showSwitchNotification") {
            showNotification(title: "供应商已切换", message: "已切换至 \(vendor.displayName)")
        }

        notifyObservers(.vendorChanged)
    }

    // 更新 Claude 设置从 profile 配置
    private func updateClaudeSettingsFromProfile(_ profile: [String: String]?) throws {
        guard let profile = profile else {
            throw ConfigError.vendorNotFound
        }

        let claudeConfigUrl = ClaudeSettings.configFile
        var claudeSettings: ClaudeSettings

        // 读取现有配置或创建新配置
        if FileManager.default.fileExists(atPath: claudeConfigUrl.path) {
            let data = try Data(contentsOf: claudeConfigUrl)
            claudeSettings = try JSONDecoder().decode(ClaudeSettings.self, from: data)
        } else {
            claudeSettings = ClaudeSettings()
        }

        // 从 profile 更新配置
        if let auth = profile["ANTHROPIC_AUTH_TOKEN"] {
            // 注意：这里可能需要将 token 写入环境变量或特殊配置
            claudeSettings.apiKeyEnv = "ANTHROPIC_AUTH_TOKEN"
        }

        if let baseURL = profile["ANTHROPIC_BASE_URL"] {
            claudeSettings.baseURL = baseURL
        }

        if let model = profile["ANTHROPIC_MODEL"] {
            claudeSettings.model = model
        }

        // 确保目录存在
        try ClaudeSettings.configDirectory.ensureDirectoryExists()

        // 写入配置
        let data = try JSONEncoder().encode(claudeSettings)
        try data.write(to: claudeConfigUrl)
    }

    // 注意：由于配置文件格式为只读，不支持动态修改供应商
    func addVendor(_ vendor: Vendor) throws {
        throw ConfigError.operationNotSupported
    }

    func updateVendor(_ vendor: Vendor) throws {
        throw ConfigError.operationNotSupported
    }

    func removeVendor(with id: String) throws {
        throw ConfigError.operationNotSupported
    }

    // MARK: - Claude Settings Management
    private func updateClaudeSettings(with patch: ClaudeSettingsPatch) throws {
        let claudeConfigUrl = ClaudeSettings.configFile
        var claudeSettings: ClaudeSettings

        // 读取现有配置或创建新配置
        if FileManager.default.fileExists(atPath: claudeConfigUrl.path) {
            let data = try Data(contentsOf: claudeConfigUrl)
            claudeSettings = try JSONDecoder().decode(ClaudeSettings.self, from: data)
        } else {
            claudeSettings = ClaudeSettings()
        }

        // 合并新配置
        claudeSettings.merge(patch: patch)

        // 确保目录存在
        try ClaudeSettings.configDirectory.ensureDirectoryExists()

        // 写入配置
        let data = try JSONEncoder().encode(claudeSettings)
        try data.write(to: claudeConfigUrl)
    }

    // MARK: - Observer Pattern
    func addObserver(_ observer: ConfigObserver) {
        observers.append(observer)
    }

    func removeObserver(_ observer: ConfigObserver) {
        observers.removeAll { $0 === observer }
    }

    private func notifyObservers(_ event: ConfigEvent) {
        observers.forEach { $0.configDidChange(event) }
    }

    // MARK: - Helper Methods
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Supporting Types
protocol ConfigObserver: AnyObject {
    func configDidChange(_ event: ConfigEvent)
}

enum ConfigEvent {
    case configLoaded
    case vendorChanged
    case vendorsUpdated
}

enum ConfigError: Error, LocalizedError {
    case configNotLoaded
    case vendorNotFound
    case vendorAlreadyExists
    case cannotRemoveLastVendor
    case corruptedConfig
    case operationNotSupported

    var errorDescription: String? {
        switch self {
        case .configNotLoaded:
            return "配置未加载"
        case .vendorNotFound:
            return "未找到指定的供应商"
        case .vendorAlreadyExists:
            return "供应商已存在"
        case .cannotRemoveLastVendor:
            return "无法删除最后一个供应商"
        case .corruptedConfig:
            return "配置文件损坏"
        case .operationNotSupported:
            return "当前配置格式不支持此操作"
        }
    }
}

// MARK: - URL Extensions
extension URL {
    func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: self,
            withIntermediateDirectories: true
        )
    }
}