import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @ObservedObject var migrationManager = MigrationManager.shared
    @ObservedObject var toastManager = ToastManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // 自定义标签栏 (类似 Finder 设置)
            HStack(spacing: 25) {
                TabItemView(tab: .general, selection: $selectedTab, icon: "gearshape", title: LocalizationKey.general)
                TabItemView(tab: .vendors, selection: $selectedTab, icon: "tag", title: LocalizationKey.vendors)
                TabItemView(tab: .advanced, selection: $selectedTab, icon: "gearshape.2", title: LocalizationKey.advanced)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 内容区域
            ZStack(alignment: .top) {
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView()
                    case .vendors:
                        VendorManagementView()
                    case .advanced:
                        AdvancedSettingsView()
                    }
                }
            }
            .frame(width: 600)
            .fixedSize(horizontal: true, vertical: true)
        }
        .sheet(isPresented: $migrationManager.showMigrationPrompt) {
            MigrationAlertView()
        }
        .toast(isPresented: $toastManager.isPresented, message: toastManager.message, type: toastManager.type)
    }
}

struct TabItemView: View {
    let tab: SettingsTab
    @Binding var selection: SettingsTab
    let icon: String
    let title: String
    
    var isSelected: Bool { selection == tab }
    
    var body: some View {
        Button(action: { selection = tab }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(height: 28)
                
                Text(LocalizedStringKey(title))
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(width: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.primary.opacity(0.05) : Color.clear)
        )
    }
}

enum SettingsTab: Hashable {

    case general

    case vendors

    case advanced

}



// MARK: - Migration View

struct MigrationAlertView: View {
    @ObservedObject var manager = MigrationManager.shared
    @State private var resultMessage: String?
    @State private var migrationFinished = false
    @State private var isSuccess = false
    @State private var dontShowAgain = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            if migrationFinished && !isSuccess {
                // Error State (Keep error message in sheet)
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text(resultMessage ?? "")
                        .multilineTextAlignment(.center)
                        .font(DesignSystem.Fonts.body)
                    
                    Button(action: {
                        manager.showMigrationPrompt = false
                    }) {
                        Text(LocalizationKey.localized(LocalizationKey.ok))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(width: 120)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                
            } else {
                // Migration Prompt State
                
                // 1. Title
                Text(LocalizationKey.localized(LocalizationKey.migrationTitle))
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.bottom, 12)
                
                // 2. Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: LocalizationKey.localized(LocalizationKey.migrationFoundVendors), manager.legacyVendorsCount))
                        .font(.body)
                }
                .padding(.bottom, 16)
                
                // 3. Description
                Text(LocalizationKey.localized(LocalizationKey.migrationNote))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)
                
                // 4. Actions
                if manager.isMigrating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(LocalizationKey.localized(LocalizationKey.migrating))
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 12)
                } else {
                    HStack(alignment: .center) {
                        // Checkbox
                        Toggle(isOn: $dontShowAgain) {
                            Text(LocalizationKey.localized(LocalizationKey.migrationDontShowAgainCheckbox))
                                .font(.caption)
                        }
                        .toggleStyle(.checkbox)
                        
                        Spacer()
                        
                        // Buttons
                        Button(action: {
                            if dontShowAgain {
                                manager.skipMigration()
                            }
                            manager.showMigrationPrompt = false
                        }) {
                            Text(LocalizationKey.localized(LocalizationKey.migrateLater))
                                .frame(width: 80)
                        }
                        .keyboardShortcut(.cancelAction)
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button(action: {
                            Task {
                                let result = await manager.performMigration()
                                await MainActor.run {
                                    handleResult(result)
                                }
                            }
                        }) {
                            Text(LocalizationKey.localized(LocalizationKey.migrateNowButton))
                                .frame(width: 100)
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 450)
    }
    
    private func handleResult(_ result: MigrationResult) {
        switch result {
        case .success(let count):
            isSuccess = true
            // Show toast and close sheet immediately for success
            let msg = String(format: LocalizationKey.localized(LocalizationKey.migrationSuccessMsg), count)
            ToastManager.shared.show(message: msg, type: .success)
            manager.showMigrationPrompt = false
            
        case .failure(let errorMessage):
            isSuccess = false
            resultMessage = String(format: LocalizationKey.localized(LocalizationKey.migrationFailureMsg), errorMessage)
            migrationFinished = true
        }
    }
}
