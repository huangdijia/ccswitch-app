import Foundation

// MARK: - CCSwitch Configuration (适配现有格式)
struct CCSConfig: Codable {
    let settingsPath: String
    var `default`: String
    let profiles: [String: [String: String]]
    let descriptions: [String: String]?

    var current: String {
        get { return `default` }
        set { `default` = newValue }
    }

    var vendors: [Vendor] {
        return profiles.map { (id, config) in
            Vendor(
                id: id,
                displayName: descriptions?[id] ?? id,
                claudeSettingsPatch: ClaudeSettingsPatch(
                    provider: "anthropic",
                    model: config["ANTHROPIC_MODEL"] ?? "claude-3-5-sonnet",
                    apiKeyEnv: "ANTHROPIC_AUTH_TOKEN",
                    baseURL: config["ANTHROPIC_BASE_URL"]
                )
            )
        }
    }

    // 从现有配置转换
    static func loadFromFile() -> CCSConfig? {
        let url = configDirectory.appendingPathComponent("ccs.json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(CCSConfig.self, from: data)
            return config
        } catch {
            print("Failed to load CCS config: \(error)")
            return nil
        }
    }
}

// MARK: - CCSwitch Configuration Paths
extension CCSConfig {
    static let configDirectory = URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path)
        .appendingPathComponent(".ccswitch")
    static let configFile = configDirectory.appendingPathComponent("ccs.json")

    static func ensureConfigDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: configDirectory,
            withIntermediateDirectories: true
        )
    }
}