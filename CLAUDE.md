# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CCSwitch is a macOS menu bar utility for switching between Claude Code AI providers (Anthropic, DeepSeek, OpenAI, Azure OpenAI, etc.). It uses **Protocol-Oriented Architecture** with **Dependency Injection** for high testability and maintainability.

## Build Commands

```bash
# Build (requires Xcode for full features)
make build       # Full Xcode build
make fast-build  # Quick build with swiftc only (no Xcode needed)
make run         # Build and run

# Testing
make test        # Unit tests (requires Xcode)
make test-app    # Manual functional tests

# Cleanup
make clean       # Remove build artifacts
```

**Xcode vs Command Line Tools**: Full Xcode is required for `make build` and `make test`. For development without Xcode, use `make fast-build` and `make run`. See BUILD_REQUIREMENTS.md for details.

## Architecture

### Layer Structure

```
Views (SwiftUI)
       ↓
ConfigManager (Facade)
       ↓
ServiceContainer (DI)
       ↓
Protocols (VendorSwitcher, ConfigRepository, etc.)
       ↓
Models & Storage
```

### Key Protocols

All major components are protocol-defined for testability:

- **VendorSwitcher** - Orchestrates vendor switching operations
- **ConfigurationRepository** - Manages `~/.ccswitch/vendors.json` persistence
- **SettingsWriter** - Writes to `~/.claude/settings.json`
- **BackupService** - Backup/restore with rotation (keeps 10)
- **NotificationService** - User notifications via UserNotifications framework
- **SettingsRepository** - UserDefaults-based preferences
- **CloudStorageService** - iCloud sync via NSUbiquitousKeyValueStore

### Service Container

`ServiceContainer.shared` manages all service instances via lazy initialization. Services are injected, not created inline. For testing, swap with mock implementations from `CCSwitchTests/Mocks/`.

### Models

- **Vendor** - Provider configuration (id, displayName, claudeSettingsPatch)
- **VendorTemplate** - Predefined templates (anthropicOfficial, deepseek, openai, azureOpenAI, anyRouter, custom)
- **CCSConfig** - App config (version, current, vendors[])
- **ClaudeSettings** - Claude settings with dynamic env field

### Configuration Files

- **CCSwitch**: `~/.ccswitch/vendors.json` - Stores provider configurations
- **Claude**: `~/.claude/settings.json` - Modified when switching providers (preserves non-env fields)

## iCloud Sync

Bidirectional sync across Macs using `NSUbiquitousKeyValueStore`:

- Automatic 2-second debounce on uploads
- Conflict resolution UI when local and remote both change
- Network awareness with offline/online detection
- Exponential backoff retry (up to 3 attempts)
- Sync states: Idle, Syncing, Synced, Offline, Error

## Important Patterns

### Dependency Injection

```swift
// Good - protocol type with injected dependency
let switcher: VendorSwitcher = DefaultVendorSwitcher(
    configRepository: mockRepo,
    settingsWriter: mockWriter
)

// Avoid - concrete type, creates own dependencies
let switcher = DefaultVendorSwitcher()
```

### Service Registration

```swift
// Production
ServiceContainer.shared.vendorSwitcher

// Testing
ServiceContainer.shared.register(
    vendorSwitcher: MockVendorSwitcher()
)
```

## Extension Points

Adding new features requires implementing protocols and registering in ServiceContainer:

- **New Vendor Template**: Add static property to `VendorTemplate`, include in `templates` array
- **New Storage Backend**: Implement `ConfigurationRepository`
- **New Notification Channel**: Implement `NotificationService`, use `CompositeNotificationService` for multi-channel
- **New Settings Storage**: Implement `SettingsRepository`

See EXTENSION_GUIDE.md for detailed examples.

## Project Structure

```
CCSwitch/
├── CCSwitch/
│   ├── App/              # CCSwitchApp, MenuBarController
│   ├── Models/           # Vendor, CCSConfig, ClaudeSettings, VendorTemplate
│   ├── Protocols/        # All protocol definitions
│   ├── Services/         # ConfigManager, ServiceContainer, SyncManager, etc.
│   ├── Views/            # SwiftUI views
│   └── Resources/        # Assets, localization (en, zh-Hans, zh-Hant)
└── CCSwitchTests/        # Unit tests + Mocks/
```

## Localization

Supports English, Simplified Chinese, Traditional Chinese. Strings in `Resources/{lang}.lproj/`. Use `NSLocalizedString` throughout.

## App Security

- **LSUIElement = true** - Menu bar app (no dock icon)
- After first install, run: `xattr -rd com.apple.quarantine /Applications/CCSwitch.app/`
