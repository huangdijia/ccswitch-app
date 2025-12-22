import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @ObservedObject var migrationManager = MigrationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // 自定义标签栏 (类似 Finder 设置)
            HStack(spacing: 25) {
                TabItemView(tab: .general, selection: $selectedTab, icon: "gearshape", title: "general")
                TabItemView(tab: .vendors, selection: $selectedTab, icon: "tag", title: "vendors")
                TabItemView(tab: .advanced, selection: $selectedTab, icon: "gearshape.2", title: "advanced")
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
            
            if migrationFinished {
                // Success/Error State
                VStack(spacing: 20) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(isSuccess ? .green : .red)
                    
                    Text(resultMessage ?? "")
                        .multilineTextAlignment(.center)
                        .font(DesignSystem.Fonts.body)
                    
                    Button(action: {
                        manager.showMigrationPrompt = false
                    }) {
                        Text(NSLocalizedString("ok", comment: "确定"))
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
                Text(NSLocalizedString("migration_title", comment: "检测到旧版配置"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.bottom, 12)
                
                // 2. Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: NSLocalizedString("migration_found_vendors", comment: "发现：%d 个供应商"), manager.legacyVendorsCount))
                        .font(.body)
                }
                .padding(.bottom, 16)
                
                // 3. Description
                Text(NSLocalizedString("migration_note", comment: "迁移过程中会自动创建备份，不会影响旧版文件的使用。"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)
                
                // 4. Actions
                if manager.isMigrating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(NSLocalizedString("migrating", comment: "正在迁移..."))
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 12)
                } else {
                    HStack(alignment: .center) {
                        // Checkbox
                        Toggle(isOn: $dontShowAgain) {
                            Text(NSLocalizedString("migration_dont_show_again_checkbox", comment: "不再提示"))
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
                            Text(NSLocalizedString("migrate_later", comment: "稍后"))
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
                            Text(NSLocalizedString("migrate_now", comment: "立即迁移"))
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
            resultMessage = String(format: NSLocalizedString("migration_success_msg", comment: "成功迁移了 %d 个供应商。"), count)
        case .failure(let errorMessage):
            isSuccess = false
            resultMessage = String(format: NSLocalizedString("migration_failure_msg", comment: "迁移失败: %@"), errorMessage)
        }
        migrationFinished = true
    }
}
