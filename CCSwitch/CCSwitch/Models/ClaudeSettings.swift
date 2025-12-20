import Foundation

// MARK: - Claude Settings Model
struct ClaudeSettings: Codable {
    var provider: String?
    var model: String?
    var apiKeyEnv: String?
    var baseURL: String?

    // 可以存储其他未知的字段
    var additionalData: [String: Any]?

    init() {
        additionalData = [:]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 解码已知字段
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        model = try container.decodeIfPresent(String.self, forKey: .model)
        apiKeyEnv = try container.decodeIfPresent(String.self, forKey: .apiKeyEnv)
        baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL)

        // 这里简化处理，暂时不保存其他字段
        additionalData = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // 编码已知字段
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(model, forKey: .model)
        try container.encodeIfPresent(apiKeyEnv, forKey: .apiKeyEnv)
        try container.encodeIfPresent(baseURL, forKey: .baseURL)
    }

    enum CodingKeys: String, CodingKey {
        case provider, model, apiKeyEnv, baseURL
    }
}

// MARK: - Claude Settings Paths
extension ClaudeSettings {
    static let configDirectory = URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path)
        .appendingPathComponent(".claude")
    static let configFile = configDirectory.appendingPathComponent("settings.json")
}