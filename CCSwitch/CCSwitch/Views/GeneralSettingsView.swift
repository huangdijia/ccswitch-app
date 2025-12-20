import SwiftUI
import UserNotifications

struct GeneralSettingsView: View {
    @State private var showSwitchNotification = true
    @State private var autoLoadConfig = true
    @State private var autoBackup = true
    @State private var hasNotificationPermission = false

    private let currentVendor = ConfigManager.shared.currentVendor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ModernSection(title: "current_status") {
                ModernRow(
                    icon: "checkmark.circle.fill",
                    iconColor: DesignSystem.Colors.success,
                    title: "current_vendor",
                    value: currentVendor?.displayName ?? NSLocalizedString("unknown", comment: "")
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
                    subtitle: hasNotificationPermission ? "show_notifications_desc" : "notifications_disabled_hint",
                    isOn: Binding(
                        get: { hasNotificationPermission ? showSwitchNotification : false },
                        set: { showSwitchNotification = $0 }
                    ),
                    key: "showSwitchNotification",
                    isDisabled: !hasNotificationPermission,
                    subtitleAction: hasNotificationPermission ? nil : {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
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
        }
    }

    private func openFile(_ path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasNotificationPermission = (settings.authorizationStatus == .authorized)
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
                    Button(action: action) {
                        Text(LocalizedStringKey(subtitle))
                            .font(DesignSystem.Fonts.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
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
                .onChange(of: isOn) { newValue in
                    UserDefaults.standard.set(newValue, forKey: key)
                }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small + 2)
    }
}
