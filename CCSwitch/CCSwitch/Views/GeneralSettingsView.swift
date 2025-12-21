import SwiftUI
import UserNotifications

struct GeneralSettingsView: View {
    @AppStorage("showSwitchNotification") private var showSwitchNotification = true
    @AppStorage("autoLoadConfig") private var autoLoadConfig = true
    @AppStorage("autoBackup") private var autoBackup = true
    
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("notifications")
                        .font(.headline)
                    
                    HStack {
                        Toggle("show_notifications", isOn: $showSwitchNotification)
                            .disabled(notificationStatus == .denied)
                        
                        if notificationStatus == .denied {
                            Button("open_system_settings") {
                                openSystemSettings()
                            }
                            .font(.caption)
                        } else if notificationStatus == .notDetermined {
                             Button("allow_notifications") {
                                 requestNotificationPermission()
                             }
                             .font(.caption)
                        }
                    }
                    
                    Text("show_notifications_desc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                Divider()
                    .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 12) {
                    Text("startup_backup")
                        .font(.headline)
                    
                    Toggle("auto_load_config", isOn: $autoLoadConfig)
                    Text("auto_load_config_desc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                        
                    Toggle("auto_backup", isOn: $autoBackup)
                    Text("auto_backup_desc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
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
}
