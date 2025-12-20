import Cocoa

class MenuBarController: NSObject, ConfigObserver {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    override init() {
        super.init()
        setupStatusBar()
        ConfigManager.shared.addObserver(self)
        buildMenu()
    }

    deinit {
        ConfigManager.shared.removeObserver(self)
    }

    // MARK: - Setup
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // 设置图标或文字
            button.title = "CC"
            button.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)

            // 设置工具提示
            button.toolTip = "CCSwitch - Click to switch Claude provider"
        }
    }

    // MARK: - Menu Building
    private func buildMenu() {
        menu = NSMenu()

        // A 区：关于
        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: NSLocalizedString("about", comment: ""), action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(withTitle: String(format: NSLocalizedString("version", comment: ""), getVersion()), action: nil, keyEquivalent: "")

        let configDirItem = NSMenuItem(title: NSLocalizedString("open_config_dir", comment: ""), action: #selector(openConfigDirectory), keyEquivalent: "")
        configDirItem.target = self
        menu.addItem(configDirItem)

        let logsItem = NSMenuItem(title: NSLocalizedString("show_logs", comment: ""), action: #selector(showLogs), keyEquivalent: "")
        logsItem.target = self
        menu.addItem(logsItem)
        menu.addItem(NSMenuItem.separator())

        // B 区：可用供应商（动态）
        updateVendorMenuItems()
        menu.addItem(NSMenuItem.separator())

        // C 区：设置
        let settingsItem = NSMenuItem(title: NSLocalizedString("settings", comment: ""), action: #selector(showSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())

        // D 区：退出
        let quitItem = NSMenuItem(title: NSLocalizedString("quit", comment: ""), action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateVendorMenuItems() {
        // 移除旧的供应商菜单项
        let initialSeparatorIndex = menu.items.firstIndex(where: { $0.isSeparatorItem }) ?? 0
        let settingSeparatorIndex = menu.items.lastIndex(where: { $0.isSeparatorItem }) ?? menu.items.count

        // 移除中间的供应商菜单项
        if initialSeparatorIndex < settingSeparatorIndex {
            let range = (initialSeparatorIndex + 1)..<(settingSeparatorIndex)
            let vendorItems = Array(menu.items[range])
            for item in vendorItems {
                if item.action != #selector(showSettings) {
                    menu.removeItem(item)
                }
            }
        }

        // 添加供应商菜单项
        let vendors = ConfigManager.shared.allVendors
        let currentVendor = ConfigManager.shared.currentVendor

        for vendor in vendors {
            let menuItem = NSMenuItem(
                title: vendor.id == currentVendor?.id ? "✓ \(vendor.displayName)" : vendor.displayName,
                action: #selector(switchVendor(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.tag = vendor.id.hashValue // 使用 hashValue 作为 tag 来标识
            menu.insertItem(menuItem, at: initialSeparatorIndex + 1)
        }
    }

    // MARK: - Menu Actions
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("about_title", comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("about_message", comment: ""),
            getVersion(),
            CCSConfig.configFile.path,
            ClaudeSettings.configFile.path
        )
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("ok", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("open_config_dir", comment: ""))

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            openConfigDirectory()
        }
    }

    @objc private func openConfigDirectory() {
        NSWorkspace.shared.selectFile(CCSConfig.configFile.path, inFileViewerRootedAtPath: "")
    }

    @objc private func showLogs() {
        // TODO: 实现日志查看功能
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("show_logs", comment: "")
        alert.informativeText = "Log viewing is not yet implemented."
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc private func showSettings() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.showSettingsWindow()
        }
    }

    @objc private func switchVendor(_ sender: NSMenuItem) {
        let vendors = ConfigManager.shared.allVendors
        guard let vendor = vendors.first(where: { $0.id.hashValue == sender.tag }) else {
            return
        }

        do {
            try ConfigManager.shared.switchToVendor(with: vendor.id)
            updateVendorMenuItems()
            updateStatusBarTitle()
        } catch {
            showErrorAlert(title: NSLocalizedString("switch_failed", comment: ""), message: error.localizedDescription)
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Helper Methods
    private func getVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func updateStatusBarTitle() {
        guard let button = statusItem.button,
              let currentVendor = ConfigManager.shared.currentVendor else {
            return
        }

        // 可以选择显示简称或保持 CC
        let abbreviations = ["anthropic": "A", "deepseek": "D", "openai": "O"]
        let abbreviation = abbreviations[currentVendor.id] ?? "CC"
        button.title = abbreviation
        button.toolTip = "CCSwitch - Current: \(currentVendor.displayName)"
    }

    private func showErrorAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
    }

    // MARK: - ConfigObserver
    func configDidChange(_ event: ConfigEvent) {
        DispatchQueue.main.async {
            switch event {
            case .configLoaded, .vendorChanged, .vendorsUpdated:
                self.updateVendorMenuItems()
                self.updateStatusBarTitle()
            }
        }
    }
}