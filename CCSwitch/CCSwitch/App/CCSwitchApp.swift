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