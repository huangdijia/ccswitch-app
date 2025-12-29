import Foundation

/// In-memory implementation of ConfigurationRepository
/// Useful for testing, previews, and temporary data handling
class InMemoryConfigurationRepository: ConfigurationRepository {
    // MARK: - Storage
    private var config: CCSConfig

    // MARK: - Initialization
    init(
        initialConfig: CCSConfig? = nil
    ) {
        if let initialConfig = initialConfig {
            self.config = initialConfig
        } else {
            self.config = CCSConfig(
                current: nil,
                vendors: [],
                favorites: [],
                presets: []
            )
        }
    }

    // MARK: - ConfigurationRepository Implementation

    func getAllVendors() throws -> [Vendor] {
        return config.vendors
    }

    func getVendor(by id: String) throws -> Vendor? {
        return config.vendors.first { $0.id == id }
    }

    func getCurrentVendor() throws -> Vendor? {
        guard let currentId = config.current else { return nil }
        return config.vendors.first { $0.id == currentId }
    }

    func setCurrentVendor(_ vendorId: String) throws {
        guard config.vendors.contains(where: { $0.id == vendorId }) else {
            throw ConfigurationError.vendorNotFound
        }
        config.current = vendorId
    }

    func addVendor(_ vendor: Vendor) throws {
        if config.vendors.contains(where: { $0.id == vendor.id }) {
            throw ConfigurationError.vendorAlreadyExists
        }
        config.vendors.append(vendor)

        // Set as current if it's the first vendor
        if config.current == nil {
            config.current = vendor.id
        }
    }

    func updateVendor(_ vendor: Vendor) throws {
        guard let index = config.vendors.firstIndex(where: { $0.id == vendor.id }) else {
            throw ConfigurationError.vendorNotFound
        }
        config.vendors[index] = vendor
    }

    func removeVendor(with vendorId: String) throws {
        guard let index = config.vendors.firstIndex(where: { $0.id == vendorId }) else {
            throw ConfigurationError.vendorNotFound
        }

        // Check if it's the last vendor
        if config.vendors.count == 1 {
            throw ConfigurationError.cannotRemoveLastVendor
        }

        // Check if it's the current vendor
        if config.current == vendorId {
            // Set current to another vendor
            config.vendors.remove(at: index)
            config.current = config.vendors.first?.id
        } else {
            config.vendors.remove(at: index)
        }
    }

    func hasConfiguration() -> Bool {
        return !config.vendors.isEmpty
    }

    func getFavorites() throws -> Set<String> {
        return Set(config.favorites ?? [])
    }

    func setFavorites(_ ids: Set<String>) throws {
        config.favorites = Array(ids)
    }

    func getPresets() throws -> Set<String> {
        return Set(config.presets ?? [])
    }

    func setPresets(_ ids: Set<String>) throws {
        config.presets = Array(ids)
    }

    // MARK: - Convenience Methods

    /// Reset the repository to empty state
    func reset() {
        config = CCSConfig(
            current: nil,
            vendors: [],
            favorites: [],
            presets: []
        )
    }

    /// Load vendors from an array
    func loadVendors(_ vendors: [Vendor]) {
        config.vendors = vendors
        if config.current == nil, let first = vendors.first {
            config.current = first.id
        }
    }

    /// Get the current configuration
    func getCurrentConfig() -> CCSConfig {
        return config
    }
}
