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
            Section {
                // Auto Reload Config
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("auto_reload_config")
                            .font(.body)
                        Text("auto_reload_config_desc")
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
                        Text("auto_backup")
                            .font(.body)
                        Text("auto_backup_desc_refined")
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
                        Text("show_backup_files")
                    }
                }
                .buttonStyle(.link)
                .padding(.leading, 0)
                .padding(.top, 4)

                // Legacy Migration
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("legacy_migration_title")
                            .font(.body)
                        Text("legacy_migration_desc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("migrate_now") {
                        MigrationManager.shared.checkMigration(force: true)
                    }
                    .controlSize(.small)
                    .disabled(!ConfigManager.shared.hasLegacyConfig)
                }
                .padding(.top, 8)
            } header: {
                Text("config_management")
            }

            // Section 2: Notifications
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("show_notifications")
                            .font(.body)
                        Text("show_notifications_desc")
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
                            Text("notification_permission_disabled")
                                .font(.callout)
                            Button("open_system_settings") {
                                openSystemSettings()
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                } else if notificationStatus == .notDetermined {
                    Button("allow_notifications") {
                        requestNotificationPermission()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            } header: {
                Text("notifications")
            }
            
            // Section 3: Software Update
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("auto_check_updates")
                                .font(.body)
                            Text("auto_check_updates_desc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { UpdateManager.shared.automaticallyChecksForUpdates },
                            set: { UpdateManager.shared.automaticallyChecksForUpdates = $0 }
                        ))
                        .labelsHidden()
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("auto_install_updates")
                                .font(.body)
                            Text("auto_install_updates_desc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { UpdateManager.shared.automaticallyDownloadsAndInstallsUpdates },
                            set: { UpdateManager.shared.automaticallyDownloadsAndInstallsUpdates = $0 }
                        ))
                        .labelsHidden()
                    }
                    
                    Divider().padding(.vertical, 4)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                updateManager.checkForUpdates(isManual: true)
                            } label: {
                                if updateManager.isChecking {
                                    HStack(spacing: 4) {
                                        ProgressView().controlSize(.small)
                                        Text("check_for_updates_now")
                                    }
                                } else {
                                    Text("check_for_updates_now")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(updateManager.isChecking || updateManager.isDownloading)
                            
                            if let lastDate = updateManager.lastUpdateCheckDate {
                                Text(String(format: NSLocalizedString("last_checked_format", comment: ""), lastDate.formatted()))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(NSLocalizedString("version_info", comment: "")) \(AppInfo.fullVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if updateManager.isDownloading {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(updateManager.installationStatus ?? "")
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(updateManager.downloadProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            ProgressView(value: updateManager.downloadProgress)
                                .progressViewStyle(.linear)
                                .controlSize(.small)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("software_update")
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
        let folderURL = CCSConfig.configDirectory
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderURL.path)
    }
}
