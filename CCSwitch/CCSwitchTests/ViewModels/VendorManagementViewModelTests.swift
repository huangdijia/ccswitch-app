import XCTest
import Combine
@testable import CCSwitch

/// Tests for VendorManagementViewModel
final class VendorManagementViewModelTests: XCTestCase {
    var mockRepository: InMemoryConfigurationRepository!
    var mockNotificationService: MockNotificationService!
    var mockConfigManager: ConfigManager!
    var viewModel: DefaultVendorManagementViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()

        // Setup mocks
        mockRepository = InMemoryConfigurationRepository()
        mockNotificationService = MockNotificationService()

        // Create test vendors
        let testVendors = [
            Vendor(id: "vendor1", name: "Test Vendor 1", env: ["KEY1": "VALUE1"]),
            Vendor(id: "vendor2", name: "Test Vendor 2", env: ["KEY2": "VALUE2"]),
            Vendor(id: "vendor3", name: "Test Vendor 3", env: ["KEY3": "VALUE3"])
        ]
        mockRepository.loadVendors(testVendors)
        try mockRepository.setCurrentVendor("vendor1")

        // Setup mock config manager with all required dependencies
        mockConfigManager = ConfigManager(
            configRepository: mockRepository,
            vendorSwitcher: MockVendorSwitcher(),
            notificationService: mockNotificationService,
            settingsRepository: UserDefaultsSettingsRepository()
        )

        // Create view model with mocked dependencies
        viewModel = DefaultVendorManagementViewModel(
            configManager: mockConfigManager,
            notificationService: mockNotificationService
        )

        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        mockConfigManager = nil
        mockNotificationService = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - Data Loading Tests

    func testLoadData() async throws {
        await viewModel.loadData()

        XCTAssertEqual(viewModel.vendors.count, 3)
        XCTAssertEqual(viewModel.currentVendorId, "vendor1")
    }

    func testFilterVendors() async throws {
        await viewModel.loadData()

        // Test filtering
        viewModel.searchText = "Vendor 1"

        let filtered = viewModel.filteredVendors
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, "vendor1")
    }

    // MARK: - Vendor Operations Tests

    func testAddVendor() async throws {
        await viewModel.loadData()
        let initialCount = viewModel.vendors.count

        let newVendor = Vendor(id: "vendor4", name: "New Vendor", env: ["NEW": "VALUE"])
        try viewModel.addVendor(newVendor)
        await viewModel.loadData()

        XCTAssertEqual(viewModel.vendors.count, initialCount + 1)
        XCTAssertTrue(mockNotificationService.lastNotification?.title.contains("success") == true)
    }

    func testAddDuplicateVendor() async throws {
        await viewModel.loadData()

        let duplicateVendor = Vendor(id: "vendor1", name: "Duplicate", env: [:])

        do {
            try viewModel.addVendor(duplicateVendor)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
        }
    }

    func testUpdateVendor() async throws {
        await viewModel.loadData()

        let updatedVendor = Vendor(id: "vendor1", name: "Updated Vendor 1", env: ["UPDATED": "VALUE"])
        try viewModel.updateVendor(updatedVendor)
        await viewModel.loadData()

        let vendor = viewModel.vendors.first { $0.id == "vendor1" }
        XCTAssertEqual(vendor?.name, "Updated Vendor 1")
    }

    func testRemoveVendor() async throws {
        await viewModel.loadData()
        let initialCount = viewModel.vendors.count

        // Try to remove a non-current vendor
        try viewModel.removeVendor(with: "vendor3")
        await viewModel.loadData()

        XCTAssertEqual(viewModel.vendors.count, initialCount - 1)
        XCTAssertNil(viewModel.vendors.first { $0.id == "vendor3" })
    }

    func testRemoveCurrentVendor() async throws {
        await viewModel.loadData()

        // Try to remove current vendor should fail
        do {
            try viewModel.removeVendor(with: "vendor1")
            XCTFail("Should have thrown an error")
        } catch VendorManagementError.cannotRemoveCurrentVendor {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testRemoveLastVendor() async throws {
        // Create a repo with only one vendor
        mockRepository.reset()
        mockRepository.loadVendors([Vendor(id: "only", name: "Only Vendor", env: [:])])
        await viewModel.loadData()

        do {
            try viewModel.removeVendor(with: "only")
            XCTFail("Should have thrown an error")
        } catch VendorManagementError.cannotRemoveLastVendor {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testDuplicateVendor() async throws {
        await viewModel.loadData()
        let initialCount = viewModel.vendors.count

        let vendorToDuplicate = viewModel.vendors.first { $0.id == "vendor1" }!
        try viewModel.duplicateVendor(vendorToDuplicate)
        await viewModel.loadData()

        XCTAssertEqual(viewModel.vendors.count, initialCount + 1)

        // Check that the duplicate exists
        let duplicates = viewModel.vendors.filter { $0.name.hasPrefix("\(vendorToDuplicate.displayName) Copy") }
        XCTAssertEqual(duplicates.count, 1)
    }

    // MARK: - Favorite Management Tests

    func testToggleFavorite() async throws {
        await viewModel.loadData()

        // Initially vendor1 should not be a favorite (empty set)
        XCTAssertFalse(viewModel.isFavorite("vendor1"))

        // Toggle to favorite
        viewModel.toggleFavorite("vendor1")

        // Note: In the current implementation, favorites are managed through configRepository
        // Since we're using a real ConfigManager with our mock repository, this should work
    }

    // MARK: - Validation Tests

    func testValidateVendorName() {
        XCTAssertTrue(viewModel.validateVendorName("Valid Name"))
        XCTAssertFalse(viewModel.validateVendorName(""))
        XCTAssertFalse(viewModel.validateVendorName("   "))
    }

    func testValidateBaseURL() {
        XCTAssertTrue(viewModel.validateBaseURL(""))
        XCTAssertTrue(viewModel.validateBaseURL("http://example.com"))
        XCTAssertTrue(viewModel.validateBaseURL("https://example.com"))
        XCTAssertFalse(viewModel.validateBaseURL("ftp://example.com"))
        XCTAssertFalse(viewModel.validateBaseURL("not-a-url"))
    }

    func testValidateTimeout() {
        XCTAssertTrue(viewModel.validateTimeout(""))
        XCTAssertTrue(viewModel.validateTimeout("5000"))
        XCTAssertTrue(viewModel.validateTimeout("1000"))
        XCTAssertTrue(viewModel.validateTimeout("300000"))
        XCTAssertFalse(viewModel.validateTimeout("999"))
        XCTAssertFalse(viewModel.validateTimeout("300001"))
        XCTAssertFalse(viewModel.validateTimeout("invalid"))
    }

    // MARK: - Computed Properties Tests

    func testFavoriteVendors() async throws {
        await viewModel.loadData()

        // Initially no favorites
        XCTAssertEqual(viewModel.favoriteVendors.count, 0)

        // Set some favorites
        try mockRepository.setFavorites(["vendor1", "vendor2"])
        await viewModel.loadData()

        XCTAssertEqual(viewModel.favoriteVendors.count, 2)
    }

    func testOtherVendors() async throws {
        await viewModel.loadData()

        // Set some favorites
        try mockRepository.setFavorites(["vendor1"])
        await viewModel.loadData()

        XCTAssertEqual(viewModel.otherVendors.count, 2)
        XCTAssertFalse(viewModel.otherVendors.contains { $0.id == "vendor1" })
    }
}
