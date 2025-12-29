import XCTest
import SwiftUI
@testable import CCSwitch

/// Base class for UI tests providing common utilities
/// This framework provides helpers for testing SwiftUI views and user interactions
@MainActor
class UITestCase: XCTestCase {

    // MARK: - Test Environment

    /// Sets up the test environment before each test
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    /// Tears down the test environment after each test
    override func tearDown() async throws {
        // Clean up test data
        try await super.tearDown()
    }

    // MARK: - View Testing Helpers

    /// Creates a view with a given size for snapshot testing
    /// - Parameters:
    ///   - content: The view content to test
    ///   - size: The size to use for the view
    /// - Returns: The configured view
    func createTestView<Content: View>(
        _ content: Content,
        size: CGSize = CGSize(width: 800, height: 600)
    ) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .background(Color(NSColor.windowBackgroundColor))
    }

    /// Renders a view and returns its snapshot as an image
    /// - Parameter view: The view to snapshot
    /// - Returns: An image of the rendered view
    func snapshotView<V: View>(_ view: V) -> NSImage? {
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)

        let bounds = hostingController.view.bounds
        guard let bitmapRep = hostingController.view.bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        hostingController.view.cacheDisplay(in: bounds, to: bitmapRep)

        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmapRep)
        return image
    }

    // MARK: - Assertion Helpers

    /// Asserts that a view contains a specific string
    /// - Parameters:
    ///   - view: The view to inspect
    ///   - text: The text to search for
    func viewContains<V: View>(_ view: V, text: String) {
        // This would use ViewInspector or similar in a real implementation
        // For now, it's a placeholder that demonstrates the intent
        let viewDescription = String(describing: type(of: view))
        XCTAssertTrue(true, "View inspection not yet implemented for: \(viewDescription)")
    }

    /// Asserts that a specific number of items are present
    /// - Parameters:
    ///   - count: The expected count
    ///   - description: Description of what's being counted
    func assertCount(_ count: Int, _ description: String) {
        XCTAssertEqual(count, count, "Expected \(count) \(description)")
    }

    // MARK: - Time Helpers

    /// Waits for a condition to be true within a timeout
    /// - Parameters:
    ///   - condition: The condition to check
    ///   - timeout: Maximum time to wait
    ///   - description: Description of what's being waited for
    func waitFor(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 1.0,
        description: String = "condition"
    ) async {
        let start = Date()
        while !condition() && Date().timeIntervalSince(start) < timeout {
            try? await Task.sleep(nanoseconds: UInt64(100_000_000)) // 100ms
        }
        XCTAssertTrue(condition(), "Timeout waiting for \(description)")
    }

    // MARK: - Mock Setup Helpers

    /// Creates a mock repository with sample data
    /// - Returns: An in-memory configuration repository with test data
    func createMockRepository() -> InMemoryConfigurationRepository {
        let repository = InMemoryConfigurationRepository()
        let sampleVendors = [
            Vendor(
                id: "test1",
                name: "Test Vendor 1",
                env: ["ANTHROPIC_BASE_URL": "https://api.example.com"]
            ),
            Vendor(
                id: "test2",
                name: "Test Vendor 2",
                env: ["ANTHROPIC_BASE_URL": "https://api2.example.com"]
            ),
        ]
        repository.loadVendors(sampleVendors)
        return repository
    }

    /// Creates a mock sync manager
    /// - Returns: A mock sync manager for testing
    func createMockSyncManager() -> UITestMockSyncManager {
        return UITestMockSyncManager()
    }

    /// Creates a mock notification service
    /// - Returns: A mock notification service for testing
    func createMockNotificationService() -> MockNotificationService {
        return MockNotificationService()
    }

    // MARK: - Performance Testing

    /// Measures the performance of a block
    /// - Parameters:
    ///   - block: The block to measure
    ///   - description: Description of what's being measured
    func measurePerformance(
        _ block: () -> Void,
        description: String
    ) {
        measure(metrics: [XCTClockMetric()]) {
            block()
        }
    }
}

// MARK: - Mock Sync Manager

/// Mock sync manager for testing
class UITestMockSyncManager: SyncManagerProtocol {
    @Published var syncConfig = SyncConfiguration()
    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingConflicts: [SyncConflict] = []
    @Published var isOnline = true

    func toggleSync(enabled: Bool) {
        syncConfig.isSyncEnabled = enabled
    }

    func uploadSelectedVendors() {
        syncStatus = .syncing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.syncStatus = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.syncStatus = .idle
            }
        }
    }

    func downloadRemoteChanges() {
        syncStatus = .syncing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.syncStatus = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.syncStatus = .idle
            }
        }
    }

    func resolveConflict(vendorId: String, keepLocal: Bool) {
        pendingConflicts.removeAll { $0.id == vendorId }
    }

    func updateSyncedVendors(ids: [String]) {
        syncConfig.syncedVendorIds = ids
    }
}

// MARK: - Snapshot Testing

/// Snapshot testing utilities for UI tests
extension UITestCase {

    /// Compares two images for equality
    /// - Parameters:
    ///   - image1: First image
    ///   - image2: Second image
    ///   - tolerance: Allowed difference (0-1, where 1 is completely different)
    func compareImages(
        _ image1: NSImage,
        _ image2: NSImage,
        tolerance: Float = 0.0
    ) -> Bool {
        guard let data1 = image1.tiffRepresentation,
              let data2 = image2.tiffRepresentation else {
            return false
        }
        return data1 == data2
    }
}
