import Cocoa
import SwiftUI

@main
struct CCSwitchApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: MenuBarController?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化配置管理器
        ConfigManager.shared.initialize()

        // 创建状态栏控制器
        statusBarController = MenuBarController()

        // 设置应用图标（如果有）
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") {
            NSApplication.shared.applicationIconImage = NSImage(contentsOfFile: iconPath)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 清理资源
        ConfigManager.shared.cleanup()
    }

    func showSettingsWindow() {
        if settingsWindow == nil {
            let contentView = SettingsView()
            let hostingView = NSHostingView(rootView: contentView)

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )

            settingsWindow?.title = NSLocalizedString("window_title_settings", comment: "")
            settingsWindow?.contentView = hostingView
            settingsWindow?.center()
            settingsWindow?.setFrameAutosaveName("SettingsWindow")
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Design System (Refined for Minimalist Style)

struct DesignSystem {
    struct Colors {
        static let background = Color(NSColor.windowBackgroundColor)
        static let surface = Color(NSColor.controlBackgroundColor)
        static let secondarySurface = Color(NSColor.underPageBackgroundColor)
        static let accent = Color.blue
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color.secondary.opacity(0.7)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let border = Color(NSColor.separatorColor).opacity(0.5)
    }
    
    struct Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 32
    }
    
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
    }
    
    struct Fonts {
        static let title = Font.system(size: 20, weight: .bold)
        static let headline = Font.system(size: 14, weight: .semibold)
        static let body = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 11, weight: .regular)
    }
}

// MARK: - Generic Modern Components

struct ModernSection<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            if let title = title {
                Text(LocalizedStringKey(title))
                    .font(DesignSystem.Fonts.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .padding(.leading, 4)
                    .textCase(.uppercase)
            }
            
            VStack(spacing: 0) {
                content()
            }
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
            )
        }
        .padding(.bottom, DesignSystem.Spacing.large)
    }
}

struct ModernRow: View {
    let icon: String?
    var iconColor: Color = .blue
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var showChevron: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                if let icon = icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(iconColor.opacity(0.1))
                            .frame(width: 28, height: 28)
                        Image(systemName: icon)
                            .foregroundColor(iconColor)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(DesignSystem.Fonts.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    if let subtitle = subtitle {
                        Text(LocalizedStringKey(subtitle))
                            .font(DesignSystem.Fonts.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(DesignSystem.Fonts.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small + 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 52) // Offset to align with text if icon is present
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Fonts.body.weight(.medium))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(DesignSystem.Colors.accent)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Fonts.body.weight(.medium))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}