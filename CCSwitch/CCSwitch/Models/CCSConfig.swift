import Foundation

// MARK: - CCSwitch Configuration (Matches new format)
struct CCSConfig: Codable {
    var current: String?
    var vendors: [Vendor]
    var favorites: [String]?
    var presets: [String]?

    // Default configuration
    static func createDefault() -> CCSConfig {
        return CCSConfig(
            current: "default",
            vendors: [
                Vendor(
                    id: "default",
                    name: "Default",
                    env: [:]
                )
            ],
            favorites: [],
            presets: ["default"]
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
            do {
                return try JSONDecoder().decode(CCSConfig.self, from: data)
            } catch {
                Logger.shared.error("Failed to decode new config format: \(error)")
                // Continue to fallback
            }
            
            // Fallback to legacy format
            let legacy = try JSONDecoder().decode(LegacyCCSConfig.self, from: data)
            return legacy.toNewConfig()
        } catch {
            Logger.shared.error("Failed to load CCS config from \(url.path): \(error)")
            return nil
        }
    }

    // 从 Bundle 加载预设配置
    /// Load preset vendors from the app bundle
    /// - Returns: An array of `Vendor` objects loaded from `presets.json` or fallback
    static func loadPresets() -> [Vendor] {
        // Hardcoded fallback in case the file is missing from Bundle Resources
        let fallbackPresets = [
            Vendor(
                id: "default",
                name: "Default",
                env: [:]
            )
        ]

        guard let url = Bundle.main.url(forResource: "presets", withExtension: "json") else {
            Logger.shared.warn("Presets file not found in bundle, using hardcoded fallback")
            return fallbackPresets
        }

        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(CCSConfig.self, from: data)
            return config.vendors
        } catch {
            Logger.shared.error("Failed to load presets from bundle: \(error), using hardcoded fallback")
            return fallbackPresets
        }
    }
}

// MARK: - Legacy Configuration (For migration)
struct LegacyCCSConfig: Decodable {
    let settingsPath: String?
    var `default`: String?
    var version: Int?
    var current: String?
    let profiles: [String: [String: String]]?
    let descriptions: [String: String]?
    let vendors: [LegacyVendor]?

    struct LegacyVendor: Decodable {
        let id: String
        let displayName: String?
        let name: String?
        let env: [String: String]?
        let claudeSettingsPatch: [String: String]?
        
        enum CodingKeys: String, CodingKey {
            case id, displayName, name, env, claudeSettingsPatch
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            claudeSettingsPatch = try container.decodeIfPresent([String: String].self, forKey: .claudeSettingsPatch)
            
            // Handle env with mixed types
            if let envContainer = try? container.decode([String: AnyDecodable].self, forKey: .env) {
                env = envContainer.mapValues { $0.description }
            } else {
                env = try container.decodeIfPresent([String: String].self, forKey: .env)
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case settingsPath, `default`, version, current, profiles, descriptions, vendors
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settingsPath = try container.decodeIfPresent(String.self, forKey: .settingsPath)
        `default` = try container.decodeIfPresent(String.self, forKey: .default)
        version = try container.decodeIfPresent(Int.self, forKey: .version)
        current = try container.decodeIfPresent(String.self, forKey: .current)
        descriptions = try container.decodeIfPresent([String: String].self, forKey: .descriptions)
        vendors = try container.decodeIfPresent([LegacyVendor].self, forKey: .vendors)
        
        // Handle profiles with mixed types
        if let profilesContainer = try? container.decode([String: [String: AnyDecodable]].self, forKey: .profiles) {
            profiles = profilesContainer.mapValues { $0.mapValues { $0.description } }
        } else {
            profiles = try container.decodeIfPresent([String: [String: String]].self, forKey: .profiles)
        }
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
            vendors: newVendors,
            favorites: [],
            presets: []
        )
    }
}

// MARK: - CCSwitch Configuration Paths
extension CCSConfig {
    static let configDirectory = URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path)
        .appendingPathComponent(".ccswitch")
    static let configFile = configDirectory.appendingPathComponent("vendors.json")
    static let legacyConfigFile = configDirectory.appendingPathComponent("ccs.json")

    static func ensureConfigDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: configDirectory,
            withIntermediateDirectories: true
        )
    }
}

// MARK: - Helper Types
private struct AnyDecodable: Decodable, CustomStringConvertible {
    let value: Any
    
    var description: String {
        return String(describing: value)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) { value = x }
        else if let x = try? container.decode(Int.self) { value = x }
        else if let x = try? container.decode(Double.self) { value = x }
        else if let x = try? container.decode(Bool.self) { value = x }
        else if container.decodeNil() { value = "" }
        else {
            throw DecodingError.typeMismatch(AnyDecodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Sync Configuration
struct SyncConfiguration: Codable, Equatable {
    var isSyncEnabled: Bool
    var syncedVendorIds: [String]
    
    init(isSyncEnabled: Bool = false, syncedVendorIds: [String] = []) {
        self.isSyncEnabled = isSyncEnabled
        self.syncedVendorIds = syncedVendorIds
    }
}