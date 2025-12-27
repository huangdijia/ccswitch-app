import Foundation
import Cocoa
import UserNotifications

// MARK: - Configuration Manager (Refactored to use Protocol-based Architecture)

protocol SyncConfigManagerProtocol {
    var allVendors: [Vendor] { get }
    func addVendor(_ vendor: Vendor) throws
    func updateVendor(_ vendor: Vendor) throws
}

class ConfigManager: ObservableObject, SyncConfigManagerProtocol {
    static let shared = ConfigManager()

    private var observers: [ConfigObserver] = []
    
    // Service dependencies
    private let configRepository: ConfigurationRepository
    private let vendorSwitcher: VendorSwitcher
    private let notificationService: NotificationService
    private let settingsRepository: SettingsRepository

    private init(
        configRepository: ConfigurationRepository? = nil,
        vendorSwitcher: VendorSwitcher? = nil,
        notificationService: NotificationService? = nil,
        settingsRepository: SettingsRepository? = nil
    ) {
        // Use dependency injection with fallback to ServiceContainer
        self.configRepository = configRepository ?? ServiceContainer.shared.configRepository
        self.vendorSwitcher = vendorSwitcher ?? ServiceContainer.shared.vendorSwitcher
        self.notificationService = notificationService ?? ServiceContainer.shared.notificationService
        self.settingsRepository = settingsRepository ?? ServiceContainer.shared.settingsRepository
    }

    // MARK: - Initialization
    func initialize() {
        notificationService.requestPermission()
        loadOrCreateConfig()
        migrateFavoritesFromUserDefaults()
    }

    func cleanup() {
        observers.removeAll()
    }

    // MARK: - Configuration Loading
    func loadOrCreateConfig() {
        do {
            // 确保配置目录存在
            try CCSConfig.ensureConfigDirectoryExists()

            // Initialize repository (loads or creates config)
            if let fileRepo = configRepository as? FileConfigurationRepository {
                try fileRepo.loadConfiguration()
            }
            
            if configRepository.hasConfiguration() {
                let currentVendorId = (try? configRepository.getCurrentVendor()?.id) ?? "none"
                Logger.shared.logConfigLoad(currentVendorId)
                notifyObservers(.configLoaded)
            } else if !hasLegacyConfig {
                Logger.shared.info("Created default configuration")
                notifyObservers(.configLoaded)
            } else {
                // 有 legacy 配置但没有新配置，且还未迁移
                Logger.shared.warn("New configuration file not found, legacy config available for migration")
                notifyObservers(.configLoaded)
            }
        } catch {
            Logger.shared.error("Failed to load or create configuration: \(error)")
            notifyObservers(.configLoaded)
        }
    }

    // MARK: - Migration
    var hasLegacyConfig: Bool {
        return FileManager.default.fileExists(atPath: CCSConfig.legacyConfigFile.path)
    }

    var isConfigLoaded: Bool {
        return configRepository.hasConfiguration()
    }

    func migrateFromLegacy() throws -> Int {
        guard let legacyConfig = CCSConfig.loadFromFile(url: CCSConfig.legacyConfigFile) else {
            throw ConfigError.configNotLoaded
        }

        var importedCount = 0
        
        // Save all vendors from legacy config
        for legacyVendor in legacyConfig.vendors {
            // Find existing vendor by ID or Name
            if let existingVendor = allVendors.first(where: { $0.id == legacyVendor.id || $0.name == legacyVendor.name }) {
                // Merge logic: Combine env vars, legacy values take precedence in case of conflict
                let mergedEnv = existingVendor.env.merging(legacyVendor.env) { (_, new) in new }
                let updatedVendor = Vendor(id: existingVendor.id, name: existingVendor.name, env: mergedEnv)
                
                do {
                    try configRepository.updateVendor(updatedVendor)
                    importedCount += 1
                } catch {
                    Logger.shared.error("Failed to merge vendor \(legacyVendor.name)", error: error)
                }
            } else {
                // No conflict, add as new
                do {
                    try configRepository.addVendor(legacyVendor)
                    importedCount += 1
                } catch {
                    Logger.shared.error("Failed to add vendor \(legacyVendor.name)", error: error)
                }
            }
        }
        
        // Set current vendor if it was part of the migration
        if let currentId = legacyConfig.current {
            try? configRepository.setCurrentVendor(currentId)
        }
        
        notifyObservers(.configLoaded)
        Logger.shared.info("Migrated configuration from legacy file: \(importedCount) vendors processed (merged or added)")
        return importedCount
    }

    // MARK: - Public Interface
    var currentVendor: Vendor? {
        return try? configRepository.getCurrentVendor()
    }

    var allVendors: [Vendor] {
        return (try? configRepository.getAllVendors()) ?? []
    }

    func switchToVendor(with id: String) throws {
        try vendorSwitcher.switchToVendor(with: id)
        notifyObservers(.vendorChanged)
    }

    private let favoritesKey = "favoriteVendorIds"
    
    // MARK: - Favorites Management
    var favoriteVendorIds: Set<String> {
        get {
            return (try? configRepository.getFavorites()) ?? []
        }
        set {
            try? configRepository.setFavorites(newValue)
            notifyObservers(.vendorsUpdated) // Notify UI to refresh
        }
    }
    
    var favoriteVendors: [Vendor] {
        let all = allVendors
        let favIds = favoriteVendorIds
        // Sort by name or keep original order, filtering by favorites
        return all.filter { favIds.contains($0.id) }
    }
    
    func isFavorite(_ id: String) -> Bool {
        return favoriteVendorIds.contains(id)
    }
    
    func toggleFavorite(_ id: String) {
        var current = favoriteVendorIds
        if current.contains(id) {
            current.remove(id)
        } else {
            current.insert(id)
        }
        favoriteVendorIds = current
    }

    // MARK: - Presets Management
    var presetVendorIds: Set<String> {
        get {
            return (try? configRepository.getPresets()) ?? []
        }
        set {
            try? configRepository.setPresets(newValue)
            notifyObservers(.vendorsUpdated)
        }
    }

    func isPreset(_ id: String) -> Bool {
        return presetVendorIds.contains(id)
    }
    
    private func migrateFavoritesFromUserDefaults() {
        let defaults = UserDefaults.standard
        guard let legacyFavorites = defaults.stringArray(forKey: favoritesKey), !legacyFavorites.isEmpty else { return }
        
        // Only migrate if repository favorites are empty
        let repoFavorites = (try? configRepository.getFavorites()) ?? []
        if repoFavorites.isEmpty {
            try? configRepository.setFavorites(Set(legacyFavorites))
            Logger.shared.info("Migrated favorites from UserDefaults to Config")
            defaults.removeObject(forKey: favoritesKey)
        }
    }

    // MARK: - Vendor Management
    func addVendor(_ vendor: Vendor) throws {
        try configRepository.addVendor(vendor)
        Logger.shared.info("Added new vendor: \(vendor.id)")
        notifyObservers(.vendorsUpdated)
    }

    func updateVendor(_ vendor: Vendor) throws {
        try configRepository.updateVendor(vendor)
        Logger.shared.info("Updated vendor: \(vendor.id)")
        notifyObservers(.vendorsUpdated)
    }

    func removeVendor(with id: String) throws {
        try configRepository.removeVendor(with: id)
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
        NotificationCenter.default.post(name: .configDidChange, object: nil)
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

extension Notification.Name {

    static let configDidChange = Notification.Name("configDidChange")

}



// MARK: - Legacy Migration Logic

enum MigrationResult: Sendable {

    case success(count: Int)

    case failure(String)

}



@MainActor

class MigrationManager: ObservableObject {

    static let shared = MigrationManager()

    

    private let migrationKey = "has_migrated_from_legacy"

    

    @Published var isMigrating = false

    @Published var showMigrationPrompt = false

    @Published var legacyVendorsCount = 0

    @Published var legacyDefaultVendor: String?

    

    private init() {}

    

    nonisolated var hasLegacyConfig: Bool {

        let migrationKey = "has_migrated_from_legacy"

        return ConfigManager.shared.hasLegacyConfig && !UserDefaults.standard.bool(forKey: migrationKey)

    }

    

    func checkMigration(force: Bool = false) {

        if force || hasLegacyConfig {

            if let legacy = CCSConfig.loadFromFile(url: CCSConfig.legacyConfigFile) {

                self.legacyVendorsCount = legacy.vendors.count

                if let defaultId = legacy.current {

                    self.legacyDefaultVendor = legacy.vendors.first(where: { $0.id == defaultId })?.name ?? defaultId

                }

                self.showMigrationPrompt = true

            }

        }

    }

    

    func skipMigration() {

        UserDefaults.standard.set(true, forKey: migrationKey)

        showMigrationPrompt = false

    }

    

        func performMigration() async -> MigrationResult {

    

            self.isMigrating = true

    

            

    

            do {

    

                let count = try ConfigManager.shared.migrateFromLegacy()

    

                UserDefaults.standard.set(true, forKey: migrationKey)

    

                self.isMigrating = false

    

                return .success(count: count)

    

            } catch {

    

                Logger.shared.error("Migration failed", error: error)

    

                self.isMigrating = false

    

                return .failure(error.localizedDescription)

    

            }

    

        }

    

    }
