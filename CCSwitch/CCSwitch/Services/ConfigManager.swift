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
                Logger.shared.logConfigLoad(config.current ?? "none")
                notifyObservers(.configLoaded)
            } else if !hasLegacyConfig {
                // 如果没有 legacy 配置，生成默认配置
                let defaultConfig = CCSConfig.createDefault()
                try saveConfig(defaultConfig)
                currentConfig = defaultConfig
                Logger.shared.info("Created default configuration")
                notifyObservers(.configLoaded)
            } else {
                // 有 legacy 配置但没有新配置，且还未迁移
                Logger.shared.warn("New configuration file not found, legacy config available for migration")
                currentConfig = nil
                notifyObservers(.configLoaded)
            }
        } catch {
            Logger.shared.error("Failed to load or create configuration: \(error)")
            currentConfig = nil
            notifyObservers(.configLoaded)
        }
    }

    // MARK: - Migration
    var hasLegacyConfig: Bool {
        return FileManager.default.fileExists(atPath: CCSConfig.legacyConfigFile.path)
    }

    var isConfigLoaded: Bool {
        return currentConfig != nil
    }

    func migrateFromLegacy() throws {
        guard let legacyConfig = CCSConfig.loadFromFile(url: CCSConfig.legacyConfigFile) else {
            throw ConfigError.configNotLoaded
        }

        try saveConfig(legacyConfig)
        currentConfig = legacyConfig
        notifyObservers(.configLoaded)
        Logger.shared.info("Migrated configuration from legacy file")
    }

    // MARK: - Configuration Saving
    private func saveConfig(_ config: CCSConfig) throws {
        try CCSConfig.ensureConfigDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        try data.write(to: CCSConfig.configFile)
    }

    // MARK: - Public Interface
    var currentVendor: Vendor? {
        guard let config = currentConfig, let current = config.current else { return nil }
        return config.vendors.first { $0.id == current }
    }

    var allVendors: [Vendor] {
        return currentConfig?.vendors ?? []
    }

    func switchToVendor(with id: String) throws {
        guard var config = currentConfig else {
            throw ConfigError.configNotLoaded
        }

        guard let vendor = config.vendors.first(where: { $0.id == id }) else {
            throw ConfigError.vendorNotFound
        }

        // 备份当前 Claude 配置
        try BackupManager.shared.backupCurrentSettings()

        // 更新 Claude 设置
        try updateClaudeSettings(with: vendor.env)

        // 更新当前供应商并保存
        config.current = id
        try saveConfig(config)
        currentConfig = config

        // 记录日志
        Logger.shared.logVendorSwitch(from: config.current, to: id)

        // 显示通知
        if UserDefaults.standard.bool(forKey: "showSwitchNotification") {
            showNotification(title: "供应商已切换", message: "已切换至 \(vendor.name)")
        }

        notifyObservers(.vendorChanged)
    }

    // MARK: - Claude Settings Management
    private func updateClaudeSettings(with env: [String: String]) throws {
        let claudeConfigUrl = ClaudeSettings.configFile
        var claudeSettings: ClaudeSettings

        // 读取现有配置或创建新配置
        if FileManager.default.fileExists(atPath: claudeConfigUrl.path) {
            let data = try Data(contentsOf: claudeConfigUrl)
            claudeSettings = try JSONDecoder().decode(ClaudeSettings.self, from: data)
        } else {
            claudeSettings = ClaudeSettings()
        }

        // 从 env 映射到 ClaudeSettings
        // 优先使用 provider, model, apiKeyEnv 等显式键
        if let provider = env["provider"] {
            claudeSettings.provider = provider
        } else if env["ANTHROPIC_AUTH_TOKEN"] != nil {
             claudeSettings.provider = "anthropic" // 默认
        }

        if let model = env["ANTHROPIC_MODEL"] ?? env["model"] {
            claudeSettings.model = model
        }

        if let apiKeyEnv = env["apiKeyEnv"] {
            claudeSettings.apiKeyEnv = apiKeyEnv
        } else if env["ANTHROPIC_AUTH_TOKEN"] != nil {
            claudeSettings.apiKeyEnv = "ANTHROPIC_AUTH_TOKEN"
        }

        if let baseURL = env["ANTHROPIC_BASE_URL"] ?? env["baseURL"] {
            claudeSettings.baseURL = baseURL
        }

        // 确保目录存在
        try ClaudeSettings.configDirectory.ensureDirectoryExists()

        // 写入配置
        let data = try JSONEncoder().encode(claudeSettings)
        try data.write(to: claudeConfigUrl)
    }

    // MARK: - Vendor Management
    func addVendor(_ vendor: Vendor) throws {
        guard var config = currentConfig else {
            throw ConfigError.configNotLoaded
        }

        if config.vendors.contains(where: { $0.id == vendor.id }) {
            throw ConfigError.vendorAlreadyExists
        }

        config.vendors.append(vendor)
        try saveConfig(config)
        currentConfig = config
        
        Logger.shared.info("Added new vendor: \(vendor.id)")
        notifyObservers(.vendorsUpdated)
    }

    func updateVendor(_ vendor: Vendor) throws {
        guard var config = currentConfig else {
            throw ConfigError.configNotLoaded
        }

        guard let index = config.vendors.firstIndex(where: { $0.id == vendor.id }) else {
            throw ConfigError.vendorNotFound
        }

        config.vendors[index] = vendor
        try saveConfig(config)
        currentConfig = config
        
        Logger.shared.info("Updated vendor: \(vendor.id)")
        notifyObservers(.vendorsUpdated)
    }

    func removeVendor(with id: String) throws {
        guard var config = currentConfig else {
            throw ConfigError.configNotLoaded
        }

        guard config.vendors.contains(where: { $0.id == id }) else {
            throw ConfigError.vendorNotFound
        }
        
        if config.vendors.count <= 1 {
            throw ConfigError.cannotRemoveLastVendor
        }
        
        config.vendors.removeAll { $0.id == id }
        
        if config.current == id {
             config.current = config.vendors.first?.id
        }

        try saveConfig(config)
        currentConfig = config
        
        Logger.shared.info("Removed vendor: \(id)")
        notifyObservers(.vendorsUpdated)
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