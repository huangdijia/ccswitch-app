import SwiftUI

struct AdvancedSettingsView: View {
    @State private var backups: [URL] = []
    @State private var showingRestoreAlert = false
    @State private var backupToRestore: URL?
    @State private var showingResetAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            // Backups Section
            SettingsCard(
                title: "backups",
                icon: "clock.arrow.circlepath",
                iconColor: .blue
            ) {
                if backups.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 56, height: 56)

                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text("no_backups")
                            .font(DesignSystem.Fonts.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Text("no_backups_desc")
                            .font(DesignSystem.Fonts.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.large)
                    .background(DesignSystem.Colors.secondarySurface)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                } else {
                    LazyVStack(spacing: DesignSystem.Spacing.small) {
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

            // Maintenance Section
            SettingsCard(
                title: "maintenance",
                icon: "wrench.and.screwdriver.fill",
                iconColor: .orange
            ) {
                VStack(spacing: DesignSystem.Spacing.small) {
                    ActionButton(
                        icon: "arrow.clockwise",
                        title: "reload_config",
                        subtitle: "reload_config_desc",
                        action: reloadConfiguration
                    )

                    ActionButton(
                        icon: "folder",
                        title: "open_claude_config",
                        subtitle: "open_claude_config_desc",
                        action: openClaudeConfig
                    )

                    ActionButton(
                        icon: "trash",
                        title: "reset_app_state",
                        subtitle: "reset_app_state_desc",
                        action: { showingResetAlert = true },
                        isDestructive: true
                    )
                }
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
            try BackupManager.shared.restoreFromBackup(backupURL: backup)
            showAlert(title: NSLocalizedString("success", comment: ""), message: NSLocalizedString("restore_success_msg", comment: ""))
            loadBackups()
        } catch {
            showAlert(title: NSLocalizedString("error", comment: ""), message: error.localizedDescription)
        }
    }

    private func deleteBackup(_ backup: URL) {
        do {
            try BackupManager.shared.deleteBackup(backupURL: backup)
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
        // Logic remains the same, just keeping it cleaner
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

// MARK: - BackupCard
struct BackupCard: View {
    let backup: URL
    let onRestore: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    private var fileName: String {
        backup.lastPathComponent
    }

    private var displayName: String {
        if let range = fileName.range(of: "bak-") {
            let timestamp = String(fileName[range.upperBound...])
            // Optional: format timestamp nicely if needed
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
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: "doc.on.doc.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(DesignSystem.Fonts.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                if let date = creationDate {
                    Text(date)
                        .font(DesignSystem.Fonts.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: DesignSystem.Spacing.small) {
                Button(action: onRestore) {
                    Text("restore_button")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(DesignSystem.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(isHovered ? DesignSystem.Colors.secondarySurface : Color.clear)
        )
        .onHover { hover in
            isHovered = hover
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let isDestructive: Bool
    @State private var isHovered = false

    init(icon: String, title: String, subtitle: String, action: @escaping () -> Void, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isDestructive = isDestructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(
                            isDestructive
                                ? DesignSystem.Colors.error.opacity(0.1)
                                : DesignSystem.Colors.warning.opacity(0.1)
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .foregroundColor(isDestructive ? DesignSystem.Colors.error : DesignSystem.Colors.warning)
                        .font(.system(size: 14, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(DesignSystem.Fonts.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary)

                    Text(LocalizedStringKey(subtitle))
                        .font(DesignSystem.Fonts.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                    .font(.caption)
            }
            .padding(DesignSystem.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(isHovered ? DesignSystem.Colors.secondarySurface : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hover in
            isHovered = hover
        }
    }
}
