import Foundation
import Combine
import AppKit
import UserNotifications

// MARK: - Settings View Model Protocol

/// Protocol for settings view model
/// This abstraction allows for different implementations and improves testability
@MainActor
protocol SettingsViewModelProtocol: ObservableObject {
    // MARK: - General Settings
    var showSwitchNotification: Bool { get set }
    var autoLoadConfig: Bool { get set }
    var autoBackup: Bool { get set }
    var notificationStatus: UNAuthorizationStatus { get set }

    // MARK: - Update Settings
    var automaticallyChecksForUpdates: Bool { get set }
    var automaticallyDownloadsAndInstallsUpdates: Bool { get set }
    var lastUpdateCheckDate: Date? { get }

    // MARK: - Debug Settings
    var showDebugLogs: Bool { get set }
    var confirmBackupDeletion: Bool { get set }

    // MARK: - Sync Settings
    var isSyncEnabled: Bool { get set }
    var syncStatus: SyncStatus { get }

    // MARK: - Computed Properties
    var fullVersion: String { get }
    var hasLegacyConfig: Bool { get }

    // MARK: - Actions
    func checkNotificationPermission() async
    func requestNotificationPermission() async
    func openSystemSettings()
    func openBackupFolder()
    func openConfigFolder()
    func checkForUpdates(isManual: Bool)
    func reloadConfiguration() async throws
    func resetAppState() async throws
    func toggleSync(enabled: Bool)
}

// MARK: - Default Implementation

/// Default implementation of SettingsViewModel
@MainActor
class DefaultSettingsViewModel: SettingsViewModelProtocol {
    // MARK: - Published Properties
    @Published var showSwitchNotification: Bool {
        didSet { settingsRepository.setBool(showSwitchNotification, for: .showSwitchNotification) }
    }
    @Published var autoLoadConfig: Bool {
        didSet { settingsRepository.setBool(autoLoadConfig, for: .autoLoadConfig) }
    }
    @Published var autoBackup: Bool {
        didSet { settingsRepository.setBool(autoBackup, for: .autoBackup) }
    }
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var automaticallyChecksForUpdates: Bool {
        didSet { updateManager.automaticallyChecksForUpdates = automaticallyChecksForUpdates }
    }
    @Published var automaticallyDownloadsAndInstallsUpdates: Bool {
        didSet { updateManager.automaticallyDownloadsAndInstallsUpdates = automaticallyDownloadsAndInstallsUpdates }
    }
    @Published var lastUpdateCheckDate: Date?
    @Published var showDebugLogs: Bool {
        didSet { settingsRepository.setBool(showDebugLogs, for: .showDebugLogs) }
    }
    @Published var confirmBackupDeletion: Bool {
        didSet { settingsRepository.setBool(confirmBackupDeletion, for: .confirmBackupDeletion) }
    }
    @Published var isSyncEnabled: Bool {
        didSet { if isSyncEnabled { syncManager.toggleSync(enabled: true) } else { syncManager.toggleSync(enabled: false) } }
    }

    // Computed (not published) - sync status updates via notification observer
    var syncStatus: SyncStatus {
        syncManager.syncStatus
    }

    // MARK: - Computed Properties
    var fullVersion: String {
        AppInfo.fullVersion
    }

    var hasLegacyConfig: Bool {
        configManager.hasLegacyConfig
    }

    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository
    private let configManager: ConfigManager
    private let syncManager: any SyncManagerProtocol
    private unowned(unsafe) let updateManager: UpdateManager
    private let notificationService: NotificationService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        settingsRepository: SettingsRepository,
        configManager: ConfigManager,
        syncManager: any SyncManagerProtocol,
        updateManager: UpdateManager,
        notificationService: NotificationService
    ) {
        self.settingsRepository = settingsRepository
        self.configManager = configManager
        self.syncManager = syncManager
        self.updateManager = updateManager
        self.notificationService = notificationService

        // Initialize stored properties directly
        showSwitchNotification = settingsRepository.getBool(for: .showSwitchNotification)
        autoLoadConfig = settingsRepository.getBool(for: .autoLoadConfig)
        autoBackup = settingsRepository.getBool(for: .autoBackup)
        showDebugLogs = settingsRepository.getBool(for: .showDebugLogs)
        confirmBackupDeletion = settingsRepository.getBool(for: .confirmBackupDeletion)
        automaticallyChecksForUpdates = updateManager.automaticallyChecksForUpdates
        automaticallyDownloadsAndInstallsUpdates = updateManager.automaticallyDownloadsAndInstallsUpdates
        lastUpdateCheckDate = updateManager.lastUpdateCheckDate
        isSyncEnabled = syncManager.syncConfig.isSyncEnabled

        // Subscribe to notification status changes
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.checkNotificationPermission()
                }
            }
            .store(in: &cancellables)

        // Subscribe to sync status changes
        NotificationCenter.default.publisher(for: .syncStatusChanged)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)

        // Subscribe to update manager changes
        NotificationCenter.default.publisher(for: NSNotification.Name("SPUUpdaterDidUpdateCheckingFinished"))
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.lastUpdateCheckDate = self?.updateManager.lastUpdateCheckDate
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Notification Actions
    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }

    func requestNotificationPermission() async {
        let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        await checkNotificationPermission()
        if granted == true {
            showSwitchNotification = true
        }
    }

    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Folder Actions
    func openBackupFolder() {
        let folderURL = ClaudeSettings.configDirectory
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderURL.path)
    }

    func openConfigFolder() {
        NSWorkspace.shared.selectFile(CCSConfig.configFile.path, inFileViewerRootedAtPath: "")
    }

    // MARK: - Update Actions
    func checkForUpdates(isManual: Bool) {
        updateManager.checkForUpdates(isManual: isManual)
    }

    // MARK: - Configuration Actions
    func reloadConfiguration() async throws {
        configManager.initialize()
        Logger.shared.info("Configuration reloaded")
        notificationService.notify(
            title: NSLocalizedString("reload_success_title", comment: ""),
            message: NSLocalizedString("reload_success_msg", comment: "")
        )
    }

    func resetAppState() async throws {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        configManager.cleanup()

        Logger.shared.info("Application state reset")
        notificationService.notify(
            title: NSLocalizedString("reset_success_title", comment: ""),
            message: NSLocalizedString("reset_success_msg", comment: "")
        )
    }

    // MARK: - Sync Actions
    func toggleSync(enabled: Bool) {
        syncManager.toggleSync(enabled: enabled)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let syncStatusChanged = Notification.Name("syncStatusChanged")
}
