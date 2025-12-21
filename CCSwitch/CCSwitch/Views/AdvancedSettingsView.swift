import SwiftUI

struct AdvancedSettingsView: View {
    @State private var backups: [URL] = []
    @State private var showingRestoreAlert = false
    @State private var backupToRestore: URL?
    @State private var showingResetAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ModernSection(title: "backups") {
                if backups.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("no_backups")
                                .font(DesignSystem.Fonts.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(DesignSystem.Spacing.xLarge)
                        Spacer()
                    }
                } else {
                    ForEach(Array(backups.enumerated()), id: \.element) { index, backup in
                        BackupRow(
                            backup: backup,
                            onRestore: {
                                backupToRestore = backup
                                showingRestoreAlert = true
                            },
                            onDelete: {
                                deleteBackup(backup)
                            }
                        )
                        if index < backups.count - 1 {
                            ModernDivider()
                        }
                    }
                }
            }

            ModernSection(title: "maintenance") {
                ModernRow(
                    icon: "arrow.clockwise",
                    iconColor: .orange,
                    title: "reload_config",
                    subtitle: "reload_config_desc",
                    action: reloadConfiguration
                )
                ModernDivider()
                ModernRow(
                    icon: "folder",
                    iconColor: .blue,
                    title: "open_claude_config",
                    subtitle: "open_claude_config_desc",
                    action: openClaudeConfig
                )
                ModernDivider()
                ModernRow(
                    icon: "trash",
                    iconColor: .red,
                    title: "reset_app_state",
                    subtitle: "reset_app_state_desc",
                    action: { showingResetAlert = true }
                )
            }
        }
        .onAppear {
            loadBackups()
        }
        .alert(isPresented: $showingRestoreAlert) {
            Alert(
                title: Text("confirm_restore_title"),
                message: Text("confirm_restore_msg"),
                primaryButton: .default(Text("restore_button")) {
                    if let backup = backupToRestore {
                        restoreBackup(backup)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("confirm_reset_title"),
                message: Text("confirm_reset_msg"),
                primaryButton: .destructive(Text("reset_button")) {
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
            try BackupManager.shared.restoreFromBackup(backup)
            showAlert(title: NSLocalizedString("success", comment: ""), message: NSLocalizedString("restore_success_msg", comment: ""))
            loadBackups()
        } catch {
            showAlert(title: NSLocalizedString("error", comment: ""), message: error.localizedDescription)
        }
    }

    private func deleteBackup(_ backup: URL) {
        do {
            try BackupManager.shared.deleteBackup(backup)
            loadBackups()
        } catch {
            showAlert(title: NSLocalizedString("error", comment: ""), message: error.localizedDescription)
        }
    }

    private func reloadConfiguration() {
        ConfigManager.shared.initialize()
        showAlert(title: NSLocalizedString("reloaded", comment: ""), message: NSLocalizedString("reload_success_msg", comment: ""))
    }

    private func openClaudeConfig() {
        NSWorkspace.shared.selectFile(ClaudeSettings.configFile.path, inFileViewerRootedAtPath: "")
    }

    private func resetAppState() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        ConfigManager.shared.cleanup()
        ConfigManager.shared.initialize()
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
}

struct BackupRow: View {
    let backup: URL
    let onRestore: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    private var displayName: String {
        let fileName = backup.lastPathComponent
        if let range = fileName.range(of: "bak-") {
            return String(fileName[range.upperBound...])
        }
        return fileName
    }

    private var creationDate: String? {
        do {
            let resourceValues = try backup.resourceValues(forKeys: [.creationDateKey])
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: resourceValues.creationDate ?? Date())
        } catch {
            return nil
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: "doc.on.doc.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(DesignSystem.Fonts.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                if let date = creationDate {
                    Text(date)
                        .font(DesignSystem.Fonts.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: DesignSystem.Spacing.small) {
                Button(action: onRestore) {
                    Text("restore_button")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .background(Color.red.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(isHovered ? Color.gray.opacity(0.05) : Color.clear)
        .onHover { hover in
            isHovered = hover
        }
    }
}
