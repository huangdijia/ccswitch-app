import Foundation

/// Vendor template for common vendor configurations
/// This improves configuration reusability and reduces duplication
struct VendorTemplate: Codable {
    let id: String
    let name: String
    let baseURL: String?
    let requiredEnvVars: [String]
    let optionalEnvVars: [String]
    let defaultValues: [String: String]
    let description: String?
    
    /// Create a vendor from this template with provided values
    /// - Parameter envValues: Environment variable values to use
    /// - Returns: A configured Vendor instance
    /// - Throws: Error if required environment variables are missing
    func createVendor(with envValues: [String: String]) throws -> Vendor {
        var env = defaultValues
        
        // Merge provided values
        for (key, value) in envValues {
            env[key] = value
        }
        
        // Validate required variables
        for requiredVar in requiredEnvVars {
            guard env[requiredVar] != nil else {
                throw VendorTemplateError.missingRequiredVariable(requiredVar)
            }
        }
        
        return Vendor(id: id, name: name, env: env)
    }
    
    /// Common vendor templates
    static let templates: [VendorTemplate] = [
        .anthropicOfficial,
        .deepseek,
        .openai,
        .azureOpenAI,
        .anyRouter,
        .custom
    ]
    
    // MARK: - Predefined Templates
    
    static let anthropicOfficial = VendorTemplate(
        id: "anthropic",
        name: "Anthropic Official",
        baseURL: "https://api.anthropic.com",
        requiredEnvVars: ["ANTHROPIC_AUTH_TOKEN"],
        optionalEnvVars: ["ANTHROPIC_MODEL", "ANTHROPIC_SMALL_FAST_MODEL"],
        defaultValues: [:],
        description: "Official Anthropic Claude API"
    )
    
    static let deepseek = VendorTemplate(
        id: "deepseek",
        name: "DeepSeek",
        baseURL: "https://api.deepseek.com/anthropic",
        requiredEnvVars: ["ANTHROPIC_AUTH_TOKEN"],
        optionalEnvVars: ["ANTHROPIC_MODEL", "ANTHROPIC_SMALL_FAST_MODEL"],
        defaultValues: [
            "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
            "ANTHROPIC_MODEL": "deepseek-chat",
            "ANTHROPIC_SMALL_FAST_MODEL": "deepseek-chat"
        ],
        description: "DeepSeek AI with Anthropic-compatible API"
    )
    
    static let openai = VendorTemplate(
        id: "openai",
        name: "OpenAI",
        baseURL: "https://api.openai.com",
        requiredEnvVars: ["OPENAI_API_KEY"],
        optionalEnvVars: ["OPENAI_MODEL", "OPENAI_BASE_URL"],
        defaultValues: [:],
        description: "OpenAI GPT models"
    )
    
    static let azureOpenAI = VendorTemplate(
        id: "azure-openai",
        name: "Azure OpenAI",
        baseURL: nil,
        requiredEnvVars: ["AZURE_OPENAI_API_KEY", "AZURE_OPENAI_ENDPOINT"],
        optionalEnvVars: ["AZURE_OPENAI_DEPLOYMENT_NAME"],
        defaultValues: [:],
        description: "Microsoft Azure OpenAI Service"
    )
    
    static let anyRouter = VendorTemplate(
        id: "anyrouter",
        name: "AnyRouter",
        baseURL: "https://anyrouter.top",
        requiredEnvVars: ["ANTHROPIC_AUTH_TOKEN"],
        optionalEnvVars: ["ANTHROPIC_MODEL"],
        defaultValues: [
            "ANTHROPIC_BASE_URL": "https://anyrouter.top"
        ],
        description: "AnyRouter API Gateway"
    )
    
    static let custom = VendorTemplate(
        id: "custom",
        name: "Custom Vendor",
        baseURL: nil,
        requiredEnvVars: [],
        optionalEnvVars: [],
        defaultValues: [:],
        description: "Custom vendor configuration"
    )
    
    /// Find a template by ID
    static func findTemplate(byId id: String) -> VendorTemplate? {
        return templates.first { $0.id == id }
    }
}

/// Errors related to vendor template operations
enum VendorTemplateError: Error, LocalizedError {
    case missingRequiredVariable(String)
    case templateNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredVariable(let variable):
            return String(format: NSLocalizedString("missing_required_variable", comment: ""), variable)
        case .templateNotFound(let id):
            return String(format: NSLocalizedString("template_not_found", comment: ""), id)
        }
    }
}
