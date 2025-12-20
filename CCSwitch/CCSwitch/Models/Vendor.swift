import Foundation

// MARK: - Vendor Model
struct Vendor: Codable, Identifiable {
    let id: String
    let displayName: String
    let claudeSettingsPatch: ClaudeSettingsPatch
    let notes: String?

    init(id: String, displayName: String, claudeSettingsPatch: ClaudeSettingsPatch, notes: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.claudeSettingsPatch = claudeSettingsPatch
        self.notes = notes
    }
}

// MARK: - Claude Settings Patch
struct ClaudeSettingsPatch: Codable {
    let provider: String
    let model: String
    let apiKeyEnv: String
    let baseURL: String?

    init(provider: String, model: String, apiKeyEnv: String, baseURL: String? = nil) {
        self.provider = provider
        self.model = model
        self.apiKeyEnv = apiKeyEnv
        self.baseURL = baseURL
    }
}

// MARK: - Vendor Status
enum VendorStatus {
    case active
    case missingFields
    case writeFailure
}