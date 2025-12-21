import SwiftUI
import UserNotifications

struct GeneralSettingsView: View {
    @AppStorage("showSwitchNotification") private var showSwitchNotification = true
    @AppStorage("autoLoadConfig") private var autoLoadConfig = true
    @AppStorage("autoBackup") private var autoBackup = true
    
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

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
                .padding(.leading, 0) // Align with text, no extra indent needed in Form usually, or minimal
                .padding(.top, 4)
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
