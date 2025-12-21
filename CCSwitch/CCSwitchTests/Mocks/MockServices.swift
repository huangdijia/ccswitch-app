import Foundation
@testable import CCSwitch

/// Mock implementation of SettingsWriter for testing
class MockSettingsWriter: SettingsWriter {
    var lastWrittenSettings: [String: String]?
    var writeCallCount = 0
    var shouldThrowError = false
    
    func writeSettings(_ env: [String: String]) throws {
        writeCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "MockSettingsWriter", code: 1, userInfo: nil)
        }
        lastWrittenSettings = env
    }
}

/// Mock implementation of BackupService for testing
class MockBackupService: BackupService {
    var backupCallCount = 0
    var restoreCallCount = 0
    var shouldThrowError = false
    var mockBackups: [URL] = []
    
    func backupCurrentSettings() throws {
        backupCallCount += 1
        if shouldThrowError {
            throw BackupError.restoreFailed
        }
    }
    
    func restoreFromBackup(_ backupURL: URL) throws {
        restoreCallCount += 1
        if shouldThrowError {
            throw BackupError.restoreFailed
        }
    }
    
    func getAllBackups() throws -> [URL] {
        if shouldThrowError {
            throw BackupError.backupNotFound
        }
        return mockBackups
    }
    
    func deleteBackup(_ backupURL: URL) throws {
        if shouldThrowError {
            throw BackupError.invalidBackupFile
        }
        mockBackups.removeAll { $0 == backupURL }
    }
    
    func deleteAllBackups() throws {
        if shouldThrowError {
            throw BackupError.restoreFailed
        }
        mockBackups.removeAll()
    }
}
