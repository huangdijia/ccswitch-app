import XCTest
import SwiftUI
@testable import CCSwitch

/// Integration tests for end-to-end workflows
/// These tests verify that components work together correctly
@MainActor
class IntegrationTests: UITestCase {

    // MARK: - Vendor Management Integration

    func testCompleteVendorWorkflow() async throws {
        // Given - A fresh repository
        let repository = createMockRepository()
        let configManager = ViewTestMockConfigManager.mockShared
        let notificationService = createMockNotificationService()

        // When - Creating a ViewModel
        let viewModel = DefaultVendorManagementViewModel(
            configManager: configManager,
            notificationService: notificationService
        )

        // Then - Should start with no vendors
        XCTAssertTrue(viewModel.vendors.isEmpty, "Should start empty")

        // When - Adding a vendor
        let newVendor = Vendor(
            id: "integration-test-1",
            name: "Integration Test Vendor",
            env: ["ANTHROPIC_BASE_URL": "https://api.test.com"]
        )

        try viewModel.addVendor(newVendor)

        // Then - Should have one vendor
        XCTAssertEqual(viewModel.vendors.count, 1, "Should have one vendor")
        XCTAssertEqual(viewModel.vendors.first?.id, "integration-test-1")
    }

    func testVendorSwitchingWorkflow() async throws {
        // Given - A repository with multiple vendors
        let repository = createMockRepository()
        let configManager = ViewTestMockConfigManager.mockShared
        let notificationService = createMockNotificationService()
        let viewModel = DefaultVendorManagementViewModel(
            configManager: configManager,
            notificationService: notificationService
        )

        let vendor1 = Vendor(id: "v1", name: "Vendor 1", env: [:])
        let vendor2 = Vendor(id: "v2", name: "Vendor 2", env: [:])

        try viewModel.addVendor(vendor1)
        try viewModel.addVendor(vendor2)

        // When - Switching to vendor 2
        try await viewModel.switchToVendor(with: "v2")

        // Then - Current vendor should be updated
        XCTAssertEqual(viewModel.currentVendorId, "v2")
    }

    func testFavoriteToggleWorkflow() async throws {
        // Given
        let repository = createMockRepository()
        let configManager = ViewTestMockConfigManager.mockShared
        let notificationService = createMockNotificationService()
        let viewModel = DefaultVendorManagementViewModel(
            configManager: configManager,
            notificationService: notificationService
        )

        let vendor = Vendor(id: "fav-test", name: "Favorite Test", env: [:])
        try viewModel.addVendor(vendor)

        // When - Toggling favorite
        viewModel.toggleFavorite("fav-test")

        // Then - Should be marked as favorite
        XCTAssertTrue(viewModel.isFavorite("fav-test"))

        // When - Toggling again
        viewModel.toggleFavorite("fav-test")

        // Then - Should no longer be favorite
        XCTAssertFalse(viewModel.isFavorite("fav-test"))
    }

    // MARK: - Settings Integration

    func testSettingsPersistenceIntegration() async {
        // Given
        let settingsRepository = UserDefaultsSettingsRepository()
        let configManager = ViewTestMockConfigManager.mockShared
        let syncManager = createMockSyncManager()
        let updateManager = UpdateManager.shared
        let notificationService = createMockNotificationService()

        let viewModel = DefaultSettingsViewModel(
            settingsRepository: settingsRepository,
            configManager: configManager,
            syncManager: syncManager,
            updateManager: updateManager,
            notificationService: notificationService
        )

        // When - Changing a setting
        viewModel.showSwitchNotification = false

        // Then - Setting should persist
        XCTAssertEqual(settingsRepository.getBool(for: .showSwitchNotification), false)
    }

    // MARK: - Sync Integration

    func testSyncToggleIntegration() async {
        // Given
        let settingsRepository = UserDefaultsSettingsRepository()
        let configManager = ViewTestMockConfigManager.mockShared
        let syncManager = createMockSyncManager()
        let updateManager = UpdateManager.shared
        let notificationService = createMockNotificationService()

        let viewModel = DefaultSettingsViewModel(
            settingsRepository: settingsRepository,
            configManager: configManager,
            syncManager: syncManager,
            updateManager: updateManager,
            notificationService: notificationService
        )

        // When - Enabling sync
        viewModel.isSyncEnabled = true

        // Then - Sync manager should be updated
        XCTAssertTrue(syncManager.syncConfig.isSyncEnabled)
    }

    // MARK: - Notification Integration

    func testNotificationIntegration() async throws {
        // Given
        let repository = createMockRepository()
        let configManager = ViewTestMockConfigManager.mockShared
        let mockNotificationService = MockNotificationService()
        let viewModel = DefaultVendorManagementViewModel(
            configManager: configManager,
            notificationService: mockNotificationService
        )

        let vendor = Vendor(id: "notif-test", name: "Notif Test", env: [:])
        try viewModel.addVendor(vendor)

        // When - Duplicating a vendor
        try viewModel.duplicateVendor(vendor)

        // Then - Notification should be sent
        XCTAssertTrue(mockNotificationService.lastNotifyTitle.isEmpty, "Title should be empty for duplicate")
        XCTAssertFalse(mockNotificationService.lastNotifyMessage.isEmpty, "Message should not be empty")
    }

    // MARK: - View Integration

    func testVendorListViewIntegration() async throws {
        // Given - A ViewModel with vendors
        let configManager = ViewTestMockConfigManager.mockShared
        let notificationService = createMockNotificationService()
        let viewModel = DefaultVendorManagementViewModel(
            configManager: configManager,
            notificationService: notificationService
        )

        let vendor1 = Vendor(id: "view-test-1", name: "View Test 1", env: [:])
        let vendor2 = Vendor(id: "view-test-2", name: "View Test 2", env: [:])
        try viewModel.addVendor(vendor1)
        try viewModel.addVendor(vendor2)

        // When - Creating a list view
        let listView = VendorListView(
            viewModel: viewModel,
            selectedVendorId: .constant(nil),
            onDelete: {},
            onAdd: {}
        )

        // Then - View should be created without errors
        XCTAssertNotNil(listView)
        XCTAssertEqual(viewModel.vendors.count, 2)
    }

    func testVendorDetailViewIntegration() async {
        // Given
        let vendor = Vendor(
            id: "detail-test",
            name: "Detail Test",
            env: [
                "ANTHROPIC_BASE_URL": "https://api.example.com",
                "ANTHROPIC_AUTH_TOKEN": "test-token"
            ]
        )

        // When - Creating a detail view
        let detailView = VendorDetailView(
            vendor: vendor,
            isActive: true,
            isDirtyBinding: .constant(false),
            onSave: { _ in },
            onSwitchVendor: { _ in }
        )

        // Then - View should be created
        XCTAssertNotNil(detailView)
    }

    // MARK: - Error Handling Integration

    func testDuplicateVendorIdHandling() async throws {
        // Given
        let configManager = ViewTestMockConfigManager.mockShared
        let notificationService = createMockNotificationService()
        let viewModel = DefaultVendorManagementViewModel(
            configManager: configManager,
            notificationService: notificationService
        )

        let vendor = Vendor(id: "dup-test", name: "Duplicate Test", env: [:])
        try viewModel.addVendor(vendor)

        // When - Trying to add duplicate
        var errorThrown = false
        do {
            try viewModel.addVendor(vendor)
        } catch {
            errorThrown = true
        }

        // Then - Should throw an error
        XCTAssertTrue(errorThrown, "Should throw error for duplicate vendor")
    }

    func testDeleteLastVendorHandling() async throws {
        // Given
        let configManager = ViewTestMockConfigManager.mockShared
        let notificationService = createMockNotificationService()
        let viewModel = DefaultVendorManagementViewModel(
            configManager: configManager,
            notificationService: notificationService
        )

        let vendor = Vendor(id: "last-test", name: "Last Test", env: [:])
        try viewModel.addVendor(vendor)

        // When - Trying to delete last vendor
        var errorThrown = false
        do {
            try viewModel.removeVendor(with: "last-test")
        } catch {
            errorThrown = true
        }

        // Then - Should throw an error
        XCTAssertTrue(errorThrown, "Should throw error when deleting last vendor")
    }

    // MARK: - Performance Integration

    func testLargeVendorListPerformance() async throws {
        // Given
        let configManager = ViewTestMockConfigManager.mockShared
        let notificationService = createMockNotificationService()
        let viewModel = DefaultVendorManagementViewModel(
            configManager: configManager,
            notificationService: notificationService
        )

        // When - Adding many vendors
        measurePerformance(
            {
                for i in 0..<100 {
                    let vendor = Vendor(
                        id: "perf-test-\(i)",
                        name: "Performance Test \(i)",
                        env: ["ANTHROPIC_BASE_URL": "https://api\(i).example.com"]
                    )
                    try? viewModel.addVendor(vendor)
                }
            },
            description: "Adding 100 vendors"
        )

        // Then - Should have all vendors
        XCTAssertEqual(viewModel.vendors.count, 100)
    }
}

// MARK: - Mock Notification Service for Testing

class MockNotificationService: NotificationService {
    var lastNotifyTitle = ""
    var lastNotifyMessage = ""
    var notificationCallCount = 0

    var lastNotification: (title: String, message: String)? {
        if notificationCallCount > 0 {
            return (lastNotifyTitle, lastNotifyMessage)
        }
        return nil
    }

    func notify(title: String, message: String) {
        notificationCallCount += 1
        lastNotifyTitle = title
        lastNotifyMessage = message
    }

    func requestPermission() {
        // Mock implementation
    }

    var hasPermission: Bool {
        return true
    }
}
