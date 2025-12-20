import SwiftUI

struct GeneralSettingsView: View {
    @State private var showSwitchNotification = true
    @State private var autoLoadConfig = true
    @State private var autoBackup = true

    private let currentVendor = ConfigManager.shared.currentVendor

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            // Current Status
            SettingsCard(
                title: "Current Status",
                icon: "info.circle.fill",
                iconColor: .blue
            ) {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    StatusCard(
                        icon: "checkmark.circle.fill",
                        iconColor: DesignSystem.Colors.success,
                        title: "Current Vendor",
                        value: currentVendor?.displayName ?? "Unknown"
                    )

                    PathButton(
                        icon: "folder.fill",
                        title: "Claude Config",
                        path: ClaudeSettings.configFile.path
                    )

                    PathButton(
                        icon: "folder.fill",
                        title: "Vendor Config",
                        path: CCSConfig.configFile.path
                    )
                }
            }

            // Notification Settings
            SettingsCard(
                title: "Notifications",
                icon: "bell.fill",
                iconColor: .orange
            ) {
                ToggleCard(
                    title: "Show Notifications",
                    subtitle: "Show system notification after switching vendor",
                    isOn: $showSwitchNotification,
                    key: "showSwitchNotification"
                )
            }

            // Startup Settings
            SettingsCard(
                title: "Startup & Backup",
                icon: "gear.badge.checkmark",
                iconColor: .purple
            ) {
                VStack(spacing: 0) {
                    ToggleCard(
                        title: "Auto Load Config",
                        subtitle: "Automatically load configuration on app startup",
                        isOn: $autoLoadConfig,
                        key: "autoLoadConfig"
                    )
                    
                    Divider().padding(.vertical, 8)

                    ToggleCard(
                        title: "Auto Backup",
                        subtitle: "Backup current config before switching",
                        isOn: $autoBackup,
                        key: "autoBackup"
                    )
                }
            }
        }
        .onAppear {
            loadSettings()
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

// MARK: - Settings Card Container
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18, weight: .semibold))

                Text(title)
                    .font(DesignSystem.Fonts.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Spacer()
            }

            content()
        }
        .modernCardStyle()
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Fonts.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Text(value)
                    .font(DesignSystem.Fonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.small)
        .background(Color.clear) // cleaner look without inner background
    }
}

// MARK: - Path Button
struct PathButton: View {
    let icon: String
    let title: String
    let path: String
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .medium))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Fonts.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text(path)
                        .font(DesignSystem.Fonts.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(isHovered ? .blue : .gray.opacity(0.5))
                    .font(.system(size: 16))
            }
            .padding(DesignSystem.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(isHovered ? Color.gray.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hover
            }
        }
    }
}

// MARK: - Toggle Card
struct ToggleCard: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let key: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Fonts.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text(subtitle)
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
        .padding(DesignSystem.Spacing.small)
    }
}
