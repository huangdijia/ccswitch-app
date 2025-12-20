import SwiftUI
import UserNotifications

struct GeneralSettingsView: View {
    @State private var showSwitchNotification = true
    @State private var autoLoadConfig = true
    @State private var autoBackup = true
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var currentVendor: Vendor? = ConfigManager.shared.currentVendor

    private var hasNotificationPermission: Bool {
        notificationStatus == .authorized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ModernSection(title: "current_status") {
                ModernRow(
                    icon: "checkmark.circle.fill",
                    iconColor: DesignSystem.Colors.success,
                    title: "current_vendor",
                    value: currentVendor?.name ?? NSLocalizedString("unknown", comment: "")
                )
                ModernDivider()
                ModernRow(
                    icon: "doc.text.fill",
                    iconColor: .blue,
                    title: "claude_config",
                    subtitle: ClaudeSettings.configFile.path,
                    showChevron: true,
                    action: { openFile(ClaudeSettings.configFile.path) }
                )
                ModernDivider()
                ModernRow(
                    icon: "gearshape.fill",
                    iconColor: .gray,
                    title: "vendor_config",
                    subtitle: CCSConfig.configFile.path,
                    showChevron: true,
                    action: { openFile(CCSConfig.configFile.path) }
                )
            }

            ModernSection(title: "notifications") {
                ToggleRow(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "show_notifications",
                    subtitle: subtitleForKey,
                    isOn: Binding(
                        get: { hasNotificationPermission ? showSwitchNotification : false },
                        set: { showSwitchNotification = $0 }
                    ),
                    key: "showSwitchNotification",
                    isDisabled: !hasNotificationPermission,
                    subtitleAction: hasNotificationPermission ? nil : {
                        handleNotificationAction()
                    }
                )
            }

            ModernSection(title: "startup_backup") {
                ToggleRow(
                    icon: "arrow.clockwise.circle.fill",
                    iconColor: .purple,
                    title: "auto_load_config",
                    subtitle: "auto_load_config_desc",
                    isOn: $autoLoadConfig,
                    key: "autoLoadConfig"
                )
                ModernDivider()
                ToggleRow(
                    icon: "shield.fill",
                    iconColor: .green,
                    title: "auto_backup",
                    subtitle: "auto_backup_desc",
                    isOn: $autoBackup,
                    key: "autoBackup"
                )
            }
        }
        .onAppear {
            loadSettings()
            checkNotificationPermission()
            currentVendor = ConfigManager.shared.currentVendor
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkNotificationPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: .configDidChange)) { _ in
            currentVendor = ConfigManager.shared.currentVendor
        }
    }

    private var subtitleForKey: String {
        switch notificationStatus {
        case .authorized: return "show_notifications_desc"
        case .notDetermined: return "notifications_not_determined_hint"
        default: return "notifications_disabled_hint"
        }
    }

    private func handleNotificationAction() {
        print("DEBUG: handleNotificationAction - status: \(notificationStatus.rawValue)")
        
        if notificationStatus == .notDetermined {
            print("DEBUG: Status is .notDetermined, requesting authorization...")
            DispatchQueue.main.async {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    print("DEBUG: Request result - granted: \(granted), error: \(String(describing: error))")
                    self.checkNotificationPermission()
                }
            }
        } else {
            print("DEBUG: Status is \(notificationStatus.rawValue), opening settings...")
            let urls = [
                "x-apple.systempreferences:com.apple.NotificationsSettingsExtension",
                "x-apple.systempreferences:com.apple.preference.notifications"
            ]
            
            for urlString in urls {
                if let url = URL(string: urlString) {
                    if NSWorkspace.shared.open(url) {
                        print("DEBUG: Successfully opened \(urlString)")
                        return
                    }
                }
            }
        }
    }

    private func openFile(_ path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("DEBUG: getNotificationSettings: \(settings.authorizationStatus.rawValue)")
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func loadSettings() {
        showSwitchNotification = UserDefaults.standard.bool(forKey: "showSwitchNotification")
        autoLoadConfig = UserDefaults.standard.bool(forKey: "autoLoadConfig")
        autoBackup = UserDefaults.standard.bool(forKey: "autoBackup")
        
        // Set defaults if not present
        if UserDefaults.standard.object(forKey: "showSwitchNotification") == nil {
            showSwitchNotification = true
            UserDefaults.standard.set(true, forKey: "showSwitchNotification")
        }
        if UserDefaults.standard.object(forKey: "autoLoadConfig") == nil {
            autoLoadConfig = true
            UserDefaults.standard.set(true, forKey: "autoLoadConfig")
        }
        if UserDefaults.standard.object(forKey: "autoBackup") == nil {
            autoBackup = true
            UserDefaults.standard.set(true, forKey: "autoBackup")
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let key: String
    var isDisabled: Bool = false
    var subtitleAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(isDisabled ? 0.05 : 0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .foregroundColor(isDisabled ? .gray.opacity(0.5) : iconColor)
                    .font(.system(size: 14, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(DesignSystem.Fonts.body)
                    .foregroundColor(isDisabled ? DesignSystem.Colors.textPrimary.opacity(0.5) : DesignSystem.Colors.textPrimary)
                
                if let action = subtitleAction {
                    Button(action: {
                        print("DEBUG: Subtitle button clicked")
                        action()
                    }) {
                        Text(LocalizedStringKey(subtitle))
                            .font(DesignSystem.Fonts.caption)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
                    }
                } else {
                    Text(LocalizedStringKey(subtitle))
                        .font(DesignSystem.Fonts.caption)
                        .foregroundColor(isDisabled ? DesignSystem.Colors.textSecondary.opacity(0.5) : DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
                .labelsHidden()
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.5 : 1.0)
                .onChange(of: isOn) { oldValue, newValue in
                    UserDefaults.standard.set(newValue, forKey: key)
                }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small + 2)
    }
}
