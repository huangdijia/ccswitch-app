import Foundation

/// Dependency injection container for managing service instances
/// This provides a centralized location for service creation and management
class ServiceContainer {
    static let shared = ServiceContainer()
    
    // MARK: - Service Instances
    
    private(set) lazy var configRepository: ConfigurationRepository = {
        return FileConfigurationRepository()
    }()
    
    private(set) lazy var settingsWriter: SettingsWriter = {
        return ClaudeSettingsWriter()
    }()
    
    private(set) lazy var backupService: BackupService = {
        return BackupManager.shared
    }()
    
    private(set) lazy var notificationService: NotificationService = {
        return UserNotificationService(settings: settingsRepository)
    }()
    
    private(set) lazy var settingsRepository: SettingsRepository = {
        return UserDefaultsSettingsRepository()
    }()
    
    private(set) lazy var vendorSwitcher: VendorSwitcher = {
        return DefaultVendorSwitcher(
            configRepository: configRepository,
            settingsWriter: settingsWriter,
            backupService: backupService,
            notificationService: notificationService,
            settingsRepository: settingsRepository
        )
    }()
    
    private(set) lazy var syncManager: SyncManager = {
        return SyncManager.shared
    }()
    
    private init() {}
    
    // MARK: - Service Registration (for testing)
    
    /// Register a custom configuration repository (useful for testing)
    func register(configRepository: ConfigurationRepository) {
        self.configRepository = configRepository
    }
    
    /// Register a custom settings writer (useful for testing)
    func register(settingsWriter: SettingsWriter) {
        self.settingsWriter = settingsWriter
    }
    
    /// Register a custom backup service (useful for testing)
    func register(backupService: BackupService) {
        self.backupService = backupService
    }
    
    /// Register a custom notification service (useful for testing)
    func register(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    /// Register a custom settings repository (useful for testing)
    func register(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }
}
