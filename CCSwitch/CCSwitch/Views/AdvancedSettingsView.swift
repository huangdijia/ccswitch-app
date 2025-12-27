import SwiftUI

struct AdvancedSettingsView: View {
    @ObservedObject private var syncManager = SyncManager.shared
    @AppStorage("showDebugLogs") private var showDebugLogs = false
    @AppStorage("confirmBackupDeletion") private var confirmBackupDeletion = true
    
    @State private var showingResetAlert = false
    @State private var showingBackupSheet = false
    @State private var showingSyncSelectionSheet = false
    
    var body: some View {
        Form {
            // MARK: - iCloud Sync
            Section {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("icloud_sync")
                                .font(.body)
                            Text("icloud_sync_desc")
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
                            Text("sync_status")
                                .font(.subheadline)
                            Spacer()
                            SyncStatusView(status: syncManager.syncStatus)
                        }
                        
                        HStack(spacing: 12) {
                            Button("manage_synced_items") {
                                showingSyncSelectionSheet = true
                            }
                            .buttonStyle(.link)
                            .font(.subheadline)
                            
                            Spacer()
                            
                            Button("sync_now") {
                                syncManager.uploadSelectedVendors()
                            }
                            .controlSize(.small)
                        }
                    }
                }
            } header: {
                Text("icloud_settings")
            }

            // MARK: - Section 1: System Behavior
            Section {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    // Debug Logs
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("show_debug_logs")
                                .font(.body)
                            Text("debug_logs_desc")
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
                            Text("confirm_backup_deletion")
                                .font(.body)
                            Text("confirm_backup_deletion_desc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $confirmBackupDeletion)
                            .labelsHidden()
                    }
                }
            } header: {
                Text("system_behavior")
            }
            
            // MARK: - Section 2: Data & Maintenance
            Section {
                HStack {
                    Text("backups")
                    Spacer()
                    Button("manage_backups") {
                        showingBackupSheet = true
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("config_file")
                        Text("config_file_path")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button("show_in_finder") {
                            openConfigFolder()
                        }
                        .buttonStyle(.link)
                        .font(.subheadline)
                        
                        Button("reload_config") {
                            reloadConfiguration()
                        }
                        .controlSize(.small)
                    }
                }
            } header: {
                Text("data_maintenance")
            }
            
            // MARK: - Section 3: Danger Zone
            Section {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Text("reset_app_action")
                        .frame(maxWidth: .infinity)
                }
            } header: {
                Text("danger_zone")
            } footer: {
                Text("reset_app_state_warning")
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
        .sheet(isPresented: $showingSyncSelectionSheet) {
            SyncSelectionView()
        }
        .sheet(isPresented: Binding(
            get: { !syncManager.pendingConflicts.isEmpty },
            set: { _ in }
        )) {
            SyncConflictResolverView()
        }
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("reset_app_state_confirm_title"),
                message: Text("reset_app_state_confirm_msg"),
                primaryButton: .destructive(Text("reset_button")) {
                    resetAppState()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func reloadConfiguration() {
        ConfigManager.shared.initialize()
        let msg = NSLocalizedString("reload_success_msg", comment: "Configuration reloaded.")
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
            let msg = NSLocalizedString("reset_success_msg", comment: "App state reset.")
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
                Text("backups")
                    .font(.headline)
                Spacer()
                Button("done") {
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
                            Text("no_backups")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(backups, id: \.self) { backup in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(backup.lastPathComponent)
                                    .font(.body)
                                Text(getCreationDate(for: backup))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("restore") {
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
            ToastManager.shared.show(message: NSLocalizedString("restore_success_msg", comment: ""), type: .success)
        } catch {
            ToastManager.shared.show(message: error.localizedDescription, type: .error)
        }
    }

    private func deleteBackup(_ backup: URL) {
        do {
            try BackupManager.shared.deleteBackup(backup)
            loadBackups()
            ToastManager.shared.show(message: NSLocalizedString("backup_deleted_success", comment: ""), type: .success)
        } catch {
            ToastManager.shared.show(message: error.localizedDescription, type: .error)
        }
    }
}