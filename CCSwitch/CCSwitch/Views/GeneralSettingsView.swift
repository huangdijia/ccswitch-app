import SwiftUI
import UserNotifications

struct GeneralSettingsView: View {
    @AppStorage("showSwitchNotification") private var showSwitchNotification = true
    @AppStorage("autoLoadConfig") private var autoLoadConfig = true
    @AppStorage("autoBackup") private var autoBackup = true

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @ObservedObject private var updateManager = UpdateManager.shared

    var body: some View {
        Form {
            // Section 1: Configuration Management
            Section(header: Text(LocalizedStringKey(LocalizationKey.configManagement))) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    // Auto Reload Config
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(LocalizationKey.autoReloadConfig))
                                .font(.body)
                            Text(LocalizedStringKey(LocalizationKey.autoReloadConfigDesc))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $autoLoadConfig)
                            .labelsHidden()
                    }

                    // Auto Backup
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(LocalizationKey.autoBackup))
                                .font(.body)
                            Text(LocalizedStringKey(LocalizationKey.autoBackupDescRefined))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $autoBackup)
                            .labelsHidden()
                    }

                    Button {
                        openBackupFolder()
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            Text(LocalizedStringKey(LocalizationKey.showBackupFiles))
                        }
                    }
                    .buttonStyle(.link)

                    if ConfigManager.shared.hasLegacyConfig {
                        // Legacy Migration
                        VStack(spacing: 0) {
                            Divider().padding(.vertical, 8)
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizedStringKey(LocalizationKey.legacyMigrationTitle))
                                        .font(.body)
                                    Text(LocalizedStringKey(LocalizationKey.legacyMigrationDesc))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(LocalizedStringKey(LocalizationKey.migrateNow)) {
                                    // 在 MainActor 环境下触发
                                    Task { @MainActor in
                                        MigrationManager.shared.checkMigration(force: true)
                                    }
                                }
                                .controlSize(.small)
                            }
                        }
                    }
                }
            }

            // Section 2: Notifications
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(LocalizationKey.showNotifications))
                            .font(.body)
                        Text(LocalizedStringKey(LocalizationKey.showNotificationsDesc))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $showSwitchNotification)
                        .labelsHidden()
                        .disabled(notificationStatus == .denied)
                }

                if notificationStatus == .denied {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(LocalizationKey.notificationPermissionDisabled))
                                .font(.callout)
                            Button(LocalizedStringKey(LocalizationKey.openSystemSettings)) {
                                openSystemSettings()
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                } else if notificationStatus == .notDetermined {
                    Button(LocalizedStringKey(LocalizationKey.allowNotifications)) {
                        requestNotificationPermission()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            } header: {
                Text(LocalizedStringKey(LocalizationKey.notifications))
            }

            // Section 3: Software Update
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(LocalizationKey.autoCheckUpdates))
                                .font(.body)
                            Text(LocalizedStringKey(LocalizationKey.autoCheckUpdatesDesc))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $updateManager.automaticallyChecksForUpdates)
                        .labelsHidden()
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(LocalizationKey.autoInstallUpdates))
                                .font(.body)
                            Text(LocalizedStringKey(LocalizationKey.autoInstallUpdatesDesc))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $updateManager.automaticallyDownloadsAndInstallsUpdates)
                        .labelsHidden()
                    }

                    Divider().padding(.vertical, 4)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                updateManager.checkForUpdates(isManual: true)
                            } label: {
                                Text(LocalizedStringKey(LocalizationKey.checkForUpdatesNow))
                            }
                            .buttonStyle(.bordered)

                            if let lastDate = updateManager.lastUpdateCheckDate {
                                Text(LocalizationKey.localized(LocalizationKey.lastCheckedFormat, lastDate.formatted()))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Text("\(LocalizationKey.localized(LocalizationKey.versionInfo)) \(AppInfo.fullVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text(LocalizedStringKey(LocalizationKey.softwareUpdate))
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            checkNotificationPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkNotificationPermission()
        }
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            checkNotificationPermission()
            if granted {
                DispatchQueue.main.async {
                    showSwitchNotification = true
                }
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openBackupFolder() {
        let folderURL = ClaudeSettings.configDirectory
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderURL.path)
    }
}
