import Foundation
import Combine

// MARK: - Sync Status

/// Sync state enumeration
enum SyncStatus: Equatable {
    case idle
    case syncing
    case error(String)
    case success
    case offline

    /// Check if sync is currently active
    var isActive: Bool {
        if case .syncing = self { return true }
        return false
    }

    /// Check if sync is in an error state
    var hasError: Bool {
        if case .error = self { return true }
        return false
    }

    /// Get the error message if in error state
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}

// MARK: - Sync Manager Protocol

/// Protocol for sync manager operations
/// This abstraction allows for different sync strategies and improves testability
protocol SyncManagerProtocol: AnyObject, ObservableObject {
    // MARK: - Published Properties
    var syncConfig: SyncConfiguration { get set }
    var syncStatus: SyncStatus { get set }
    var pendingConflicts: [SyncConflict] { get set }
    var isOnline: Bool { get }

    // MARK: - Sync Control
    func toggleSync(enabled: Bool)
    func uploadSelectedVendors()
    func downloadRemoteChanges()

    // MARK: - Conflict Resolution
    func resolveConflict(vendorId: String, keepLocal: Bool)

    // MARK: - Configuration
    func updateSyncedVendors(ids: [String])
}

// MARK: - Supporting Types

/// Sync conflict representation
struct SyncConflict: Identifiable, Equatable {
    let id: String // Vendor ID
    let local: Vendor
    let remote: Vendor

    static func == (lhs: SyncConflict, rhs: SyncConflict) -> Bool {
        lhs.id == rhs.id &&
        lhs.local == rhs.local &&
        lhs.remote == rhs.remote
    }
}

// MARK: - Sync Configuration Extension

extension SyncConfiguration {
    /// Check if a vendor is configured for sync
    func contains(vendorId: String) -> Bool {
        return syncedVendorIds.contains(vendorId)
    }

    /// Add a vendor to sync configuration
    mutating func add(vendorId: String) {
        if !syncedVendorIds.contains(vendorId) {
            syncedVendorIds.append(vendorId)
        }
    }

    /// Remove a vendor from sync configuration
    mutating func remove(vendorId: String) {
        syncedVendorIds.removeAll { $0 == vendorId }
    }
}

// MARK: - Default Conformance

extension SyncManager: SyncManagerProtocol {
    // SyncManager already conforms to the protocol
    // This extension ensures compatibility
}

