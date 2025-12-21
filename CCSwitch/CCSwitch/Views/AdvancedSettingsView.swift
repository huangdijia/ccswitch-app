import SwiftUI

struct AdvancedSettingsView: View {
    @AppStorage("showDebugLogs") private var showDebugLogs = false
    @AppStorage("confirmBackupDeletion") private var confirmBackupDeletion = true
    
    @State private var showingResetAlert = false
    @State private var showingBackupSheet = false
    @State private var showingReloadSuccess = false
    
    var body: some View {
        Form {
            // MARK: - Section 1: System Behavior
            Section {
                Toggle("show_debug_logs", isOn: $showDebugLogs)
                Toggle("confirm_backup_deletion", isOn: $confirmBackupDeletion)
            } header: {
                Text("system_behavior")
            } footer: {
                Text("debug_logs_desc")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
        .alert(isPresented: $showingReloadSuccess) {
            Alert(
                title: Text("reloaded"),
                message: Text("reload_success_msg"),
                dismissButton: .default(Text("ok"))
            )
        }
    }

    private func reloadConfiguration() {
        ConfigManager.shared.initialize()
        showingReloadSuccess = true
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
        
        // Note: In a real app, you might want to force restart or notify the user 
        // that defaults have been restored.
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
        } catch {
            print("Error restoring backup: \(error)")
        }
    }

    private func deleteBackup(_ backup: URL) {
        do {
            try BackupManager.shared.deleteBackup(backup)
            loadBackups()
        } catch {
            print("Error deleting backup: \(error)")
        }
    }
}