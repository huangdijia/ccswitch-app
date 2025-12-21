import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

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
            .fixedSize(horizontal: true, vertical: true) // 关键：强制垂直方向紧贴内容
        }
        .background(Color(NSColor.windowBackgroundColor))
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