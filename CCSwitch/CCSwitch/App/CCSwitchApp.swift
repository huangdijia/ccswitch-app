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

            settingsWindow?.title = "CCSwitch Settings"
            settingsWindow?.contentView = hostingView
            settingsWindow?.center()
            settingsWindow?.setFrameAutosaveName("SettingsWindow")
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Design System (Moved from DesignSystem.swift to fix CI build)

struct DesignSystem {
    struct Colors {
        static let background = Color("AppBackground") // Fallback to system if asset not present
        static let surface = Color(NSColor.controlBackgroundColor)
        static let secondarySurface = Color(NSColor.textBackgroundColor)
        static let accent = Color.blue
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    struct Fonts {
        static let title = Font.system(size: 24, weight: .bold)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
    }
}

// MARK: - View Modifiers

struct ModernCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func modernCardStyle() -> some View {
        self.modifier(ModernCardStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Fonts.body.weight(.medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
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
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}