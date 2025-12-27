import Foundation
import Combine
import Network

class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    @Published var syncConfig = SyncConfiguration()
    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingConflicts: [SyncConflict] = []
    @Published var isOnline = true
    
    struct SyncConflict: Identifiable {
        let id: String // Vendor ID
        let local: Vendor
        let remote: Vendor
    }
    
    private let cloudStorage: CloudStorageService
    private let configManager: SyncConfigManagerProtocol
    private let monitor = NWPathMonitor()
    private var cancellables = Set<AnyCancellable>()
    
    private let syncConfigKey = "sync_configuration"
    private let vendorsKeyPrefix = "vendor_"
    
    private var retryCount = 0
    private let maxRetries = 3
    
    init(
        cloudStorage: CloudStorageService? = nil,
        configManager: SyncConfigManagerProtocol = ConfigManager.shared
    ) {
        self.cloudStorage = cloudStorage ?? ICloudStorageService()
        self.configManager = configManager
        
        loadSyncConfig()
        setupObservers()
        setupNetworkMonitor()
    }
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case error(String)
        case success
        case offline
    }
    
    // MARK: - Initialization
    
    private func setupObservers() {
        // Listen for local changes
        NotificationCenter.default.publisher(for: .configDidChange)
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleLocalChange()
            }
            .store(in: &cancellables)
        
        // Listen for remote changes
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleRemoteChange(notification)
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let online = path.status == .satisfied
                if online && !(self?.isOnline ?? true) {
                    // Transitioned from offline to online
                    self?.handleBackOnline()
                }
                self?.isOnline = online
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    private func loadSyncConfig() {
        do {
            if let config = try cloudStorage.objectCodable(SyncConfiguration.self, forKey: syncConfigKey) {
                self.syncConfig = config
            }
        } catch {
            Logger.shared.error("Failed to load sync configuration from cloud: \(error)")
        }
    }
    
    // MARK: - Local Changes
    
    private func handleLocalChange() {
        guard syncConfig.isSyncEnabled else { return }
        uploadSelectedVendors()
    }
    
    private func handleBackOnline() {
        if syncConfig.isSyncEnabled {
            uploadSelectedVendors()
        }
    }
    
    func uploadSelectedVendors() {
        guard syncConfig.isSyncEnabled else { return }
        guard isOnline else {
            syncStatus = .offline
            return
        }
        
        syncStatus = .syncing
        
        // Always sync ALL vendors
        let vendors = configManager.allVendors
        
        // Update config to track all vendors
        // We use map to get fresh IDs in case vendors were added/removed locally
        syncConfig.syncedVendorIds = vendors.map { $0.id }
        
        do {
            for vendor in vendors {
                try cloudStorage.setCodable(vendor, forKey: "\(vendorsKeyPrefix)\(vendor.id)")
            }
            // Also sync the config itself
            try cloudStorage.setCodable(syncConfig, forKey: syncConfigKey)
            
            let success = cloudStorage.synchronize()
            if !success {
                Logger.shared.warn("Cloud storage synchronization to disk returned false")
            }
            
            // Treat as success regardless of disk sync status
            syncStatus = .success
            retryCount = 0
            
            // Reset to idle after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if case .success = self.syncStatus {
                    self.syncStatus = .idle
                }
            }
        } catch {
            handleSyncFailure(error: error.localizedDescription)
        }
    }
    
    private func handleSyncFailure(error: String) {
        if retryCount < maxRetries {
            retryCount += 1
            let delay = Double(retryCount * retryCount) // Exponential backoff
            Logger.shared.warn("Sync failed, retrying in \(delay) seconds... (Attempt \(retryCount))")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.uploadSelectedVendors()
            }
        } else {
            syncStatus = .error(error)
            retryCount = 0
        }
    }
    
    // MARK: - Remote Changes
    
    private func handleRemoteChange(_ notification: Notification) {
        guard syncConfig.isSyncEnabled else { return }
        downloadRemoteChanges()
    }
    
    func downloadRemoteChanges() {
        guard isOnline else { return }
        
        syncStatus = .syncing
        
        // Reload sync config from cloud first
        loadSyncConfig()
        
        var conflicts: [SyncConflict] = []
        
        for vendorId in syncConfig.syncedVendorIds {
            do {
                if let remoteVendor = try cloudStorage.objectCodable(Vendor.self, forKey: "\(vendorsKeyPrefix)\(vendorId)") {
                    if let localVendor = configManager.allVendors.first(where: { $0.id == vendorId }) {
                        if localVendor != remoteVendor {
                            conflicts.append(SyncConflict(id: vendorId, local: localVendor, remote: remoteVendor))
                        }
                    } else {
                        // New vendor from cloud, auto-import it
                        try configManager.addVendor(remoteVendor)
                    }
                }
            } catch {
                Logger.shared.error("Failed to download remote vendor \(vendorId): \(error)")
            }
        }
        
        self.pendingConflicts = conflicts
        
        if conflicts.isEmpty {
            syncStatus = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if case .success = self.syncStatus {
                    self.syncStatus = .idle
                }
            }
        } else {
            syncStatus = .idle // Conflicts will be handled by UI
        }
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict(vendorId: String, keepLocal: Bool) {
        guard let conflict = pendingConflicts.first(where: { $0.id == vendorId }) else { return }
        
        do {
            if keepLocal {
                // Upload local to cloud
                try cloudStorage.setCodable(conflict.local, forKey: "\(vendorsKeyPrefix)\(vendorId)")
                _ = cloudStorage.synchronize()
            } else {
                // Apply remote to local
                try configManager.updateVendor(conflict.remote)
            }
            
            // Remove from pending
            pendingConflicts.removeAll { $0.id == vendorId }
        } catch {
            syncStatus = .error("Failed to resolve conflict: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Interface
    
    func toggleSync(enabled: Bool) {
        syncConfig.isSyncEnabled = enabled
        saveSyncConfigLocally()
        
        if enabled {
            uploadSelectedVendors()
        }
    }
    
    func updateSyncedVendors(ids: [String]) {
        syncConfig.syncedVendorIds = ids
        saveSyncConfigLocally()
        uploadSelectedVendors()
    }
    
    private func saveSyncConfigLocally() {
        do {
            try cloudStorage.setCodable(syncConfig, forKey: syncConfigKey)
            _ = cloudStorage.synchronize()
        } catch {
            Logger.shared.error("Failed to save sync config to cloud: \(error)")
        }
    }
}