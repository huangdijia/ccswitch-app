# Extension Guide for CCSwitch

This guide explains how to extend CCSwitch with new features, vendors, and storage backends.

## Table of Contents

1. [Adding a New Vendor Template](#adding-a-new-vendor-template)
2. [Adding a Custom Storage Backend](#adding-a-custom-storage-backend)
3. [Adding Custom Notification Channels](#adding-custom-notification-channels)
4. [Creating Custom Settings Repositories](#creating-custom-settings-repositories)
5. [Extending the Backup System](#extending-the-backup-system)

## Adding a New Vendor Template

Vendor templates make it easy to add support for new AI providers with preconfigured settings.

### Step 1: Define the Template

Add a new static property to `VendorTemplate`:

```swift
extension VendorTemplate {
    static let myNewVendor = VendorTemplate(
        id: "my-vendor",
        name: "My Vendor Name",
        baseURL: "https://api.myvendor.com",
        requiredEnvVars: [
            "MY_VENDOR_API_KEY",
            "MY_VENDOR_BASE_URL"
        ],
        optionalEnvVars: [
            "MY_VENDOR_MODEL",
            "MY_VENDOR_TIMEOUT"
        ],
        defaultValues: [
            "MY_VENDOR_BASE_URL": "https://api.myvendor.com",
            "MY_VENDOR_MODEL": "default-model",
            "MY_VENDOR_TIMEOUT": "30"
        ],
        description: "My Vendor AI Service"
    )
}
```

### Step 2: Add to Templates List

```swift
extension VendorTemplate {
    static let templates: [VendorTemplate] = [
        .anthropicOfficial,
        .deepseek,
        .openai,
        .azureOpenAI,
        .anyRouter,
        .myNewVendor, // Add your template here
        .custom
    ]
}
```

### Step 3: Use in UI (Optional)

Create a UI to select from templates:

```swift
struct VendorTemplatePickerView: View {
    @State private var selectedTemplate: VendorTemplate?
    
    var body: some View {
        Picker("Template", selection: $selectedTemplate) {
            ForEach(VendorTemplate.templates, id: \.id) { template in
                Text(template.name).tag(template as VendorTemplate?)
            }
        }
        
        Button("Create from Template") {
            if let template = selectedTemplate {
                let vendor = try? template.createVendor(with: [
                    "MY_VENDOR_API_KEY": apiKeyInput
                ])
                // Use vendor...
            }
        }
    }
}
```

## Adding a Custom Storage Backend

You can replace file-based storage with a database, remote service, or any other backend.

### Step 1: Implement ConfigurationRepository

```swift
import Foundation

class DatabaseConfigurationRepository: ConfigurationRepository {
    private let database: MyDatabase
    
    init(database: MyDatabase) {
        self.database = database
    }
    
    func getAllVendors() throws -> [Vendor] {
        return try database.query("SELECT * FROM vendors")
            .map { row in
                Vendor(
                    id: row["id"],
                    name: row["name"],
                    env: row["env"]
                )
            }
    }
    
    func getVendor(by id: String) throws -> Vendor? {
        return try database.query("SELECT * FROM vendors WHERE id = ?", id)
            .first
            .map { row in
                Vendor(
                    id: row["id"],
                    name: row["name"],
                    env: row["env"]
                )
            }
    }
    
    func getCurrentVendor() throws -> Vendor? {
        let currentId = try database.query("SELECT current_vendor FROM config")
            .first?["current_vendor"]
        
        guard let id = currentId else { return nil }
        return try getVendor(by: id)
    }
    
    func setCurrentVendor(_ vendorId: String) throws {
        try database.execute("UPDATE config SET current_vendor = ?", vendorId)
    }
    
    func addVendor(_ vendor: Vendor) throws {
        try database.execute(
            "INSERT INTO vendors (id, name, env) VALUES (?, ?, ?)",
            vendor.id,
            vendor.name,
            vendor.env
        )
    }
    
    func updateVendor(_ vendor: Vendor) throws {
        try database.execute(
            "UPDATE vendors SET name = ?, env = ? WHERE id = ?",
            vendor.name,
            vendor.env,
            vendor.id
        )
    }
    
    func removeVendor(with vendorId: String) throws {
        try database.execute("DELETE FROM vendors WHERE id = ?", vendorId)
    }
    
    func hasConfiguration() -> Bool {
        return (try? database.query("SELECT COUNT(*) FROM vendors").first?["count"]) ?? 0 > 0
    }
}
```

### Step 2: Register the Implementation

```swift
// In app initialization
let database = MyDatabase()
let repository = DatabaseConfigurationRepository(database: database)
ServiceContainer.shared.register(configRepository: repository)
```

## Adding Custom Notification Channels

Add support for Slack, email, webhooks, or other notification channels.

### Step 1: Implement NotificationService

```swift
import Foundation

class SlackNotificationService: NotificationService {
    private let webhookURL: URL
    private let settings: SettingsRepository
    
    init(webhookURL: URL, settings: SettingsRepository) {
        self.webhookURL = webhookURL
        self.settings = settings
    }
    
    func notify(title: String, message: String) {
        guard settings.getBool(for: .showSwitchNotification) else {
            return
        }
        
        let payload: [String: Any] = [
            "text": "\(title): \(message)",
            "username": "CCSwitch Bot",
            "icon_emoji": ":robot_face:"
        ]
        
        var request = URLRequest(url: webhookURL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.shared.error("Slack notification failed: \(error)")
            }
        }.resume()
    }
    
    func requestPermission() {
        // Slack doesn't need permission
    }
}
```

### Step 2: Use Multi-Channel Notifications

```swift
class CompositeNotificationService: NotificationService {
    private let services: [NotificationService]
    
    init(services: [NotificationService]) {
        self.services = services
    }
    
    func notify(title: String, message: String) {
        services.forEach { $0.notify(title: title, message: message) }
    }
    
    func requestPermission() {
        services.forEach { $0.requestPermission() }
    }
}

// Usage
let userNotifications = UserNotificationService()
let slackNotifications = SlackNotificationService(
    webhookURL: URL(string: "https://hooks.slack.com/...")!,
    settings: UserDefaultsSettingsRepository()
)

let composite = CompositeNotificationService(
    services: [userNotifications, slackNotifications]
)

ServiceContainer.shared.register(notificationService: composite)
```

## Creating Custom Settings Repositories

Store user preferences in iCloud, a remote server, or custom storage.

### Step 1: Implement SettingsRepository

```swift
import Foundation

class CloudSettingsRepository: SettingsRepository {
    private let cloudStore: NSUbiquitousKeyValueStore
    
    init(cloudStore: NSUbiquitousKeyValueStore = .default) {
        self.cloudStore = cloudStore
    }
    
    func getBool(for key: SettingsKey) -> Bool {
        return cloudStore.bool(forKey: key.rawValue)
    }
    
    func setBool(_ value: Bool, for key: SettingsKey) {
        cloudStore.set(value, forKey: key.rawValue)
        cloudStore.synchronize()
    }
    
    func getString(for key: SettingsKey) -> String? {
        return cloudStore.string(forKey: key.rawValue)
    }
    
    func setString(_ value: String?, for key: SettingsKey) {
        if let value = value {
            cloudStore.set(value, forKey: key.rawValue)
        } else {
            cloudStore.removeObject(forKey: key.rawValue)
        }
        cloudStore.synchronize()
    }
}
```

### Step 2: Register the Implementation

```swift
let cloudSettings = CloudSettingsRepository()
ServiceContainer.shared.register(settingsRepository: cloudSettings)
```

## Extending the Backup System

Add cloud backup, compression, or encryption.

### Step 1: Implement BackupService

```swift
import Foundation
import Compression

class CompressedBackupService: BackupService {
    private let baseService: BackupService
    
    init(baseService: BackupService = BackupManager.shared) {
        self.baseService = baseService
    }
    
    func backupCurrentSettings() throws {
        try baseService.backupCurrentSettings()
        
        // Compress the latest backup
        let backups = try baseService.getAllBackups()
        guard let latest = backups.first else { return }
        
        let data = try Data(contentsOf: latest)
        let compressed = try compress(data: data)
        try compressed.write(to: latest.appendingPathExtension("gz"))
    }
    
    func restoreFromBackup(_ backupURL: URL) throws {
        var urlToRestore = backupURL
        
        // Decompress if needed
        if backupURL.pathExtension == "gz" {
            let compressed = try Data(contentsOf: backupURL)
            let decompressed = try decompress(data: compressed)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            try decompressed.write(to: tempURL)
            urlToRestore = tempURL
        }
        
        try baseService.restoreFromBackup(urlToRestore)
    }
    
    func getAllBackups() throws -> [URL] {
        return try baseService.getAllBackups()
    }
    
    func deleteBackup(_ backupURL: URL) throws {
        try baseService.deleteBackup(backupURL)
    }
    
    func deleteAllBackups() throws {
        try baseService.deleteAllBackups()
    }
    
    private func compress(data: Data) throws -> Data {
        // Implementation of compression
        return data // Placeholder
    }
    
    private func decompress(data: Data) throws -> Data {
        // Implementation of decompression
        return data // Placeholder
    }
}
```

### Step 2: Use Decorator Pattern

```swift
let compressedBackup = CompressedBackupService(
    baseService: BackupManager.shared
)

ServiceContainer.shared.register(backupService: compressedBackup)
```

## Best Practices

### 1. Follow Protocol Contracts

Always implement all protocol methods, even if some are no-ops:

```swift
class MyCustomService: NotificationService {
    func notify(title: String, message: String) {
        // Custom implementation
    }
    
    func requestPermission() {
        // No-op if not needed, but must be implemented
    }
}
```

### 2. Handle Errors Gracefully

Use custom error types for better error handling:

```swift
enum MyServiceError: Error, LocalizedError {
    case networkError(underlying: Error)
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidConfiguration:
            return "Invalid configuration"
        }
    }
}
```

### 3. Add Tests

Always create tests for custom implementations:

```swift
class MyCustomRepositoryTests: XCTestCase {
    func testGetAllVendors() throws {
        let repo = MyCustomRepository()
        let vendors = try repo.getAllVendors()
        XCTAssertFalse(vendors.isEmpty)
    }
}
```

### 4. Document Extensions

Add documentation comments to your extensions:

```swift
/// Custom repository that stores configuration in PostgreSQL
///
/// This implementation provides distributed configuration management
/// across multiple instances of CCSwitch.
class PostgreSQLConfigurationRepository: ConfigurationRepository {
    // Implementation...
}
```

## Example: Complete Extension

Here's a complete example that adds Redis-based configuration storage:

```swift
import Foundation
import Redis

class RedisConfigurationRepository: ConfigurationRepository {
    private let redis: RedisClient
    private let keyPrefix = "ccswitch:"
    
    init(host: String = "localhost", port: Int = 6379) throws {
        self.redis = try RedisClient(host: host, port: port)
    }
    
    func getAllVendors() throws -> [Vendor] {
        let keys = try redis.keys("\(keyPrefix)vendor:*")
        return try keys.compactMap { key in
            guard let json = try redis.get(key) else { return nil }
            return try JSONDecoder().decode(Vendor.self, from: json.data(using: .utf8)!)
        }
    }
    
    func getVendor(by id: String) throws -> Vendor? {
        guard let json = try redis.get("\(keyPrefix)vendor:\(id)") else {
            return nil
        }
        return try JSONDecoder().decode(Vendor.self, from: json.data(using: .utf8)!)
    }
    
    func getCurrentVendor() throws -> Vendor? {
        guard let currentId = try redis.get("\(keyPrefix)current") else {
            return nil
        }
        return try getVendor(by: currentId)
    }
    
    func setCurrentVendor(_ vendorId: String) throws {
        try redis.set("\(keyPrefix)current", value: vendorId)
    }
    
    func addVendor(_ vendor: Vendor) throws {
        let key = "\(keyPrefix)vendor:\(vendor.id)"
        let exists = try redis.exists(key)
        
        guard !exists else {
            throw ConfigurationError.vendorAlreadyExists
        }
        
        let json = try JSONEncoder().encode(vendor)
        try redis.set(key, value: String(data: json, encoding: .utf8)!)
    }
    
    func updateVendor(_ vendor: Vendor) throws {
        let key = "\(keyPrefix)vendor:\(vendor.id)"
        let exists = try redis.exists(key)
        
        guard exists else {
            throw ConfigurationError.vendorNotFound
        }
        
        let json = try JSONEncoder().encode(vendor)
        try redis.set(key, value: String(data: json, encoding: .utf8)!)
    }
    
    func removeVendor(with vendorId: String) throws {
        let key = "\(keyPrefix)vendor:\(vendorId)"
        try redis.del(key)
    }
    
    func hasConfiguration() -> Bool {
        return (try? redis.exists("\(keyPrefix)current")) ?? false
    }
}

// Usage
let redisRepo = try RedisConfigurationRepository(host: "redis.example.com")
ServiceContainer.shared.register(configRepository: redisRepo)
```

## Contributing

When contributing extensions:

1. Follow the existing code style
2. Add comprehensive tests
3. Document your changes
4. Update this guide with examples
5. Create a pull request with a clear description

For questions or discussions, open an issue on GitHub.
