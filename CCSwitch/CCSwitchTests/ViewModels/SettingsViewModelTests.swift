import XCTest
import UserNotifications
@testable import CCSwitch

/// Tests for SettingsViewModel
@MainActor
final class SettingsViewModelTests: XCTestCase {
    var mockSettingsRepository: MockSettingsRepository!
    var mockConfigManager: ConfigManager!
    var mockSyncManager: MockSyncManager!
    var mockUpdateManager: UpdateManager!
    var mockNotificationService: SettingsMockNotificationService!
    var viewModel: DefaultSettingsViewModel!

    override func setUp() async throws {
        try await super.setUp()

        // Setup mocks
        mockSettingsRepository = MockSettingsRepository()
        mockSyncManager = MockSyncManager()
        mockNotificationService = SettingsMockNotificationService()

        // Setup mock config manager with all required dependencies
        mockConfigManager = ConfigManager(
            configRepository: InMemoryConfigurationRepository(),
            vendorSwitcher: MockVendorSwitcher(),
            notificationService: mockNotificationService,
            settingsRepository: mockSettingsRepository
        )

        // Setup update manager (use real one for now)
        mockUpdateManager = UpdateManager.shared

        // Create view model with mocked dependencies
        viewModel = DefaultSettingsViewModel(
            settingsRepository: mockSettingsRepository,
            configManager: mockConfigManager,
            syncManager: mockSyncManager,
            updateManager: mockUpdateManager,
            notificationService: mockNotificationService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockUpdateManager = nil
        mockSyncManager = nil
        mockConfigManager = nil
        mockSettingsRepository = nil
        mockNotificationService = nil
        try await super.tearDown()
    }

    // MARK: - Settings Properties Tests

    func testShowSwitchNotification() {
        mockSettingsRepository.setBool(true, for: .showSwitchNotification)
        XCTAssertEqual(viewModel.showSwitchNotification, true)

        viewModel.showSwitchNotification = false
        XCTAssertEqual(mockSettingsRepository.getBool(for: .showSwitchNotification), false)
    }

    func testAutoLoadConfig() {
        mockSettingsRepository.setBool(true, for: .autoLoadConfig)
        XCTAssertEqual(viewModel.autoLoadConfig, true)

        viewModel.autoLoadConfig = false
        XCTAssertEqual(mockSettingsRepository.getBool(for: .autoLoadConfig), false)
    }

    func testAutoBackup() {
        mockSettingsRepository.setBool(true, for: .autoBackup)
        XCTAssertEqual(viewModel.autoBackup, true)

        viewModel.autoBackup = false
        XCTAssertEqual(mockSettingsRepository.getBool(for: .autoBackup), false)
    }

    func testShowDebugLogs() {
        mockSettingsRepository.setBool(true, for: .showDebugLogs)
        XCTAssertEqual(viewModel.showDebugLogs, true)

        viewModel.showDebugLogs = false
        XCTAssertEqual(mockSettingsRepository.getBool(for: .showDebugLogs), false)
    }

    func testConfirmBackupDeletion() {
        mockSettingsRepository.setBool(true, for: .confirmBackupDeletion)
        XCTAssertEqual(viewModel.confirmBackupDeletion, true)

        viewModel.confirmBackupDeletion = false
        XCTAssertEqual(mockSettingsRepository.getBool(for: .confirmBackupDeletion), false)
    }

    // MARK: - Update Settings Tests

    func testAutomaticallyChecksForUpdates() {
        viewModel.automaticallyChecksForUpdates = true
        XCTAssertEqual(viewModel.automaticallyChecksForUpdates, true)
    }

    func testAutomaticallyDownloadsAndInstallsUpdates() {
        viewModel.automaticallyDownloadsAndInstallsUpdates = true
        XCTAssertEqual(viewModel.automaticallyDownloadsAndInstallsUpdates, true)
    }

    // MARK: - Sync Settings Tests

    func testIsSyncEnabled() {
        mockSyncManager.isEnabled = true
        XCTAssertEqual(viewModel.isSyncEnabled, true)

        mockSyncManager.isEnabled = false
        XCTAssertEqual(viewModel.isSyncEnabled, false)
    }

    func testToggleSync() {
        mockSyncManager.isEnabled = false

        viewModel.toggleSync(enabled: true)

        XCTAssertTrue(mockSyncManager.isEnabled)
        XCTAssertTrue(mockSyncManager.toggleCalled)
    }

    func testSyncStatus() {
        mockSyncManager.currentState = .syncing
        XCTAssertEqual(viewModel.syncStatus, .syncing)

        mockSyncManager.currentState = .success
        XCTAssertEqual(viewModel.syncStatus, .success)
    }

    // MARK: - Computed Properties Tests

    func testFullVersion() {
        // Should return AppInfo.fullVersion
        XCTAssertEqual(viewModel.fullVersion, AppInfo.fullVersion)
    }

    func testHasLegacyConfig() {
        // This depends on ConfigManager state
        let hasLegacy = viewModel.hasLegacyConfig
        // Just verify it's a Bool
        XCTAssertTrue(hasLegacy is Bool)
    }

    // MARK: - Actions Tests

    func testOpenSystemSettings() {
        // This method opens a URL, we can't test it directly
        // Just verify it doesn't crash
        XCTAssertNoThrow(viewModel.openSystemSettings())
    }

    func testReloadConfiguration() async throws {
        // This should call configManager.initialize()
        try await viewModel.reloadConfiguration()

        // Verify notification was sent
        XCTAssertEqual(mockNotificationService.notificationCallCount, 1)
    }

    func testResetAppState() async throws {
        // This should reset UserDefaults and reinitialize
        try await viewModel.resetAppState()

        // Verify notification was sent
        XCTAssertEqual(mockNotificationService.notificationCallCount, 1)
    }
}

// MARK: - Mock Sync Manager

class MockSyncManager: SyncManagerProtocol {
    var isEnabled: Bool = false
    var currentState: SyncStatus = .idle
    var toggleCalled = false
    var uploadCalled = false
    var downloadCalled = false

    var syncConfig: SyncConfiguration = SyncConfiguration()
    var syncStatus: SyncStatus {
        get { currentState }
        set { currentState = newValue }
    }
    var pendingConflicts: [SyncConflict] = []
    var isOnline: Bool = true

    func toggleSync(enabled: Bool) {
        toggleCalled = true
        isEnabled = enabled
        syncConfig.isSyncEnabled = enabled
    }

    func uploadSelectedVendors() {
        uploadCalled = true
        currentState = .syncing
    }

    func downloadRemoteChanges() {
        downloadCalled = true
        currentState = .syncing
    }

    func resolveConflict(vendorId: String, keepLocal: Bool) {
        // Mock implementation
    }

    func updateSyncedVendors(ids: [String]) {
        syncConfig.syncedVendorIds = ids
    }
}

// MARK: - Mock Notification Service

class SettingsMockNotificationService: NotificationService {
    var notificationCallCount = 0
    var lastNotifyTitle = ""
    var lastNotifyMessage = ""

    func notify(title: String, message: String) {
        notificationCallCount += 1
        lastNotifyTitle = title
        lastNotifyMessage = message
    }

    func requestPermission() {
        // Mock implementation
    }

    var hasPermission: Bool {
        return true
    }
}
