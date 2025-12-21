# Architecture Documentation

## Overview

CCSwitch adopts a **protocol-oriented architecture** with **dependency injection** to improve code reusability, testability, and maintainability.

## Core Principles

### 1. Protocol-Oriented Design
All major components are defined as protocols with concrete implementations, allowing:
- Easy mocking for testing
- Flexible implementation swapping
- Clear contracts between components

### 2. Dependency Injection
Components receive their dependencies through initializers rather than creating them internally:
- Improves testability
- Reduces coupling
- Makes dependencies explicit

### 3. Single Responsibility
Each component has a well-defined, focused purpose:
- `VendorSwitcher`: Handles vendor switching logic
- `ConfigurationRepository`: Manages configuration persistence
- `SettingsWriter`: Writes to Claude settings
- `BackupService`: Manages backups
- `NotificationService`: Handles user notifications

### 4. Separation of Concerns
Clear boundaries between layers:
- **Models**: Data structures (Vendor, CCSConfig, ClaudeSettings)
- **Protocols**: Abstract interfaces
- **Services**: Business logic implementations
- **Views**: UI layer (SwiftUI)
- **App**: Application lifecycle

## Architecture Layers

```
┌─────────────────────────────────────────┐
│              Views (SwiftUI)            │
│  VendorManagementView, SettingsView...  │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│          ConfigManager (Facade)         │
│     Coordinates between services        │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│          Service Container              │
│   Manages dependency injection          │
└─┬──────────┬──────────┬─────────┬──────┘
  │          │          │         │
  ▼          ▼          ▼         ▼
┌─────┐  ┌──────┐  ┌────────┐  ┌────────┐
│Vendor│  │Config│  │Settings│  │Backup  │
│Switch│  │Repo  │  │Writer  │  │Service │
└─────┘  └──────┘  └────────┘  └────────┘
  │          │          │         │
  └──────────┴──────────┴─────────┘
                 │
┌────────────────▼────────────────────────┐
│          Models & Storage               │
│  Vendor, CCSConfig, ClaudeSettings      │
└─────────────────────────────────────────┘
```

## Key Components

### Protocols

#### VendorSwitcher
Handles vendor switching operations.

```swift
protocol VendorSwitcher {
    func switchToVendor(with vendorId: String) throws
    func getCurrentVendor() -> Vendor?
}
```

**Implementation**: `DefaultVendorSwitcher`
- Orchestrates backup, settings writing, and notifications
- Delegates to specialized services

#### ConfigurationRepository
Manages configuration persistence.

```swift
protocol ConfigurationRepository {
    func getAllVendors() throws -> [Vendor]
    func getVendor(by id: String) throws -> Vendor?
    func getCurrentVendor() throws -> Vendor?
    func setCurrentVendor(_ vendorId: String) throws
    func addVendor(_ vendor: Vendor) throws
    func updateVendor(_ vendor: Vendor) throws
    func removeVendor(with vendorId: String) throws
    func hasConfiguration() -> Bool
}
```

**Implementation**: `FileConfigurationRepository`
- Reads/writes to `~/.ccswitch/vendors.json`
- Handles configuration validation
- Manages vendor CRUD operations

#### SettingsWriter
Writes environment settings to Claude configuration.

```swift
protocol SettingsWriter {
    func writeSettings(_ env: [String: String]) throws
}
```

**Implementation**: `ClaudeSettingsWriter`
- Writes to `~/.claude/settings.json`
- Preserves existing non-env fields
- Ensures directory structure exists

#### BackupService
Manages backup operations.

```swift
protocol BackupService {
    func backupCurrentSettings() throws
    func restoreFromBackup(_ backupURL: URL) throws
    func getAllBackups() throws -> [URL]
    func deleteBackup(_ backupURL: URL) throws
    func deleteAllBackups() throws
}
```

**Implementation**: `BackupManager`
- Creates timestamped backups
- Manages backup rotation (keeps last 10)
- Supports restore operations

#### NotificationService
Handles user notifications.

```swift
protocol NotificationService {
    func notify(title: String, message: String)
    func requestPermission()
}
```

**Implementation**: `UserNotificationService`
- Uses macOS UserNotifications framework
- Checks user preferences before notifying
- Handles permission requests

#### SettingsRepository
Manages user preferences storage.

```swift
protocol SettingsRepository {
    func getBool(for key: SettingsKey) -> Bool
    func setBool(_ value: Bool, for key: SettingsKey)
    func getString(for key: SettingsKey) -> String?
    func setString(_ value: String?, for key: SettingsKey)
}
```

**Implementation**: `UserDefaultsSettingsRepository`
- Uses UserDefaults for persistence
- Type-safe setting keys

### Service Container

Centralized dependency management:

```swift
class ServiceContainer {
    static let shared = ServiceContainer()
    
    lazy var configRepository: ConfigurationRepository = FileConfigurationRepository()
    lazy var settingsWriter: SettingsWriter = ClaudeSettingsWriter()
    lazy var backupService: BackupService = BackupManager.shared
    lazy var notificationService: NotificationService = UserNotificationService()
    // ... more services
}
```

Benefits:
- Single source of truth for service instances
- Easy to swap implementations (e.g., for testing)
- Lazy initialization for performance

### Models

#### Vendor
Represents a provider configuration:
```swift
struct Vendor: Codable, Identifiable {
    let id: String
    let name: String
    let env: [String: String]
}
```

#### VendorTemplate
Reusable vendor configurations:
```swift
struct VendorTemplate {
    let id: String
    let name: String
    let baseURL: String?
    let requiredEnvVars: [String]
    let defaultValues: [String: String]
    
    func createVendor(with envValues: [String: String]) throws -> Vendor
}
```

Predefined templates:
- Anthropic Official
- DeepSeek
- OpenAI
- Azure OpenAI
- AnyRouter
- Custom

#### CCSConfig
Application configuration:
```swift
struct CCSConfig: Codable {
    var current: String?
    var vendors: [Vendor]
}
```

#### ClaudeSettings
Claude configuration with dynamic fields:
```swift
struct ClaudeSettings: Codable {
    var env: [String: String]?
    // Preserves arbitrary other fields
}
```

## Extension Points

### Adding a New Vendor Type

1. **Create a VendorTemplate**:
```swift
static let myVendor = VendorTemplate(
    id: "my-vendor",
    name: "My Vendor",
    baseURL: "https://api.myvendor.com",
    requiredEnvVars: ["AUTH_TOKEN"],
    defaultValues: ["BASE_URL": "https://api.myvendor.com"]
)
```

2. **Add to templates list**:
```swift
static let templates: [VendorTemplate] = [
    // existing templates...
    .myVendor
]
```

### Adding a New Storage Backend

1. **Implement ConfigurationRepository**:
```swift
class DatabaseConfigurationRepository: ConfigurationRepository {
    // Implement all protocol methods
}
```

2. **Register in ServiceContainer**:
```swift
ServiceContainer.shared.register(
    configRepository: DatabaseConfigurationRepository()
)
```

### Adding Custom Notifications

1. **Implement NotificationService**:
```swift
class SlackNotificationService: NotificationService {
    func notify(title: String, message: String) {
        // Send to Slack
    }
}
```

2. **Register in ServiceContainer**:
```swift
ServiceContainer.shared.register(
    notificationService: SlackNotificationService()
)
```

## Testing Strategy

### Unit Testing

All protocols have mock implementations in `CCSwitchTests/Mocks/`:
- `MockConfigurationRepository`
- `MockSettingsWriter`
- `MockBackupService`
- `MockNotificationService`
- `MockSettingsRepository`

Example test:
```swift
func testSwitchVendor() throws {
    let mockRepo = MockConfigurationRepository()
    let mockWriter = MockSettingsWriter()
    
    let switcher = DefaultVendorSwitcher(
        configRepository: mockRepo,
        settingsWriter: mockWriter
    )
    
    try switcher.switchToVendor(with: "test")
    
    XCTAssertEqual(mockWriter.writeCallCount, 1)
}
```

### Integration Testing

Test entire workflows with real implementations:
```swift
func testEndToEndVendorSwitch() throws {
    let tempConfig = // create temp config file
    let repo = FileConfigurationRepository(configURL: tempConfig)
    // Test full flow
}
```

## Migration Guide

### From Old Architecture to New

The refactored `ConfigManager` maintains backward compatibility while using the new architecture internally.

**Before** (tightly coupled):
```swift
ConfigManager.shared.switchToVendor(with: "vendor-id")
```

**After** (same API, better architecture):
```swift
ConfigManager.shared.switchToVendor(with: "vendor-id")
// Now uses VendorSwitcher internally
```

### Using New Architecture Directly

For new features, use services directly:
```swift
let switcher = ServiceContainer.shared.vendorSwitcher
try switcher.switchToVendor(with: "vendor-id")
```

## Best Practices

### 1. Prefer Protocols Over Concrete Types
```swift
// Good
let repository: ConfigurationRepository = FileConfigurationRepository()

// Avoid
let repository = FileConfigurationRepository()
```

### 2. Inject Dependencies
```swift
// Good
init(configRepository: ConfigurationRepository) {
    self.configRepository = configRepository
}

// Avoid
init() {
    self.configRepository = FileConfigurationRepository()
}
```

### 3. Use ServiceContainer for Production
```swift
// Production
let container = ServiceContainer.shared

// Testing
let container = ServiceContainer()
container.register(configRepository: MockConfigurationRepository())
```

### 4. Keep Services Focused
Each service should have a single, well-defined responsibility.

### 5. Handle Errors Gracefully
All protocol methods that can fail throw typed errors:
```swift
do {
    try repository.addVendor(vendor)
} catch ConfigurationError.vendorAlreadyExists {
    // Handle duplicate
} catch {
    // Handle other errors
}
```

## Future Improvements

1. **Event Bus**: Decouple components further with an event system
2. **Configuration Validation**: Schema-based validation
3. **Remote Configuration**: Support for cloud-synced configs
4. **Plugin System**: Allow third-party vendor integrations
5. **Middleware**: Add hooks for pre/post switching operations

## Summary

The refactored architecture provides:
- ✅ **Better testability** through protocol-based design
- ✅ **Improved reusability** via dependency injection
- ✅ **Lower maintenance cost** with clear separation of concerns
- ✅ **Easy extensibility** through well-defined extension points
- ✅ **Backward compatibility** with existing code
