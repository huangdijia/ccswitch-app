import Foundation
import os

// MARK: - Logger Service
class Logger {
    static let shared = Logger()

    private let logger = os.Logger(subsystem: "com.cccode.switch", category: "CCSwitch")
    private let logFileURL: URL

    private init() {
        let configDir = CCSConfig.configDirectory
        try? configDir.ensureDirectoryExists()
        logFileURL = configDir.appendingPathComponent("ccswitch.log")
    }

    // MARK: - Logging Methods
    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        writeToFile(level: "INFO", message: message)
    }

    func debug(_ message: String) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        writeToFile(level: "DEBUG", message: message)
        #endif
    }

    func error(_ message: String, error: Error? = nil) {
        let fullMessage = error != nil ? "\(message): \(error!)" : message
        logger.error("\(fullMessage, privacy: .public)")
        writeToFile(level: "ERROR", message: fullMessage)
    }

    func warn(_ message: String) {
        logger.warning("\(message, privacy: .public)")
        writeToFile(level: "WARN", message: message)
    }

    // MARK: - File Writing
    private func writeToFile(level: String, message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] [\(level)] \(message)\n"

        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                do {
                    let fileHandle = try FileHandle(forWritingTo: logFileURL)
                    try fileHandle.seekToEnd()
                    try fileHandle.write(contentsOf: data)
                    try fileHandle.close()
                } catch {
                    print("Failed to write to log file: \(error)")
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }

        // Rotate logs if they get too large (>5MB)
        rotateLogsIfNeeded()
    }

    private func rotateLogsIfNeeded() {
        do {
            let attributes = try logFileURL.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = attributes.fileSize, fileSize > 5 * 1024 * 1024 {
                // Rotate log file
                let rotatedLogURL = logFileURL.appendingPathExtension("old")
                if FileManager.default.fileExists(atPath: rotatedLogURL.path) {
                    try FileManager.default.removeItem(at: rotatedLogURL)
                }
                try FileManager.default.moveItem(at: logFileURL, to: rotatedLogURL)
            }
        } catch {
            print("Failed to rotate logs: \(error)")
        }
    }

    // MARK: - Log Reading
    func getLogContents() -> String {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            return "暂无日志"
        }

        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            return "无法读取日志文件: \(error.localizedDescription)"
        }
    }

    func clearLogs() {
        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                try FileManager.default.removeItem(at: logFileURL)
            }
        } catch {
            print("Failed to clear logs: \(error)")
        }
    }

    // MARK: - Private Properties
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Convenience Extensions
extension Logger {
    func logConfigLoad(_ vendorId: String) {
        info("Configuration loaded, current vendor: \(vendorId)")
    }

    func logVendorSwitch(from: String?, to: String) {
        info("Vendor switched from \(from ?? "unknown") to \(to)")
    }

    func logConfigUpdate(_ action: String) {
        info("Configuration updated: \(action)")
    }

    func logBackup(_ action: String, fileName: String) {
        info("Backup \(action): \(fileName)")
    }

    func logError(_ message: String, operation: String) {
        error("Operation '\(operation)' failed: \(message)")
    }
}