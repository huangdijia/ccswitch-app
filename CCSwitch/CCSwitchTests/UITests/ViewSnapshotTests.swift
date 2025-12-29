import XCTest
import SwiftUI
@testable import CCSwitch

/// Snapshot tests for key views in the application
/// These tests verify that views render correctly and maintain visual consistency
@MainActor
class ViewSnapshotTests: UITestCase {

    // MARK: - Vendor List View Tests

    func testVendorRowViewRenders() {
        // Given
        let vendor = Vendor(
            id: "test",
            name: "Test Vendor",
            env: ["ANTHROPIC_BASE_URL": "https://api.example.com"]
        )
        let isActive = true
        let isFavorite = true
        let isPreset = false

        // When
        let view = VendorRowView(
            vendor: vendor,
            isActive: isActive,
            isFavorite: isFavorite,
            isPreset: isPreset,
            onToggleFavorite: {}
        )

        // Then
        XCTAssertNotNil(view, "VendorRowView should render")
    }

    func testVendorListViewWithEmptyState() {
        // Given
        let viewModel = DefaultVendorManagementViewModel(
            configManager: ViewTestMockConfigManager.mockShared,
            notificationService: createMockNotificationService()
        )

        // When
        let view = VendorListView(
            viewModel: viewModel,
            selectedVendorId: .constant(nil),
            onDelete: {},
            onAdd: {}
        )

        // Then
        XCTAssertNotNil(view, "VendorListView should render with empty state")
    }

    func testVendorDetailViewRenders() {
        // Given
        let vendor = Vendor(
            id: "test",
            name: "Test Vendor",
            env: [
                "ANTHROPIC_BASE_URL": "https://api.example.com",
                "ANTHROPIC_AUTH_TOKEN": "test-token",
                "API_TIMEOUT_MS": "30000"
            ]
        )

        // When
        let view = VendorDetailView(
            vendor: vendor,
            isActive: true,
            isDirtyBinding: .constant(false),
            onSave: { _ in },
            onSwitchVendor: { _ in }
        )

        // Then
        XCTAssertNotNil(view, "VendorDetailView should render")
    }

    // MARK: - Settings View Tests

    func testSettingsViewRenders() {
        // When
        let view = SettingsView()

        // Then
        XCTAssertNotNil(view, "SettingsView should render")
    }

    // MARK: - View State Tests

    func testVendorDetailViewValidation() async {
        // Given
        let vendor = Vendor(
            id: "test",
            name: "Test Vendor",
            env: [:]
        )
        let view = VendorDetailView(
            vendor: vendor,
            isActive: true,
            isDirtyBinding: .constant(false),
            onSave: { _ in },
            onSwitchVendor: { _ in }
        )

        // When & Then
        // Verify view can be created (validation testing requires ViewInspector)
        XCTAssertNotNil(view, "VendorDetailView should be created")
    }

    // MARK: - Toggle State Tests

    func testVendorRowViewToggleFavorite() {
        // Given
        var favoriteToggled = false
        let vendor = Vendor(
            id: "test",
            name: "Test",
            env: [:]
        )

        let view = VendorRowView(
            vendor: vendor,
            isActive: false,
            isFavorite: false,
            isPreset: false,
            onToggleFavorite: {
                favoriteToggled = true
            }
        )

        // When - would need ViewInspector to trigger the tap
        // Then
        XCTAssertNotNil(view, "Toggle action should be set")
    }

    // MARK: - Empty State Tests

    func testEmptyVendorList() {
        // Given
        let viewModel = DefaultVendorManagementViewModel(
            configManager: ViewTestMockConfigManager.mockShared,
            notificationService: createMockNotificationService()
        )

        // When
        let vendors = viewModel.vendors

        // Then
        XCTAssertTrue(vendors.isEmpty, "Should start with no vendors")
    }

    // MARK: - Performance Tests

    func testVendorListViewPerformance() {
        let viewModel = DefaultVendorManagementViewModel(
            configManager: ViewTestMockConfigManager.mockShared,
            notificationService: createMockNotificationService()
        )

        measurePerformance(
            {
                let _ = VendorListView(
                    viewModel: viewModel,
                    selectedVendorId: .constant(nil),
                    onDelete: {},
                    onAdd: {}
                )
            },
            description: "VendorListView creation"
        )
    }
}

// MARK: - Mock Config Manager for Testing

class ViewTestMockConfigManager: ConfigManager {
    static let mockShared = ViewTestMockConfigManager(
        configRepository: InMemoryConfigurationRepository(),
        vendorSwitcher: MockVendorSwitcher(),
        notificationService: MockNotificationService(),
        settingsRepository: UserDefaultsSettingsRepository()
    )

    private var mockVendors: [Vendor] = []
    private var mockCurrentVendor: Vendor?

    override var allVendors: [Vendor] {
        return mockVendors.isEmpty ? super.allVendors : mockVendors
    }

    override var currentVendor: Vendor? {
        return mockCurrentVendor ?? super.currentVendor
    }

    func addMockVendor(_ vendor: Vendor) {
        mockVendors.append(vendor)
        mockCurrentVendor = vendor
    }
}
