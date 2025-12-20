import Foundation

// MARK: - Claude Settings Model
struct ClaudeSettings: Codable {
    var env: [String: String]?
    
    // Store other arbitrary keys
    private var otherSettings: [String: AnyValue] = [:]

    init() {
        env = [:]
    }

    // Custom coding keys to handle 'env' explicitly and others dynamically
    struct DynamicKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int?
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        var settings: [String: AnyValue] = [:]
        
        for key in container.allKeys {
            if key.stringValue == "env" {
                env = try container.decodeIfPresent([String: String].self, forKey: key)
            } else {
                if let value = try? container.decode(AnyValue.self, forKey: key) {
                    settings[key.stringValue] = value
                }
            }
        }
        otherSettings = settings
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        
        // Encode 'env'
        try container.encodeIfPresent(env, forKey: DynamicKey(stringValue: "env")!)
        
        // Encode other settings
        for (key, value) in otherSettings {
            if key != "env" {
                try container.encode(value, forKey: DynamicKey(stringValue: key)!)
            }
        }
    }
}

// Helper to handle arbitrary JSON values in Codable
enum AnyValue: Codable {
    case string(String)
    case bool(Bool)
    case double(Double)
    case int(Int)
    case dictionary([String: AnyValue])
    case array([AnyValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) { self = .string(x) }
        else if let x = try? container.decode(Bool.self) { self = .bool(x) }
        else if let x = try? container.decode(Int.self) { self = .int(x) }
        else if let x = try? container.decode(Double.self) { self = .double(x) }
        else if let x = try? container.decode([String: AnyValue].self) { self = .dictionary(x) }
        else if let x = try? container.decode([AnyValue].self) { self = .array(x) }
        else { self = .null }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x): try container.encode(x)
        case .bool(let x): try container.encode(x)
        case .double(let x): try container.encode(x)
        case .int(let x): try container.encode(x)
        case .dictionary(let x): try container.encode(x)
        case .array(let x): try container.encode(x)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Claude Settings Paths
extension ClaudeSettings {
    static let configDirectory = URL(fileURLWithPath: FileManager.default.homeDirectoryForCurrentUser.path)
        .appendingPathComponent(".claude")
    static let configFile = configDirectory.appendingPathComponent("settings.json")
}