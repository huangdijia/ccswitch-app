# CCSwitch for macOS

[![GitHub Release](https://img.shields.io/github/v/release/huangdijia/ccswitch-app)](https://github.com/huangdijia/ccswitch-app/releases)
[![GitHub Downloads](https://img.shields.io/github/downloads/huangdijia/ccswitch-app/total)](https://github.com/huangdijia/ccswitch-app/releases)
[![GitHub License](https://img.shields.io/github/license/huangdijia/ccswitch-app)](LICENSE)

A macOS menu bar tool for quickly switching Claude Code providers.

[简体中文](README_CN.md)

![CCSwitch Screenshot](Screenshots/01.jpg)

## Features

### ✅ Implemented Features

1. **Menu Bar Integration**
   - macOS menu bar icon display
   - Current provider abbreviation display (optional)
   - Tooltip showing current provider information

2. **Provider Switching**
   - One-click Claude Code provider switching
   - Support for multiple provider configurations
   - Current provider indicator (✓)
   - Preset provider templates (Anthropic, DeepSeek, OpenAI, etc.)

3. **Configuration Management**
   - Automatic read/write of `~/.claude/settings.json`
   - Centralized provider configuration management (`~/.ccswitch/vendors.json`)
   - Automatic configuration backup mechanism
   - Configuration template reuse support

4. **Settings Interface**
   - General: General settings, path display, notification permission management, software updates 🆕
   - Provider Management: Add/edit/delete providers, import from old configurations
   - Advanced: Backup management, advanced operations

5. **Security Features**
   - Automatic backup before switching
   - Configuration file corruption protection
   - Permission checks and error handling

6. **User Experience**
   - Menu bar synchronized switching
   - Switch success notifications (requires notification permission)
   - Notification permission detection and guidance
   - Detailed error messages
   - Logging and issue reporting
   - Multi-language support (Simplified Chinese, Traditional Chinese, English)

7. **Architecture Optimization** 🆕
   - Protocol-Oriented Architecture
   - Dependency injection pattern for improved testability
   - Clear separation of concerns
   - Easy-to-extend modular design

8. **Auto Update** 🆕
   - Automatic update checking based on GitHub Releases
   - Automatic download and install update options
   - Manual check for updates functionality
   - Update progress display

## Installation and Usage

### Download and Install

1. Download the latest `CCSwitch.dmg` from GitHub Releases.
2. Drag `CCSwitch.app` into the `Applications` folder.
3. **Important**: Since the app is not signed with an Apple Developer certificate, you need to run the following command in Terminal after first installation to resolve the "app is damaged" or "unable to verify developer" issue:

   ```bash
   xattr -rd com.apple.quarantine /Applications/CCSwitch.app/
   ```

### Build from Source (For Development)

#### Build Requirements

- macOS 14.6+
- Xcode 15.0+
- Swift 5.9+

### Build Steps

1. Clone the project:

```bash
git clone https://github.com/huangdijia/ccswitch-app.git
cd ccswitch-app
```

2. Run build script (multiple options):

Using Makefile (recommended):

```bash
make build      # Full build (requires Xcode)
make fast-build # Fast build (only requires Swift command line tools)
make run        # Build and run
make test       # Run unit tests (requires Xcode)
```

Or use shell script:

```bash
./build.sh
```

#### Development Build and Debug

The project provides several helper scripts for development:

- **compile_swift.sh** - Compile directly with Swift compiler (no Xcode required)
- **run_dev.sh** - Run in development mode (automatically removes security restrictions)
- **test_app.sh** - Test basic app functionality
- **fix_and_run.sh** - Fix and run the app (for first run)

Quick development run:

```bash
./run_dev.sh
```

### Configure Providers

1. Click the CCSwitch icon in the menu bar
2. Select "Settings..."
3. Add, edit, or import providers in the "Provider Management" tab

### Switch Providers

1. Click the menu bar icon
2. Select the provider you want to switch to, or toggle the switch in the provider list in the settings interface
3. Configuration will be updated automatically

## Configuration File Format

### CCSwitch Configuration (~/.ccswitch/vendors.json)

```json
{
  "version": 1,
  "current": "anthropic",
  "vendors": [
    {
      "id": "default",
      "displayName": "Default",
      "claudeSettingsPatch": {}
    },
    {
      "id": "deepseek",
      "displayName": "DeepSeek",
      "claudeSettingsPatch": {
        "ANTHROPIC_AUTH_TOKEN": "sk-xxxxxx",
        "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
        "ANTHROPIC_MODEL": "deepseek-chat",
        "ANTHROPIC_SMALL_FAST_MODEL": "deepseek-chat"
      }
    }
  ]
}
```

> **Note**: Configuration file path is `~/.ccswitch/vendors.json`, refer to example file `CCSwitch/vendors.json.example`

### Claude Configuration (~/.claude/settings.json)

The app will automatically update the `env` field of this file while preserving other existing fields.

## Project Structure

```
ccswitch-app/
├── build.sh                          # Main build script
├── compile_swift.sh                  # Swift compilation script
├── run_dev.sh                        # Development run script
├── test_app.sh                       # Application test script
├── fix_and_run.sh                    # Fix and run script
├── Makefile                          # Make build system 🆕
├── README.md                         # Project documentation
├── README_CN.md                      # Chinese documentation
├── README_XCODE.md                   # Xcode usage guide
├── ARCHITECTURE.md                   # Architecture documentation 🆕
├── EXTENSION_GUIDE.md                # Extension guide 🆕
├── CONTRIBUTING.md                   # Contributing guide 🆕
├── BUILD_REQUIREMENTS.md             # Build requirements documentation 🆕
└── CCSwitch/
    ├── CCSwitch.xcodeproj            # Xcode project file
    ├── CCSwitch.xcworkspace          # Xcode workspace
    ├── vendors.json.example         # Configuration file example
    ├── CCSwitch/
    │   ├── App/
    │   │   ├── CCSwitchApp.swift        # App entry point
    │   │   ├── MenuBarController.swift  # Menu bar controller
    │   │   └── AppInfo.swift            # App version information 🆕
    │   ├── Models/
    │   │   ├── Vendor.swift             # Provider model
    │   │   ├── VendorTemplate.swift     # Provider template 🆕
    │   │   ├── CCSConfig.swift          # CCSwitch configuration
    │   │   └── ClaudeSettings.swift     # Claude configuration model
    │   ├── Protocols/                   # Protocol definitions 🆕
    │   │   ├── VendorSwitcher.swift        # Provider switching protocol
    │   │   ├── ConfigurationRepository.swift # Configuration repository protocol
    │   │   ├── SettingsWriter.swift        # Settings writer protocol
    │   │   ├── BackupService.swift         # Backup service protocol
    │   │   ├── NotificationService.swift   # Notification service protocol
    │   │   └── SettingsRepository.swift    # Settings repository protocol
    │   ├── Services/
    │   │   ├── ConfigManager.swift      # Configuration management service (refactored)
    │   │   ├── ServiceContainer.swift   # Dependency injection container 🆕
    │   │   ├── UpdateManager.swift      # Auto update manager 🆕
    │   │   ├── BackupManager.swift      # Backup management
    │   │   ├── Logger.swift            # Logging system
    │   │   └── ErrorHandler.swift      # Error handling
    │   ├── Views/
    │   │   ├── SettingsView.swift       # Settings window main view
    │   │   ├── GeneralSettingsView.swift    # General settings (with notification permissions)
    │   │   ├── VendorManagementView.swift   # Provider management
    │   │   ├── VendorEditView.swift         # Provider editing
    │   │   └── AdvancedSettingsView.swift   # Advanced settings
    │   └── Resources/
    │       ├── Info.plist
    │       ├── AppIcon.icns
    │       ├── en.lproj/                # English localization
    │       ├── zh-Hans.lproj/           # Simplified Chinese localization
    │       └── zh-Hant.lproj/           # Traditional Chinese localization
    └── CCSwitchTests/
        ├── ConfigManagerTests.swift     # Configuration management tests 🆕
        ├── ModelTests.swift             # Model tests 🆕
        └── Mocks/                       # Mock objects 🆕
            ├── MockConfigurationRepository.swift
            └── MockServices.swift
```

## Testing

Run unit tests:

Using Makefile:

```bash
make test       # Run unit tests (requires Xcode)
make test-app   # Run manual test script
```

Or using command line:

```bash
cd CCSwitch
xcodebuild test -project CCSwitch.xcodeproj -scheme CCSwitch -destination 'platform=macOS'
```

Or using test script:

```bash
./test_app.sh
```

## Architecture

CCSwitch uses **Protocol-Oriented Architecture** with **Dependency Injection** pattern:

- ✅ **High Testability**: All core components have protocol definitions and Mock implementations
- ✅ **High Reusability**: Component reuse through protocol abstraction and dependency injection
- ✅ **Low Coupling**: Clear separation of concerns, well-defined responsibilities for each layer
- ✅ **Easy Extension**: Add new providers, storage backends, notification channels without modifying core code

For detailed architecture documentation, please refer to:

- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture design details
- [EXTENSION_GUIDE.md](EXTENSION_GUIDE.md) - Extension development guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contributing guide

## Contributing

Issues and Pull Requests are welcome!

Before contributing, please read:

- [CONTRIBUTING.md](CONTRIBUTING.md) - Contributing guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - Understand project architecture
- [EXTENSION_GUIDE.md](EXTENSION_GUIDE.md) - Learn how to extend features

## License

MIT License

## Changelog

### v0.1.7 (2025-12-21)

- ✨ Added auto-update feature (based on GitHub Releases)
- ✨ Added software update settings interface
- ✨ Added AppInfo utility class for version information
- 🔧 Added Makefile support for multiple build methods
- 🔧 Improved localization strings
- 📝 Updated documentation and architecture description
- 🎉 Initial release
- 🎯 Implemented all core features
- ✅ Support for provider switching and configuration management
- ✅ Support for notification permission detection and guidance
- ✅ Multi-language support (Simplified Chinese, Traditional Chinese, English)
- 🛠️ Provided multiple development helper scripts
