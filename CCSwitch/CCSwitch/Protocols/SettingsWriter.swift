import Foundation

/// Protocol for writing settings to Claude configuration
/// This abstraction allows for different storage mechanisms and improves testability
protocol SettingsWriter {
    /// Write environment settings to Claude configuration
    /// - Parameter env: Dictionary of environment variables to write
    /// - Throws: Error if writing fails
    func writeSettings(_ env: [String: String]) throws
}

/// Default implementation that writes to Claude's settings.json file
class ClaudeSettingsWriter: SettingsWriter {
    private let settingsURL: URL
    private let fileManager: FileManager
    
    init(
        settingsURL: URL = ClaudeSettings.configFile,
        fileManager: FileManager = .default
    ) {
        self.settingsURL = settingsURL
        self.fileManager = fileManager
    }
    
    func writeSettings(_ env: [String: String]) throws {
        var claudeSettings: ClaudeSettings
        
        // Read existing configuration or create new one
        if fileManager.fileExists(atPath: settingsURL.path) {
            let data = try Data(contentsOf: settingsURL)
            claudeSettings = try JSONDecoder().decode(ClaudeSettings.self, from: data)
        } else {
            claudeSettings = ClaudeSettings()
        }
        
        // Update only the env field
        claudeSettings.env = env
        
        // Ensure directory exists
        try ClaudeSettings.configDirectory.ensureDirectoryExists()
        
        // Write configuration
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try encoder.encode(claudeSettings)
        try data.write(to: settingsURL)
        
        Logger.shared.info("Successfully wrote settings to \(settingsURL.path)")
    }
}
