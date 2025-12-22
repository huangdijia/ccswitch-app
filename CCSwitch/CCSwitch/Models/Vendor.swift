import Foundation

// MARK: - Vendor Model
struct Vendor: Codable, Identifiable {
    let id: String
    let name: String
    let env: [String: String]

    init(id: String, name: String, env: [String: String]) {
        self.id = id
        self.name = name
        self.env = env
    }

    var displayName: String { name }
    
    enum CodingKeys: String, CodingKey {
        case id, name, env
    }

    // Custom decoding to handle non-string values in env
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Try decoding as strict [String: String] first
        if let stringEnv = try? container.decode([String: String].self, forKey: .env) {
            env = stringEnv
        } else {
            // Fallback: Decode values loosely and convert to String
            let anyEnv = try container.decode([String: SafeString].self, forKey: .env)
            env = anyEnv.mapValues { $0.value }
        }
    }
}

// Helper for robust string decoding
struct SafeString: Codable {
    let value: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            value = str
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(double)
        } else if let bool = try? container.decode(Bool.self) {
            value = String(bool)
        } else {
            // Handle null or others by decoding as empty or throwing
            if container.decodeNil() {
                value = ""
            } else {
                throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String, Int, Double or Bool"))
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

// MARK: - Vendor Status
enum VendorStatus {
    case active
    case missingFields
    case writeFailure
}