import Foundation

/// Protocol for vendor switching operations
/// This abstraction allows for different switching strategies and improves testability
protocol VendorSwitcher {
    /// Switch to a vendor with the specified ID
    /// - Parameter vendorId: The unique identifier of the vendor to switch to
    /// - Throws: Error if switching fails
    func switchToVendor(with vendorId: String) throws
    
    /// Get the currently active vendor
    /// - Returns: The current vendor, or nil if none is active
    func getCurrentVendor() -> Vendor?
}

/// Default implementation of VendorSwitcher
class DefaultVendorSwitcher: VendorSwitcher {
    private let configRepository: ConfigurationRepository
    private let settingsWriter: SettingsWriter
    private let backupService: BackupService?
    private let notificationService: NotificationService?
    
    init(
        configRepository: ConfigurationRepository,
        settingsWriter: SettingsWriter,
        backupService: BackupService? = nil,
        notificationService: NotificationService? = nil
    ) {
        self.configRepository = configRepository
        self.settingsWriter = settingsWriter
        self.backupService = backupService
        self.notificationService = notificationService
    }
    
    func switchToVendor(with vendorId: String) throws {
        guard let vendor = try configRepository.getVendor(by: vendorId) else {
            throw VendorSwitcherError.vendorNotFound
        }
        
        // Backup current settings if enabled
        if let backupService = backupService {
            try? backupService.backupCurrentSettings()
        }
        
        // Write new settings
        try settingsWriter.writeSettings(vendor.env)
        
        // Update current vendor in config
        try configRepository.setCurrentVendor(vendorId)
        
        // Send notification if available
        notificationService?.notify(
            title: NSLocalizedString("vendor_switched", comment: ""),
            message: String(format: NSLocalizedString("switched_to_vendor", comment: ""), vendor.name)
        )
        
        Logger.shared.logVendorSwitch(from: getCurrentVendor()?.id, to: vendorId)
    }
    
    func getCurrentVendor() -> Vendor? {
        return try? configRepository.getCurrentVendor()
    }
}

/// Errors that can occur during vendor switching
enum VendorSwitcherError: Error, LocalizedError {
    case vendorNotFound
    case switchingFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .vendorNotFound:
            return NSLocalizedString("vendor_not_found", comment: "")
        case .switchingFailed(let error):
            return String(format: NSLocalizedString("switching_failed_with_error", comment: ""), error.localizedDescription)
        }
    }
}
