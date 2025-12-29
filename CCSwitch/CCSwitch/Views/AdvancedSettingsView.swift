import SwiftUI

struct AdvancedSettingsView: View {
    @ObservedObject private var syncManager = SyncManager.shared
    @AppStorage("showDebugLogs") private var showDebugLogs = false
    @AppStorage("confirmBackupDeletion") private var confirmBackupDeletion = true

    @State private var showingResetAlert = false
    @State private var showingBackupSheet = false

    var body: some View {
        Form {
            // MARK: - iCloud Sync
            Section {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(LocalizationKey.icloudSync))
                                .font(.body)
                            Text(LocalizedStringKey(LocalizationKey.icloudSyncDesc))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { syncManager.syncConfig.isSyncEnabled },
                            set: { syncManager.toggleSync(enabled: $0) }
                        ))
                        .labelsHidden()
                    }

                    if syncManager.syncConfig.isSyncEnabled {
                        Divider().padding(.vertical, 4)

                        HStack {
                            Text(LocalizedStringKey(LocalizationKey.syncStatus))
                                .font(.subheadline)
                            Spacer()
                            SyncStatusView(status: syncManager.syncStatus)
                        }

                        HStack {
                            Spacer()

                            Button(LocalizedStringKey(LocalizationKey.syncNow)) {
                                syncManager.uploadSelectedVendors()
                            }
                            .controlSize(.small)
                        }
                    }
                }
            } header: {
                Text(LocalizedStringKey(LocalizationKey.icloudSettings))
            }

            // MARK: - Section 1: System Behavior
            Section {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    // Debug Logs
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(LocalizationKey.showDebugLogs))
                                .font(.body)
                            Text(LocalizedStringKey(LocalizationKey.debugLogsDesc))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $showDebugLogs)
                            .labelsHidden()
                    }

                    Divider().padding(.vertical, 4)

                    // Confirm Backup Deletion
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(LocalizationKey.confirmBackupDeletion))
                                .font(.body)
                            Text(LocalizedStringKey(LocalizationKey.confirmBackupDeletionDesc))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $confirmBackupDeletion)
                            .labelsHidden()
                    }
                }
            } header: {
                Text(LocalizedStringKey(LocalizationKey.systemBehavior))
            }

            // MARK: - Section 2: Data & Maintenance
            Section {
                HStack {
                    Text(LocalizedStringKey(LocalizationKey.backups))
                    Spacer()
                    Button(LocalizedStringKey(LocalizationKey.manageBackups)) {
                        showingBackupSheet = true
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(LocalizationKey.configFile))
                        Text(LocalizedStringKey(LocalizationKey.configFilePath))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button(LocalizedStringKey(LocalizationKey.showInFinder)) {
                            openConfigFolder()
                        }
                        .buttonStyle(.link)
                        .font(.subheadline)

                        Button(LocalizedStringKey(LocalizationKey.reloadConfig)) {
                            reloadConfiguration()
                        }
                        .controlSize(.small)
                    }
                }
            } header: {
                Text(LocalizedStringKey(LocalizationKey.dataMaintenance))
            }

            // MARK: - Section 3: Danger Zone
            Section {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Text(LocalizedStringKey(LocalizationKey.resetAppAction))
                        .frame(maxWidth: .infinity)
                }
            } header: {
                Text(LocalizedStringKey(LocalizationKey.dangerZone))
            } footer: {
                Text(LocalizedStringKey(LocalizationKey.resetAppStateWarning))
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showingBackupSheet) {
            BackupListView()
        }
        .sheet(isPresented: Binding(
            get: { !syncManager.pendingConflicts.isEmpty },
            set: { _ in }
        )) {
            SyncConflictResolverView()
        }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text(LocalizedStringKey(LocalizationKey.resetAppStateConfirmTitle)),
                message: Text(LocalizedStringKey(LocalizationKey.resetAppStateConfirmMsg)),
                primaryButton: .destructive(Text(LocalizedStringKey(LocalizationKey.resetButton))) {
                    resetAppState()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func reloadConfiguration() {
        ConfigManager.shared.initialize()
        let msg = LocalizationKey.localized(LocalizationKey.reloadSuccessMsg)
        ToastManager.shared.show(message: msg, type: .success)
    }

    private func openConfigFolder() {
        // Pointing to the CCSwitch config file specifically
        NSWorkspace.shared.selectFile(CCSConfig.configFile.path, inFileViewerRootedAtPath: "")
    }

    private func resetAppState() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        ConfigManager.shared.cleanup()
        ConfigManager.shared.initialize()

        // Defer the state update to ensure the previous alert is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let msg = LocalizationKey.localized(LocalizationKey.resetSuccessMsg)
            ToastManager.shared.show(message: msg, type: .success)
        }
    }
}

struct BackupListView: View {
    @State private var backups: [URL] = []
    @State private var showingRestoreAlert = false
    @State private var backupToRestore: URL?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(LocalizedStringKey(LocalizationKey.backups))
                    .font(.headline)
                Spacer()
                Button(LocalizedStringKey(LocalizationKey.done)) {
                    presentationMode.wrappedValue.dismiss()
                }
                .controlSize(.small)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            List {
                if backups.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "archivebox")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text(LocalizedStringKey(LocalizationKey.noBackups))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(backups.enumerated()), id: \.element.path) { _, backup in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(backup.lastPathComponent)
                                    .font(.body)
                                Text(getCreationDate(for: backup))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(LocalizedStringKey(LocalizationKey.restore)) {
                                backupToRestore = backup
                                showingRestoreAlert = true
                            }
                            .buttonStyle(.link)

                            Button(action: { deleteBackup(backup) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(width: 450, height: 350)
        .onAppear {
            loadBackups()
        }
        .alert(isPresented: $showingRestoreAlert) {
            Alert(
                title: Text(LocalizedStringKey(LocalizationKey.confirmRestoreTitle)),
                message: Text(LocalizedStringKey(LocalizationKey.confirmRestoreMsg)),
                primaryButton: .default(Text(LocalizedStringKey(LocalizationKey.restoreButton))) {
                    if let backup = backupToRestore {
                        restoreBackup(backup)
                    }
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

    private func getCreationDate(for url: URL) -> String {
        do {
            let values = try url.resourceValues(forKeys: [.creationDateKey])
            if let date = values.creationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
        } catch {}
        return ""
    }

    private func restoreBackup(_ backup: URL) {
        do {
            try BackupManager.shared.restoreFromBackup(backup)
            loadBackups()
            ToastManager.shared.show(message: LocalizationKey.localized(LocalizationKey.restoreSuccessMsg), type: .success)
        } catch {
            ToastManager.shared.show(message: error.localizedDescription, type: .error)
        }
    }

    private func deleteBackup(_ backup: URL) {
        do {
            try BackupManager.shared.deleteBackup(backup)
            loadBackups()
            ToastManager.shared.show(message: LocalizationKey.localized(LocalizationKey.backupDeletedSuccess), type: .success)
        } catch {
            ToastManager.shared.show(message: error.localizedDescription, type: .error)
        }
    }
}