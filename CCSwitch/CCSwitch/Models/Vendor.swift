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
}

// MARK: - Vendor Status
enum VendorStatus {
    case active
    case missingFields
    case writeFailure
}