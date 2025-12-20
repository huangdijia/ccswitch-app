import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                // App Info / Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)

                        Text("CC")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CCSwitch")
                            .font(DesignSystem.Fonts.headline)
                        Text("v1.0.0")
                            .font(DesignSystem.Fonts.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.large)
                .padding(.horizontal, DesignSystem.Spacing.small)

                // Navigation Items
                VStack(spacing: 4) {
                    SidebarItem(
                        icon: "gear",
                        title: "general",
                        isActive: selectedTab == .general
                    ) {
                        selectedTab = .general
                    }

                    SidebarItem(
                        icon: "server.rack",
                        title: "vendors",
                        isActive: selectedTab == .vendors
                    ) {
                        selectedTab = .vendors
                    }

                    SidebarItem(
                        icon: "gearshape.2",
                        title: "advanced",
                        isActive: selectedTab == .advanced
                    ) {
                        selectedTab = .advanced
                    }
                }

                Spacer()

                // Footer
                VStack(alignment: .leading, spacing: 4) {
                    Text("app_name")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("fast_switching")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.8))
                }
                .padding(.horizontal, DesignSystem.Spacing.small)
                .padding(.bottom, DesignSystem.Spacing.medium)
            }
            .padding(DesignSystem.Spacing.medium)
            .frame(width: 240)
            .background(Color(NSColor.controlBackgroundColor)) // Slightly different background for sidebar
            .overlay(
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(NSColor.separatorColor))
                        .frame(width: 1)
                }
            )

            // Main Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(LocalizedStringKey(tabTitle(for: selectedTab)))
                        .font(DesignSystem.Fonts.title)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Spacer()
                    
                    // Close button (optional, as window usually has one, but kept for consistency with old design if desired)
                    // Removing the custom close button to rely on native window controls which is more mac-like.
                }
                .padding(DesignSystem.Spacing.large)
                .background(DesignSystem.Colors.surface.opacity(0.5)) // Translucent header effect
                
                Divider()

                // Content
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
                    .padding(DesignSystem.Spacing.large)
                }
            }
            .background(DesignSystem.Colors.secondarySurface)
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func tabTitle(for tab: SettingsTab) -> String {
        switch tab {
        case .general: return "general_settings"
        case .vendors: return "vendor_management_title"
        case .advanced: return "advanced_options"
        }
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 24)

                Text(LocalizedStringKey(title))
                    .font(.system(size: 14, weight: .medium))

                Spacer()
                
                if isActive {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.blue.opacity(0.1) : (isHovered ? Color.gray.opacity(0.05) : Color.clear))
            )
            .foregroundColor(isActive ? .blue : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hover in
            isHovered = hover
        }
    }
}

enum SettingsTab {
    case general
    case vendors
    case advanced
}
