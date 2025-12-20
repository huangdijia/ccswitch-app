import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        HStack(spacing: 0) {
            // 侧边栏
            VStack(alignment: .leading, spacing: 8) {
                // Logo
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.gradient)
                            .frame(width: 40, height: 40)

                        Text("CC")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CCSwitch")
                            .font(.system(size: 14, weight: .bold))
                        Text("v1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)

                // 菜单项
                SidebarItem(
                    icon: "gear",
                    title: "通用设置",
                    isActive: selectedTab == .general
                ) {
                    selectedTab = .general
                }

                SidebarItem(
                    icon: "server.rack",
                    title: "供应商管理",
                    isActive: selectedTab == .vendors
                ) {
                    selectedTab = .vendors
                }

                SidebarItem(
                    icon: "gearshape.2",
                    title: "高级选项",
                    isActive: selectedTab == .advanced
                ) {
                    selectedTab = .advanced
                }

                Spacer()

                // 底部信息
                VStack(alignment: .leading, spacing: 6) {
                    Text("CCSwitch")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("快速切换 Claude 供应商")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                }
                .padding(.bottom, 8)
            }
            .frame(width: 200)
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))

            // 主内容区域
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text(tabTitle(for: selectedTab))
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Button(action: {
                        if let window = NSApp.keyWindow {
                            window.close()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 28, height: 28)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(20)
                .background(Color(NSColor.textBackgroundColor))

                // 内容视图
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        switch selectedTab {
                        case .general:
                            GeneralSettingsView()
                        case .vendors:
                            VendorManagementView()
                        case .advanced:
                            AdvancedSettingsView()
                        }
                    }
                    .padding(24)
                }
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .frame(width: 900, height: 650)
        .background(Color(NSColor.textBackgroundColor))
    }

    private func tabTitle(for tab: SettingsTab) -> String {
        switch tab {
        case .general: return "通用设置"
        case .vendors: return "供应商管理"
        case .advanced: return "高级选项"
        }
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 14, weight: .medium))

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                isActive ? Color.blue.opacity(0.15) : Color.clear
            )
            .foregroundColor(isActive ? .blue : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SettingsTab {
    case general
    case vendors
    case advanced
}