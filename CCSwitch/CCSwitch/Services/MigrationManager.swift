import Foundation
import SwiftUI

enum MigrationResult: Sendable {
    case success(count: Int)
    case failure(String)
}

@MainActor
class MigrationManager: ObservableObject {
    static let shared = MigrationManager()
    
    private let migrationKey = "has_migrated_from_legacy"
    
    @Published var isMigrating = false
    @Published var showMigrationPrompt = false
    @Published var legacyVendorsCount = 0
    @Published var legacyDefaultVendor: String?
    
    private init() {}
    
    nonisolated var hasLegacyConfig: Bool {
        let migrationKey = "has_migrated_from_legacy"
        return ConfigManager.shared.hasLegacyConfig && !UserDefaults.standard.bool(forKey: migrationKey)
    }
    
    func checkMigration(force: Bool = false) {
        if force || hasLegacyConfig {
            if let legacy = CCSConfig.loadFromFile(url: CCSConfig.legacyConfigFile) {
                self.legacyVendorsCount = legacy.vendors.count
                if let defaultId = legacy.current {
                    self.legacyDefaultVendor = legacy.vendors.first(where: { $0.id == defaultId })?.name ?? defaultId
                }
                self.showMigrationPrompt = true
            }
        }
    }
    
    func skipMigration() {
        UserDefaults.standard.set(true, forKey: migrationKey)
        showMigrationPrompt = false
    }
    
    func performMigration() async -> MigrationResult {
        self.isMigrating = true
        
        do {
            // 1. Create Backup (In background if needed, but here simple file op)
            try backupLegacyConfig()
            
            // 2. Perform migration
            let count = try ConfigManager.shared.migrateFromLegacy()
            
            // 3. Mark as migrated
            UserDefaults.standard.set(true, forKey: migrationKey)
            
            self.isMigrating = false
            return .success(count: count)
        } catch {
            Logger.shared.error("Migration failed", error: error)
            self.isMigrating = false
            return .failure(error.localizedDescription)
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
