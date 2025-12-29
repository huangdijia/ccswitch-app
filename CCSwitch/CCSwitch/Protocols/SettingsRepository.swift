import Foundation

/// Keys for user settings
enum SettingsKey: String {
    case autoBackup
    case showSwitchNotification
    case statusBarDisplayMode
    case autoLoadConfig
    case showDebugLogs
    case confirmBackupDeletion
}

/// Protocol for user preferences storage
/// This abstraction allows for different storage mechanisms and improves testability
protocol SettingsRepository {
    /// Get a boolean setting
    /// - Parameter key: The setting key
    /// - Returns: The boolean value, or false if not set
    func getBool(for key: SettingsKey) -> Bool
    
    /// Set a boolean setting
    /// - Parameters:
    ///   - value: The boolean value to set
    ///   - key: The setting key
    func setBool(_ value: Bool, for key: SettingsKey)
    
    /// Get a string setting
    /// - Parameter key: The setting key
    /// - Returns: The string value, or nil if not set
    func getString(for key: SettingsKey) -> String?
    
    /// Set a string setting
    /// - Parameters:
    ///   - value: The string value to set
    ///   - key: The setting key
    func setString(_ value: String?, for key: SettingsKey)
}

/// Default implementation using UserDefaults
class UserDefaultsSettingsRepository: SettingsRepository {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func getBool(for key: SettingsKey) -> Bool {
        return userDefaults.bool(forKey: key.rawValue)
    }
    
    func setBool(_ value: Bool, for key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }
    
    func getString(for key: SettingsKey) -> String? {
        return userDefaults.string(forKey: key.rawValue)
    }
    
    func setString(_ value: String?, for key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }
}

/// Mock implementation for testing
class MockSettingsRepository: SettingsRepository {
    private var storage: [String: Any] = [:]
    
    func getBool(for key: SettingsKey) -> Bool {
        return storage[key.rawValue] as? Bool ?? false
    }
    
    func setBool(_ value: Bool, for key: SettingsKey) {
        storage[key.rawValue] = value
    }
    
    func getString(for key: SettingsKey) -> String? {
        return storage[key.rawValue] as? String
    }
    
    func setString(_ value: String?, for key: SettingsKey) {
        storage[key.rawValue] = value
    }
}
