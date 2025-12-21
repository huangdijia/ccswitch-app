import SwiftUI

struct AdvancedSettingsView: View {
    @State private var showDebugLogs = false
    @State private var confirmBackupDeletion = true
    @State private var showingResetAlert = false
    @State private var showingBackupSheet = false
    @State private var showingReloadSuccess = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // System Options
            VStack(alignment: .leading, spacing: 16) {
                Toggle("show_debug_logs", isOn: $showDebugLogs)
                    .toggleStyle(.checkbox)
                
                Toggle("confirm_backup_deletion", isOn: $confirmBackupDeletion)
                    .toggleStyle(.checkbox)
            }
            
            // Maintenance Section
            VStack(alignment: .leading, spacing: 12) {
                Text("maintenance")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button("manage_backups") {
                            showingBackupSheet = true
                        }
                        
                        Button("reload_config") {
                            reloadConfiguration()
                        }
                    }
                    
                    HStack {
                        Button("open_claude_config") {
                            openClaudeConfig()
                        }
                        
                        Button(role: .destructive, action: {
                            showingResetAlert = true
                        }) {
                            Text("reset_app_state")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.leading, 16) // Indent actions
            }
            
            Spacer()
        }
        .padding(24)
        .sheet(isPresented: $showingBackupSheet) {
            BackupListView()
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

    private func openClaudeConfig() {
        NSWorkspace.shared.selectFile(ClaudeSettings.configFile.path, inFileViewerRootedAtPath: "")
    }

    private func resetAppState() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        ConfigManager.shared.cleanup()
        ConfigManager.shared.initialize()
    }
}

struct BackupListView: View {
    @State private var backups: [URL] = []
    @State private var showingRestoreAlert = false
    @State private var backupToRestore: URL?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Text("backups")
                    .font(.headline)
                Spacer()
                Button("done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            
            List {
                if backups.isEmpty {
                    Text("no_backups")
                        .foregroundColor(.secondary)
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
        .frame(width: 400, height: 300)
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
