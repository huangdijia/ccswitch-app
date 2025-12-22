import XCTest
@testable import CCSwitch

final class ConfigManagerTests: XCTestCase {
    var mockRepository: MockConfigurationRepository!
    var mockSettingsWriter: MockSettingsWriter!
    var mockBackupService: MockBackupService!
    var mockNotificationService: MockNotificationService!
    var mockSettingsRepository: MockSettingsRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockConfigurationRepository()
        mockSettingsWriter = MockSettingsWriter()
        mockBackupService = MockBackupService()
        mockNotificationService = MockNotificationService()
        mockSettingsRepository = MockSettingsRepository()
        
        // Setup default test data
        mockRepository.vendors = [
            Vendor(id: "test1", name: "Test Vendor 1", env: ["KEY1": "VALUE1"]),
            Vendor(id: "test2", name: "Test Vendor 2", env: ["KEY2": "VALUE2"])
        ]
        mockRepository.currentVendorId = "test1"
    }
    
    override func tearDown() {
        mockRepository = nil
        mockSettingsWriter = nil
        mockBackupService = nil
        mockNotificationService = nil
        mockSettingsRepository = nil
        super.tearDown()
    }
    
    // MARK: - Vendor Retrieval Tests
    
    func testGetAllVendors() throws {
        let vendors = try mockRepository.getAllVendors()
        XCTAssertEqual(vendors.count, 2)
        XCTAssertEqual(vendors[0].id, "test1")
        XCTAssertEqual(vendors[1].id, "test2")
    }
    
    func testGetVendorById() throws {
        let vendor = try mockRepository.getVendor(by: "test1")
        XCTAssertNotNil(vendor)
        XCTAssertEqual(vendor?.id, "test1")
        XCTAssertEqual(vendor?.name, "Test Vendor 1")
    }
    
    func testGetNonExistentVendor() throws {
        let vendor = try mockRepository.getVendor(by: "nonexistent")
        XCTAssertNil(vendor)
    }
    
    func testGetCurrentVendor() throws {
        let vendor = try mockRepository.getCurrentVendor()
        XCTAssertNotNil(vendor)
        XCTAssertEqual(vendor?.id, "test1")
    }
    
    // MARK: - Vendor Management Tests
    
    func testAddVendor() throws {
        let newVendor = Vendor(id: "test3", name: "Test Vendor 3", env: ["KEY3": "VALUE3"])
        try mockRepository.addVendor(newVendor)
        
        XCTAssertEqual(mockRepository.addVendorCallCount, 1)
        XCTAssertEqual(mockRepository.vendors.count, 3)
        
        let addedVendor = try mockRepository.getVendor(by: "test3")
        XCTAssertNotNil(addedVendor)
        XCTAssertEqual(addedVendor?.name, "Test Vendor 3")
    }
    
    func testAddDuplicateVendor() {
        let duplicateVendor = Vendor(id: "test1", name: "Duplicate", env: [:])
        
        XCTAssertThrowsError(try mockRepository.addVendor(duplicateVendor)) { error in
            XCTAssertTrue(error is ConfigurationError)
        }
    }
    
    func testUpdateVendor() throws {
        let updatedVendor = Vendor(id: "test1", name: "Updated Name", env: ["UPDATED": "VALUE"])
        try mockRepository.updateVendor(updatedVendor)
        
        XCTAssertEqual(mockRepository.updateVendorCallCount, 1)
        
        let vendor = try mockRepository.getVendor(by: "test1")
        XCTAssertEqual(vendor?.name, "Updated Name")
        XCTAssertEqual(vendor?.env["UPDATED"], "VALUE")
    }
    
    func testUpdateNonExistentVendor() {
        let nonExistentVendor = Vendor(id: "nonexistent", name: "Test", env: [:])
        
        XCTAssertThrowsError(try mockRepository.updateVendor(nonExistentVendor)) { error in
            XCTAssertTrue(error is ConfigurationError)
        }
    }
    
    func testRemoveVendor() throws {
        try mockRepository.removeVendor(with: "test2")
        
        XCTAssertEqual(mockRepository.removeVendorCallCount, 1)
        XCTAssertEqual(mockRepository.vendors.count, 1)
        
        let vendor = try mockRepository.getVendor(by: "test2")
        XCTAssertNil(vendor)
    }
    
    func testRemoveLastVendor() throws {
        // Remove one vendor first to have only one left
        try mockRepository.removeVendor(with: "test2")
        
        // Try to remove the last one
        XCTAssertThrowsError(try mockRepository.removeVendor(with: "test1")) { error in
            XCTAssertTrue(error is ConfigurationError)
        }
    }
    
    func testRemoveCurrentVendor() throws {
        try mockRepository.removeVendor(with: "test1")
        
        // Current vendor should be switched to the remaining one
        let currentVendor = try mockRepository.getCurrentVendor()
        XCTAssertEqual(currentVendor?.id, "test2")
    }
    
    // MARK: - Vendor Switching Tests
    
    func testSwitchVendor() throws {
        // Mock setting for auto backup (default is usually false in mock unless set)
        mockSettingsRepository.setBool(true, for: .autoBackup)

        let switcher = DefaultVendorSwitcher(
            configRepository: mockRepository,
            settingsWriter: mockSettingsWriter,
            backupService: mockBackupService,
            notificationService: mockNotificationService,
            settingsRepository: mockSettingsRepository
        )
        
        try switcher.switchToVendor(with: "test2")
        
        XCTAssertEqual(mockRepository.currentVendorId, "test2")
        XCTAssertEqual(mockSettingsWriter.writeCallCount, 1)
        XCTAssertEqual(mockSettingsWriter.lastWrittenSettings?["KEY2"], "VALUE2")
        XCTAssertEqual(mockBackupService.backupCallCount, 1)
        XCTAssertNotNil(mockNotificationService.lastNotification)
    }

    func testSwitchVendorWithBackupDisabled() throws {
        // Disable auto backup
        mockSettingsRepository.setBool(false, for: .autoBackup)
        
        let switcher = DefaultVendorSwitcher(
            configRepository: mockRepository,
            settingsWriter: mockSettingsWriter,
            backupService: mockBackupService,
            notificationService: mockNotificationService,
            settingsRepository: mockSettingsRepository
        )
        
        try switcher.switchToVendor(with: "test2")
        
        XCTAssertEqual(mockRepository.currentVendorId, "test2")
        // Should write settings but NOT backup
        XCTAssertEqual(mockSettingsWriter.writeCallCount, 1)
        XCTAssertEqual(mockBackupService.backupCallCount, 0)
    }
    
    func testSwitchToNonExistentVendor() {
        let switcher = DefaultVendorSwitcher(
            configRepository: mockRepository,
            settingsWriter: mockSettingsWriter
        )
        
        XCTAssertThrowsError(try switcher.switchToVendor(with: "nonexistent")) { error in
            XCTAssertTrue(error is VendorSwitcherError)
        }
    }
    
    // MARK: - Configuration State Tests
    
    func testHasConfiguration() {
        XCTAssertTrue(mockRepository.hasConfiguration())
        
        mockRepository.vendors.removeAll()
        XCTAssertFalse(mockRepository.hasConfiguration())
    }
    
    func testSetCurrentVendor() throws {
        try mockRepository.setCurrentVendor("test2")
        XCTAssertEqual(mockRepository.currentVendorId, "test2")
        
        let currentVendor = try mockRepository.getCurrentVendor()
        XCTAssertEqual(currentVendor?.id, "test2")
    }
}
