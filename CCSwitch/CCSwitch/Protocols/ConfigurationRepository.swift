import Foundation

/// Protocol for configuration data access
/// This abstraction allows for different storage backends and improves testability
protocol ConfigurationRepository {
    /// Load all vendors from configuration
    /// - Returns: Array of all configured vendors
    /// - Throws: Error if loading fails
    func getAllVendors() throws -> [Vendor]
    
    /// Get a specific vendor by ID
    /// - Parameter id: The vendor's unique identifier
    /// - Returns: The vendor if found, nil otherwise
    /// - Throws: Error if retrieval fails
    func getVendor(by id: String) throws -> Vendor?
    
    /// Get the currently active vendor
    /// - Returns: The current vendor if set, nil otherwise
    /// - Throws: Error if retrieval fails
    func getCurrentVendor() throws -> Vendor?
    
    /// Set the current vendor
    /// - Parameter vendorId: The ID of the vendor to set as current
    /// - Throws: Error if setting fails
    func setCurrentVendor(_ vendorId: String) throws
    
    /// Add a new vendor
    /// - Parameter vendor: The vendor to add
    /// - Throws: Error if the vendor already exists or saving fails
    func addVendor(_ vendor: Vendor) throws
    
    /// Update an existing vendor
    /// - Parameter vendor: The vendor with updated data
    /// - Throws: Error if the vendor doesn't exist or saving fails
    func updateVendor(_ vendor: Vendor) throws
    
    /// Remove a vendor
    /// - Parameter vendorId: The ID of the vendor to remove
    /// - Throws: Error if the vendor doesn't exist or is the last one
    func removeVendor(with vendorId: String) throws
    
    /// Check if configuration exists
    /// - Returns: true if configuration is loaded, false otherwise
    func hasConfiguration() -> Bool
    
    /// Get favorite vendor IDs
    /// - Returns: Set of favorite vendor IDs
    /// - Throws: Error if retrieval fails
    func getFavorites() throws -> Set<String>
    
    /// Set favorite vendor IDs
    /// - Parameter ids: Set of favorite vendor IDs
    /// - Throws: Error if saving fails
    func setFavorites(_ ids: Set<String>) throws
}

/// Default implementation using CCSConfig file storage
class FileConfigurationRepository: ConfigurationRepository {
    private var config: CCSConfig?
    private let configURL: URL
    private let fileManager: FileManager
    
    init(
        configURL: URL = CCSConfig.configFile,
        fileManager: FileManager = .default
    ) {
        self.configURL = configURL
        self.fileManager = fileManager
    }
    
    func loadConfiguration() throws {
        if !fileManager.fileExists(atPath: configURL.path) {
            // First launch: sync presets to vendors.json
            let presets = CCSConfig.loadPresets()
            if !presets.isEmpty {
                config = CCSConfig(current: presets.first?.id, vendors: presets, favorites: [])
            } else {
                config = CCSConfig.createDefault()
            }
            try saveConfiguration()
            return
        }
        
        guard let loadedConfig = CCSConfig.loadFromFile(url: configURL) else {
            throw ConfigurationError.loadFailed
        }
        
        config = loadedConfig
    }
    
    func getAllVendors() throws -> [Vendor] {
        try ensureConfigLoaded()
        return config?.vendors ?? []
    }
    
    func getVendor(by id: String) throws -> Vendor? {
        try ensureConfigLoaded()
        return config?.vendors.first { $0.id == id }
    }
    
    func getCurrentVendor() throws -> Vendor? {
        try ensureConfigLoaded()
        guard let currentId = config?.current else { return nil }
        return try getVendor(by: currentId)
    }
    
    func setCurrentVendor(_ vendorId: String) throws {
        try ensureConfigLoaded()
        guard config?.vendors.contains(where: { $0.id == vendorId }) == true else {
            throw ConfigurationError.vendorNotFound
        }
        config?.current = vendorId
        try saveConfiguration()
    }
    
    func addVendor(_ vendor: Vendor) throws {
        try ensureConfigLoaded()
        guard config?.vendors.contains(where: { $0.id == vendor.id }) == false else {
            throw ConfigurationError.vendorAlreadyExists
        }
        config?.vendors.append(vendor)
        try saveConfiguration()
    }
    
    func updateVendor(_ vendor: Vendor) throws {
        try ensureConfigLoaded()
        guard let index = config?.vendors.firstIndex(where: { $0.id == vendor.id }) else {
            throw ConfigurationError.vendorNotFound
        }
        
        // When a vendor is updated (e.g. user adds Auth Token), it's no longer a "Recommended" preset
        var updatedVendor = vendor
        updatedVendor.isPreset = false
        
        config?.vendors[index] = updatedVendor
        try saveConfiguration()
    }
    
    func removeVendor(with vendorId: String) throws {
        try ensureConfigLoaded()
        guard let vendors = config?.vendors, vendors.count > 1 else {
            throw ConfigurationError.cannotRemoveLastVendor
        }
        guard vendors.contains(where: { $0.id == vendorId }) else {
            throw ConfigurationError.vendorNotFound
        }
        
        config?.vendors.removeAll { $0.id == vendorId }
        
        // If we removed the current vendor, switch to the first available
        if config?.current == vendorId {
            config?.current = config?.vendors.first?.id
        }
        
        try saveConfiguration()
    }
    
    func hasConfiguration() -> Bool {
        return config != nil
    }
    
    func getFavorites() throws -> Set<String> {
        try ensureConfigLoaded()
        return Set(config?.favorites ?? [])
    }
    
    func setFavorites(_ ids: Set<String>) throws {
        try ensureConfigLoaded()
        config?.favorites = Array(ids)
        try saveConfiguration()
    }
    
    // MARK: - Private Methods
    
    private func ensureConfigLoaded() throws {
        if config == nil {
            try loadConfiguration()
        }
    }
    
    private func saveConfiguration() throws {
        guard let config = config else {
            throw ConfigurationError.configNotLoaded
        }
        
        try CCSConfig.ensureConfigDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try encoder.encode(config)
        try data.write(to: configURL)
    }
}

/// Errors related to configuration operations
enum ConfigurationError: Error, LocalizedError {
    /// Failed to load configuration from storage
    case loadFailed
    /// Configuration has not been loaded yet
    case configNotLoaded
    /// The specified vendor was not found
    case vendorNotFound
    /// The vendor already exists
    case vendorAlreadyExists
    /// Cannot remove the last remaining vendor
    case cannotRemoveLastVendor
    /// Failed to save configuration to storage
    case saveFailed
    /// The requested operation is not supported
    case operationNotSupported
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return NSLocalizedString("config_load_failed", comment: "")
        case .configNotLoaded:
            return NSLocalizedString("config_not_loaded", comment: "")
        case .vendorNotFound:
            return NSLocalizedString("vendor_not_found", comment: "")
        case .vendorAlreadyExists:
            return NSLocalizedString("vendor_already_exists", comment: "")
        case .cannotRemoveLastVendor:
            return NSLocalizedString("cannot_remove_last_vendor", comment: "")
        case .saveFailed:
            return NSLocalizedString("config_save_failed", comment: "")
        case .operationNotSupported:
            return NSLocalizedString("operation_not_supported", comment: "")
        }
    }
}
