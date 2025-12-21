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

        // 1. Vendors (Dynamic)
        // updateVendorMenuItems will insert vendors at the beginning
        // We need a separator after vendors
        menu.addItem(NSMenuItem.separator())

        // 2. About & Settings
        let aboutItem = NSMenuItem(title: NSLocalizedString("about", comment: ""), action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let settingsItem = NSMenuItem(title: NSLocalizedString("settings", comment: ""), action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let updateItem = NSMenuItem(title: NSLocalizedString("check_for_updates_now", comment: ""), action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)
        
        menu.addItem(NSMenuItem.separator())

        // 3. Quit
        let quitItem = NSMenuItem(title: NSLocalizedString("quit", comment: ""), action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        
        // Initial population
        updateVendorMenuItems()
    }

    private func updateVendorMenuItems() {
        // Find the first separator
        guard let firstSeparator = menu.items.first(where: { $0.isSeparatorItem }) else { return }
        let separatorIndex = menu.index(of: firstSeparator)
        
        // Remove items before the first separator
        for _ in 0..<separatorIndex {
            menu.removeItem(at: 0)
        }
        
        // Insert vendors at the beginning
        insertVendors(at: 0)
    }
    
    private func insertVendors(at index: Int) {
        let vendors = ConfigManager.shared.allVendors
        let currentVendor = ConfigManager.shared.currentVendor

        for (offset, vendor) in vendors.enumerated() {
            let menuItem = NSMenuItem(
                title: vendor.displayName,
                action: #selector(switchVendor(_:)),
                keyEquivalent: ""
            )
            menuItem.state = vendor.id == currentVendor?.id ? .on : .off
            menuItem.target = self
            menuItem.tag = vendor.id.hashValue
            menu.insertItem(menuItem, at: index + offset)
        }
        
        if vendors.isEmpty {
             let noVendorsItem = NSMenuItem(title: NSLocalizedString("no_vendors", comment: ""), action: nil, keyEquivalent: "")
             noVendorsItem.isEnabled = false
             menu.insertItem(noVendorsItem, at: index)
        }
    }

    // MARK: - Menu Actions
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("about_title", comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("about_message", comment: ""),
            AppInfo.version,
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

    @objc private func checkForUpdates() {
        Task { @MainActor in
            UpdateManager.shared.checkForUpdates(isManual: true)
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
    private var currentVersion: String {
        return AppInfo.version
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