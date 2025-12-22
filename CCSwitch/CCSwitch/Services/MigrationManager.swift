import Foundation
import SwiftUI

enum MigrationResult {
    case success(count: Int)
    case failure(Error)
}

class MigrationManager: ObservableObject {
    static let shared = MigrationManager()
    
    private let migrationKey = "has_migrated_from_legacy"
    
    @Published var isMigrating = false
    @Published var showMigrationPrompt = false
    @Published var legacyVendorsCount = 0
    @Published var legacyDefaultVendor: String?
    
    private init() {}
    
    var hasLegacyConfig: Bool {
        return ConfigManager.shared.hasLegacyConfig && !UserDefaults.standard.bool(forKey: migrationKey)
    }
    
    func checkMigration(force: Bool = false) {
        if force || hasLegacyConfig {
            // Try to peek into legacy config to show count
            if let legacy = CCSConfig.loadFromFile(url: CCSConfig.legacyConfigFile) {
                DispatchQueue.main.async {
                    self.legacyVendorsCount = legacy.vendors.count
                    if let defaultId = legacy.current {
                        self.legacyDefaultVendor = legacy.vendors.first(where: { $0.id == defaultId })?.name ?? defaultId
                    }
                    self.showMigrationPrompt = true
                }
            } else if force {
                Logger.shared.error("Manual migration triggered but legacy file could not be loaded")
            }
        }
    }
    
    func skipMigration() {
        UserDefaults.standard.set(true, forKey: migrationKey)
        showMigrationPrompt = false
    }
    
    @MainActor
    func performMigration() async -> MigrationResult {
        isMigrating = true
        
        // Give UI a moment to show loading if needed
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        do {
            // 1. Create Backup
            try backupLegacyConfig()
            
                    // 2. Perform migration via ConfigManager
                    let count = try await Task { @MainActor in
                        try ConfigManager.shared.migrateFromLegacy()
                    }.value
                        // 3. Mark as migrated
            UserDefaults.standard.set(true, forKey: migrationKey)
            
            DispatchQueue.main.async {
                self.isMigrating = false
            }
            
            return .success(count: count)
        } catch {
            Logger.shared.error("Migration failed", error: error)
            DispatchQueue.main.async {
                self.isMigrating = false
            }
            return .failure(error)
        }
    }
    
    private func backupLegacyConfig() throws {
        let fileManager = FileManager.default
        let legacyURL = CCSConfig.legacyConfigFile
        
        guard fileManager.fileExists(atPath: legacyURL.path) else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: Date())
        
        let backupURL = legacyURL.deletingPathExtension().appendingPathExtension("bak-\(timestamp).json")
        
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        
        try fileManager.copyItem(at: legacyURL, to: backupURL)
        Logger.shared.info("Created legacy config backup at \(backupURL.path)")
    }
}
