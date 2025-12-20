import SwiftUI

struct AdvancedSettingsView: View {
    @State private var backups: [URL] = []
    @State private var showingRestoreAlert = false
    @State private var backupToRestore: URL?
    @State private var showingResetAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 备份管理卡片
            SettingsCard(
                title: "备份管理",
                icon: "clock.arrow.circlepath",
                iconColor: .blue,
                content: {
                    if backups.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 56, height: 56)

                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }

                            Text("暂无备份文件")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("切换供应商时会自动创建备份")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(backups, id: \.self) { backup in
                                BackupCard(
                                    backup: backup,
                                    onRestore: {
                                        backupToRestore = backup
                                        showingRestoreAlert = true
                                    },
                                    onDelete: {
                                        deleteBackup(backup)
                                    }
                                )
                            }
                        }
                    }
                }
            )

            // 操作卡片
            SettingsCard(
                title: "维护操作",
                icon: "wrench.and.screwdriver",
                iconColor: .orange,
                content: {
                    VStack(spacing: 12) {
                        ActionButton(
                            icon: "arrow.clockwise",
                            title: "重载配置",
                            subtitle: "重新读取配置文件",
                            action: reloadConfiguration
                        )

                        ActionButton(
                            icon: "folder",
                            title: "打开 Claude 配置",
                            subtitle: "在 Finder 中显示配置文件",
                            action: openClaudeConfig
                        )

                        ActionButton(
                            icon: "arrow.triangle.2.circlepath",
                            title: "重置应用状态",
                            subtitle: "清除缓存并恢复默认设置",
                            action: { showingResetAlert = true },
                            isDestructive: true
                        )
                    }
                }
            )
        }
        .onAppear {
            loadBackups()
        }
        .alert(isPresented: $showingRestoreAlert) {
            Alert(
                title: Text("确认恢复"),
                message: Text("确定要恢复到此备份吗？当前配置将被自动备份。"),
                primaryButton: .default(Text("恢复")) {
                    if let backup = backupToRestore {
                        restoreBackup(backup)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("确认重置"),
                message: Text("这将清除应用的缓存状态，但不会删除配置文件。确定要继续吗？"),
                primaryButton: .destructive(Text("重置")) {
                    resetAppState()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func loadBackups() {
        do {
            backups = try BackupManager.shared.getAllBackups()
        } catch {
            print("Failed to load backups: \(error)")
        }
    }

    private func restoreBackup(_ backup: URL) {
        do {
            try BackupManager.shared.restoreFromBackup(backupURL: backup)
            showAlert(title: "恢复成功", message: "配置已恢复")
            loadBackups()
        } catch {
            showAlert(title: "恢复失败", message: error.localizedDescription)
        }
    }

    private func deleteBackup(_ backup: URL) {
        do {
            try BackupManager.shared.deleteBackup(backupURL: backup)
            loadBackups()
        } catch {
            showAlert(title: "删除失败", message: error.localizedDescription)
        }
    }

    private func reloadConfiguration() {
        ConfigManager.shared.initialize()
        showAlert(title: "重载完成", message: "配置已重新加载")
    }

    private func openClaudeConfig() {
        NSWorkspace.shared.selectFile(ClaudeSettings.configFile.path, inFileViewerRootedAtPath: "")
    }

    private func resetAppState() {
        let alert = NSAlert()
        alert.messageText = "确认重置"
        alert.informativeText = "这将清除应用的缓存状态，但不会删除配置文件。确定要继续吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            // 清理 UserDefaults
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)

            // 重新初始化
            ConfigManager.shared.cleanup()
            ConfigManager.shared.initialize()

            showAlert(title: "重置完成", message: "应用状态已重置")
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
}

// MARK: - Backup Card
struct BackupCard: View {
    let backup: URL
    let onRestore: () -> Void
    let onDelete: () -> Void

    private var fileName: String {
        backup.lastPathComponent
    }

    private var displayName: String {
        if let range = fileName.range(of: "bak-") {
            let timestamp = String(fileName[range.upperBound...])
            return timestamp
        }
        return fileName
    }

    private var creationDate: String? {
        do {
            let resourceValues = try backup.resourceValues(forKeys: [.creationDateKey])
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            return formatter.string(from: resourceValues.creationDate ?? Date())
        } catch {
            return nil
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // 备份图标
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: "doc.on.doc.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14, weight: .semibold))
            }

            // 备份信息
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                if let date = creationDate {
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 操作按钮
            HStack(spacing: 8) {
                Button(action: onRestore) {
                    Text("恢复")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
                .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let isDestructive: Bool

    init(icon: String, title: String, subtitle: String, action: @escaping () -> Void, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isDestructive = isDestructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            isDestructive
                                ? Color.red.opacity(0.1)
                                : Color.orange.opacity(0.1)
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .foregroundColor(isDestructive ? .red : .orange)
                        .font(.system(size: 15, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : .primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.textBackgroundColor))
                    .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isDestructive ? Color.red.opacity(0.3) : Color.gray.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}