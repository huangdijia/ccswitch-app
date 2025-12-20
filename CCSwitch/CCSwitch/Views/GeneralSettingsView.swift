import SwiftUI

struct GeneralSettingsView: View {
    @State private var showSwitchNotification = true
    @State private var autoLoadConfig = true
    @State private var autoBackup = true

    private let currentVendor = ConfigManager.shared.currentVendor

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 当前状态卡片
            SettingsCard(
                title: "当前状态",
                icon: "info.circle.fill",
                iconColor: .blue,
                content: {
                    VStack(spacing: 12) {
                        StatusCard(
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            title: "当前供应商",
                            value: currentVendor?.displayName ?? "未知"
                        )

                        PathButton(
                            icon: "folder",
                            title: "Claude 配置",
                            path: ClaudeSettings.configFile.path
                        )

                        PathButton(
                            icon: "folder",
                            title: "供应商配置",
                            path: CCSConfig.configFile.path
                        )
                    }
                }
            )

            // 通知设置卡片
            SettingsCard(
                title: "通知设置",
                icon: "bell.fill",
                iconColor: .orange,
                content: {
                    ToggleCard(
                        title: "切换后显示通知",
                        subtitle: "供应商切换成功时显示系统通知",
                        isOn: $showSwitchNotification,
                        key: "showSwitchNotification"
                    )
                }
            )

            // 启动设置卡片
            SettingsCard(
                title: "启动设置",
                icon: "gear.badge.checkmark",
                iconColor: .purple,
                content: {
                    VStack(spacing: 12) {
                        ToggleCard(
                            title: "启动时自动加载配置",
                            subtitle: "应用启动时自动读取配置文件",
                            isOn: $autoLoadConfig,
                            key: "autoLoadConfig"
                        )

                        ToggleCard(
                            title: "自动备份 Claude 配置",
                            subtitle: "切换前自动备份当前配置",
                            isOn: $autoBackup,
                            key: "autoBackup"
                        )
                    }
                }
            )
        }
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        showSwitchNotification = UserDefaults.standard.bool(forKey: "showSwitchNotification")
        autoLoadConfig = UserDefaults.standard.bool(forKey: "autoLoadConfig")
        autoBackup = UserDefaults.standard.bool(forKey: "autoBackup")

        // 设置默认值
        if !UserDefaults.standard.object(forKey: "showSwitchNotification").isSome {
            showSwitchNotification = true
            UserDefaults.standard.set(true, forKey: "showSwitchNotification")
        }
        if !UserDefaults.standard.object(forKey: "autoLoadConfig").isSome {
            autoLoadConfig = true
            UserDefaults.standard.set(true, forKey: "autoLoadConfig")
        }
        if !UserDefaults.standard.object(forKey: "autoBackup").isSome {
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18, weight: .semibold))

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()
            }

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)

                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Path Button
struct PathButton: View {
    let icon: String
    let title: String
    let path: String

    var body: some View {
        Button(action: {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 13, weight: .medium))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(12)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
                .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
        )
    }
}

// MARK: - Toggle Card
struct ToggleCard: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let key: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
                .labelsHidden()
                .onChange(of: isOn) { newValue in
                    UserDefaults.standard.set(newValue, forKey: key)
                }
        }
        .padding(12)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Helper extension to check if optional has a value
extension Optional {
    var isSome: Bool {
        switch self {
        case .none:
            return false
        case .some:
            return true
        }
    }
}