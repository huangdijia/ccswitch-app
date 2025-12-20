import Foundation

// MARK: - CCSwitch Configuration (Matches new format)
struct CCSConfig: Codable {
    var current: String?
    var vendors: [Vendor]

    // Default configuration
    static func createDefault() -> CCSConfig {
        return CCSConfig(
            current: "default",
            vendors: [
                Vendor(
                    id: "default",
                    name: "Default",
                    env: [:]
                ),
                Vendor(
                    id: "anyrouter",
                    name: "AnyRouter",
                    env: [
                        "ANTHROPIC_AUTH_TOKEN": "sk-xxxxxx",
                        "ANTHROPIC_BASE_URL": "https://anyrouter.top"
                    ]
                ),
                Vendor(
                    id: "deepseek",
                    name: "DeepSeek",
                    env: [
                        "ANTHROPIC_AUTH_TOKEN": "sk-xxxxxx",
                        "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
                        "ANTHROPIC_MODEL": "deepseek-chat",
                        "ANTHROPIC_SMALL_FAST_MODEL": "deepseek-chat"
                    ]
                )
            ]
        )
    }

    // 从现有配置转换
    static func loadFromFile(url: URL = CCSConfig.configFile) -> CCSConfig? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            
            // Try loading new format first
            if let config = try? JSONDecoder().decode(CCSConfig.self, from: data) {
                return config
            }
            
            // Fallback to legacy format
            let legacy = try JSONDecoder().decode(LegacyCCSConfig.self, from: data)
            return legacy.toNewConfig()
        } catch {
            print("Failed to load CCS config from \(url.path): \(error)")
            return nil
        }
    }
}

// MARK: - Legacy Configuration (For migration)
struct LegacyCCSConfig: Codable {
    let settingsPath: String?
    var `default`: String?
    var version: Int?
    var current: String?
    let profiles: [String: [String: String]]?
    let descriptions: [String: String]?
    let vendors: [LegacyVendor]?

    struct LegacyVendor: Codable {
        let id: String
        let displayName: String?
        let name: String?
        let env: [String: String]?
        let claudeSettingsPatch: [String: String]?
    }

    func toNewConfig() -> CCSConfig {
        var newVendors: [Vendor] = []
        
        if let vendors = vendors {
            newVendors = vendors.map { v in
                Vendor(
                    id: v.id,
                    name: v.name ?? v.displayName ?? v.id,
                    env: v.env ?? [:]
                )
            }
        } else if let profiles = profiles {
            newVendors = profiles.map { (id, config) in
                Vendor(
                    id: id,
                    name: descriptions?[id] ?? id,
                    env: config
                )
            }
        }
        
        return CCSConfig(
            current: current ?? `default`,
            vendors: newVendors
        )
    }
}

// MARK: - CCSwitch Configuration Paths
extension CCSConfig {
    static let configDirectory = URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path)
        .appendingPathComponent(".ccswitch")
    static let configFile = configDirectory.appendingPathComponent("ccswitch.json")
    static let legacyConfigFile = configDirectory.appendingPathComponent("ccs.json")

    static func ensureConfigDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: configDirectory,
            withIntermediateDirectories: true
        )
    }
}