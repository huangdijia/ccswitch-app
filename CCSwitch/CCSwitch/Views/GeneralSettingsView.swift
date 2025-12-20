import SwiftUI

struct GeneralSettingsView: View {
    @State private var showSwitchNotification = true
    @State private var autoLoadConfig = true
    @State private var autoBackup = true

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
                    subtitle: "show_notifications_desc",
                    isOn: $showSwitchNotification,
                    key: "showSwitchNotification"
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
        }
    }

    private func openFile(_ path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
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

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(DesignSystem.Fonts.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(LocalizedStringKey(subtitle))
                    .font(DesignSystem.Fonts.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
                .labelsHidden()
                .onChange(of: isOn) { newValue in
                    UserDefaults.standard.set(newValue, forKey: key)
                }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small + 2)
    }
}
