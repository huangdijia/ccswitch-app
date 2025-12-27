import XCTest
@testable import CCSwitch

final class SyncManagerTests: XCTestCase {
    var mockCloud: MockCloudStorageService!
    var mockConfigManager: MockConfigManager!
    var syncManager: SyncManager!
    
    override func setUp() {
        super.setUp()
        mockCloud = MockCloudStorageService()
        mockConfigManager = MockConfigManager()
        // Pre-populate mock config with some vendors for testing
        mockConfigManager.allVendors = [
            Vendor(id: "v1", name: "Vendor 1", env: [:]),
            Vendor(id: "v2", name: "Vendor 2", env: [:])
        ]
        
        syncManager = SyncManager(cloudStorage: mockCloud, configManager: mockConfigManager)
    }
    
    func testToggleSync() {
        syncManager.toggleSync(enabled: true)
        XCTAssertTrue(syncManager.syncConfig.isSyncEnabled)
        XCTAssertTrue(mockCloud.synchronizeCalled)
    }
    
    func testUpdateSyncedVendors() {
        syncManager.toggleSync(enabled: true)
        syncManager.updateSyncedVendors(ids: ["v1", "v2"])
        XCTAssertEqual(syncManager.syncConfig.syncedVendorIds, ["v1", "v2"])
        XCTAssertTrue(mockCloud.synchronizeCalled)
    }
    
    func testUploadSelectedVendorsWhenDisabled() {
        syncManager.toggleSync(enabled: false)
        syncManager.uploadSelectedVendors()
        XCTAssertEqual(syncManager.syncStatus, .idle)
    }
    
    func testConflictDetection() throws {
        let vendorId = "v1"
        let remoteVendor = Vendor(id: vendorId, name: "Remote Name", env: [:])
        
        // Setup cloud with a conflicting vendor
        try mockCloud.setCodable(remoteVendor, forKey: "vendor_\(vendorId)")
        syncManager.syncConfig.syncedVendorIds = [vendorId]
        syncManager.syncConfig.isSyncEnabled = true
        
        // Simulate remote change
        syncManager.downloadRemoteChanges()
        
        // Check if conflicts are detected
        // Note: MockConfigManager needs to return "v1" with different data for conflict to happen
        // In setUp, v1 is "Vendor 1". Remote is "Remote Name". So they differ.
        
        XCTAssertEqual(syncManager.pendingConflicts.count, 1)
        XCTAssertEqual(syncManager.pendingConflicts.first?.id, vendorId)
    }
}

// MARK: - Mocks

class MockConfigManager: SyncConfigManagerProtocol {
    var allVendors: [Vendor] = []
    var addedVendors: [Vendor] = []
    var updatedVendors: [Vendor] = []
    
    func addVendor(_ vendor: Vendor) throws {
        addedVendors.append(vendor)
        allVendors.append(vendor)
    }
    
    func updateVendor(_ vendor: Vendor) throws {
        updatedVendors.append(vendor)
        if let index = allVendors.firstIndex(where: { $0.id == vendor.id }) {
            allVendors[index] = vendor
        }
    }
}
