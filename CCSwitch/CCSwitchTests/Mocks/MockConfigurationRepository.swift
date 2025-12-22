import Foundation
@testable import CCSwitch

/// Mock implementation of ConfigurationRepository for testing
class MockConfigurationRepository: ConfigurationRepository {
    var vendors: [Vendor] = []
    var currentVendorId: String?
    
    var getAllVendorsCallCount = 0
    var addVendorCallCount = 0
    var updateVendorCallCount = 0
    var removeVendorCallCount = 0
    var shouldThrowError = false
    
    func getAllVendors() throws -> [Vendor] {
        getAllVendorsCallCount += 1
        if shouldThrowError {
            throw ConfigurationError.loadFailed
        }
        return vendors
    }
    
    func getVendor(by id: String) throws -> Vendor? {
        if shouldThrowError {
            throw ConfigurationError.vendorNotFound
        }
        return vendors.first { $0.id == id }
    }
    
    func getCurrentVendor() throws -> Vendor? {
        if shouldThrowError {
            throw ConfigurationError.loadFailed
        }
        guard let id = currentVendorId else { return nil }
        return try getVendor(by: id)
    }
    
    func setCurrentVendor(_ vendorId: String) throws {
        if shouldThrowError {
            throw ConfigurationError.vendorNotFound
        }
        guard vendors.contains(where: { $0.id == vendorId }) else {
            throw ConfigurationError.vendorNotFound
        }
        currentVendorId = vendorId
    }
    
    func addVendor(_ vendor: Vendor) throws {
        addVendorCallCount += 1
        if shouldThrowError {
            throw ConfigurationError.vendorAlreadyExists
        }
        guard !vendors.contains(where: { $0.id == vendor.id }) else {
            throw ConfigurationError.vendorAlreadyExists
        }
        vendors.append(vendor)
    }
    
    func updateVendor(_ vendor: Vendor) throws {
        updateVendorCallCount += 1
        if shouldThrowError {
            throw ConfigurationError.vendorNotFound
        }
        guard let index = vendors.firstIndex(where: { $0.id == vendor.id }) else {
            throw ConfigurationError.vendorNotFound
        }
        vendors[index] = vendor
    }
    
    func removeVendor(with vendorId: String) throws {
        removeVendorCallCount += 1
        if shouldThrowError {
            throw ConfigurationError.cannotRemoveLastVendor
        }
        guard vendors.count > 1 else {
            throw ConfigurationError.cannotRemoveLastVendor
        }
        guard vendors.contains(where: { $0.id == vendorId }) else {
            throw ConfigurationError.vendorNotFound
        }
        vendors.removeAll { $0.id == vendorId }
        if currentVendorId == vendorId {
            currentVendorId = vendors.first?.id
        }
    }
    
    func hasConfiguration() -> Bool {
        return !vendors.isEmpty
    }
    
    var favorites: Set<String> = []
    
    func getFavorites() throws -> Set<String> {
        if shouldThrowError {
            throw ConfigurationError.loadFailed
        }
        return favorites
    }
    
    func setFavorites(_ ids: Set<String>) throws {
        if shouldThrowError {
            throw ConfigurationError.saveFailed
        }
        favorites = ids
    }

    var presets: Set<String> = []
    
    func getPresets() throws -> Set<String> {
        if shouldThrowError {
            throw ConfigurationError.loadFailed
        }
        return presets
    }
    
    func setPresets(_ ids: Set<String>) throws {
        if shouldThrowError {
            throw ConfigurationError.saveFailed
        }
        presets = ids
    }
}
