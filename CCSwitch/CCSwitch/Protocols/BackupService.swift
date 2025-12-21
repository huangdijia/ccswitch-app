import Foundation

/// Protocol for backup operations
/// This abstraction allows for different backup strategies and improves testability
protocol BackupService {
    /// Create a backup of the current settings
    /// - Throws: Error if backup fails
    func backupCurrentSettings() throws
    
    /// Restore settings from a backup
    /// - Parameter backupURL: URL of the backup file to restore
    /// - Throws: Error if restore fails
    func restoreFromBackup(_ backupURL: URL) throws
    
    /// Get all available backups
    /// - Returns: Array of backup file URLs, sorted by date (newest first)
    /// - Throws: Error if listing fails
    func getAllBackups() throws -> [URL]
    
    /// Delete a specific backup
    /// - Parameter backupURL: URL of the backup to delete
    /// - Throws: Error if deletion fails
    func deleteBackup(_ backupURL: URL) throws
    
    /// Delete all backups
    /// - Throws: Error if deletion fails
    func deleteAllBackups() throws
}

// Extend BackupManager to conform to the protocol
extension BackupManager: BackupService {}
