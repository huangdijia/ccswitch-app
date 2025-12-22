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

    

    var body: some View {

        VStack(spacing: DesignSystem.Spacing.large) {

            VStack(spacing: DesignSystem.Spacing.small) {

                Image(systemName: migrationFinished ? (isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill") : "arrow.triangle.2.circlepath.doc.on.clipboard")

                    .font(.system(size: 40))

                    .foregroundColor(migrationFinished ? (isSuccess ? .green : .red) : DesignSystem.Colors.accent)

                

                Text(migrationFinished ? NSLocalizedString("migration_completed", comment: "迁移完成") : NSLocalizedString("migration_title", comment: "检测到旧版配置"))

                    .font(DesignSystem.Fonts.title)

            }

            

            VStack(spacing: DesignSystem.Spacing.medium) {

                if migrationFinished {

                    Text(resultMessage ?? "")

                        .multilineTextAlignment(.center)

                        .font(DesignSystem.Fonts.body)

                } else {

                    Text(String(format: NSLocalizedString("migration_message", comment: "发现旧版配置文件中包含 %d 个供应商，是否现在迁移到新版格式？"), manager.legacyVendorsCount))

                        .multilineTextAlignment(.center)

                        .font(DesignSystem.Fonts.body)

                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    

                    if let defaultVendor = manager.legacyDefaultVendor {

                        Text(String(format: NSLocalizedString("migration_default_vendor", comment: "默认供应商: %@"), defaultVendor))

                            .font(DesignSystem.Fonts.caption)

                            .foregroundColor(DesignSystem.Colors.textPrimary)

                    }

                    

                    Text(NSLocalizedString("migration_note", comment: "迁移过程中会自动创建备份，不会影响旧版文件的使用。"))

                        .font(DesignSystem.Fonts.caption)

                        .foregroundColor(DesignSystem.Colors.textTertiary)

                        .multilineTextAlignment(.center)

                }

            }

            .padding(.horizontal)

            

            if manager.isMigrating {

                VStack(spacing: DesignSystem.Spacing.medium) {

                    ProgressView()

                    Text(NSLocalizedString("migrating", comment: "正在迁移..."))

                        .font(DesignSystem.Fonts.caption)

                }

            } else if migrationFinished {

                Button(action: {

                    manager.showMigrationPrompt = false

                }) {

                    Text(NSLocalizedString("ok", comment: "确定"))

                        .frame(maxWidth: .infinity)

                }

                .buttonStyle(PrimaryButtonStyle())

            } else {

                VStack(spacing: DesignSystem.Spacing.small) {

                    Button(action: {

                        Task {

                            let result = await manager.performMigration()

                            await MainActor.run {

                                handleResult(result)

                            }

                        }

                    }) {

                        Text(NSLocalizedString("migrate_now", comment: "立即迁移"))

                            .frame(maxWidth: .infinity)

                    }

                    .buttonStyle(PrimaryButtonStyle())

                    

                    HStack(spacing: DesignSystem.Spacing.medium) {

                        Button(action: {

                            manager.showMigrationPrompt = false

                        }) {

                            Text(NSLocalizedString("migrate_later", comment: "稍后"))

                                .frame(maxWidth: .infinity)

                        }

                        .buttonStyle(SecondaryButtonStyle())

                        

                        Button(action: {

                            manager.skipMigration()

                        }) {

                            Text(NSLocalizedString("dont_show_again", comment: "不再提示"))

                                .frame(maxWidth: .infinity)

                        }

                        .buttonStyle(SecondaryButtonStyle())

                    }

                }

            }

        }

        .padding(DesignSystem.Spacing.xLarge)

        .frame(width: 400)

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
