import XCTest
@testable import CCSwitch

final class ModelTests: XCTestCase {
    func testVendorInitialization() {
        let patch = ClaudeSettingsPatch(
            provider: "anthropic",
            model: "claude-3-5-sonnet",
            apiKeyEnv: "ANTHROPIC_API_KEY"
        )

        let vendor = Vendor(
            id: "anthropic",
            displayName: "Anthropic",
            claudeSettingsPatch: patch,
            notes: "Official Anthropic provider"
        )

        XCTAssertEqual(vendor.id, "anthropic")
        XCTAssertEqual(vendor.displayName, "Anthropic")
        XCTAssertEqual(vendor.claudeSettingsPatch.provider, "anthropic")
        XCTAssertEqual(vendor.claudeSettingsPatch.model, "claude-3-5-sonnet")
        XCTAssertEqual(vendor.claudeSettingsPatch.apiKeyEnv, "ANTHROPIC_API_KEY")
        XCTAssertEqual(vendor.notes, "Official Anthropic provider")
    }

    func testVendorWithOptionalFields() {
        let patch = ClaudeSettingsPatch(
            provider: "openai",
            model: "gpt-4",
            apiKeyEnv: "OPENAI_API_KEY",
            baseURL: "https://api.openai.com/v1"
        )

        let vendor = Vendor(
            id: "openai",
            displayName: "OpenAI",
            claudeSettingsPatch: patch
        )

        XCTAssertEqual(vendor.id, "openai")
        XCTAssertEqual(vendor.displayName, "OpenAI")
        XCTAssertEqual(vendor.claudeSettingsPatch.baseURL, "https://api.openai.com/v1")
        XCTAssertNil(vendor.notes)
    }

    func testVendorJSONEncodingDecoding() throws {
        let vendor = Vendor(
            id: "deepseek",
            displayName: "DeepSeek",
            claudeSettingsPatch: ClaudeSettingsPatch(
                provider: "deepseek",
                model: "deepseek-chat",
                apiKeyEnv: "DEEPSEEK_API_KEY"
            ),
            notes: "DeepSeek AI provider"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(vendor)

        let decoder = JSONDecoder()
        let decodedVendor = try decoder.decode(Vendor.self, from: data)

        XCTAssertEqual(decodedVendor.id, vendor.id)
        XCTAssertEqual(decodedVendor.displayName, vendor.displayName)
        XCTAssertEqual(decodedVendor.claudeSettingsPatch.provider, vendor.claudeSettingsPatch.provider)
        XCTAssertEqual(decodedVendor.claudeSettingsPatch.model, vendor.claudeSettingsPatch.model)
        XCTAssertEqual(decodedVendor.claudeSettingsPatch.apiKeyEnv, vendor.claudeSettingsPatch.apiKeyEnv)
        XCTAssertEqual(decodedVendor.notes, vendor.notes)
    }

    func testCCSConfigJSONEncodingDecoding() throws {
        let config = CCSConfig(
            version: 1,
            current: "anthropic",
            vendors: [
                Vendor(
                    id: "anthropic",
                    displayName: "Anthropic",
                    claudeSettingsPatch: ClaudeSettingsPatch(
                        provider: "anthropic",
                        model: "claude-3-5-sonnet",
                        apiKeyEnv: "ANTHROPIC_API_KEY"
                    )
                ),
                Vendor(
                    id: "deepseek",
                    displayName: "DeepSeek",
                    claudeSettingsPatch: ClaudeSettingsPatch(
                        provider: "deepseek",
                        model: "deepseek-chat",
                        apiKeyEnv: "DEEPSEEK_API_KEY"
                    )
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(CCSConfig.self, from: data)

        XCTAssertEqual(decodedConfig.version, config.version)
        XCTAssertEqual(decodedConfig.current, config.current)
        XCTAssertEqual(decodedConfig.vendors.count, config.vendors.count)
        XCTAssertEqual(decodedConfig.vendors[0].id, config.vendors[0].id)
        XCTAssertEqual(decodedConfig.vendors[1].id, config.vendors[1].id)
    }

    func testClaudeSettingsPatch() {
        let patch = ClaudeSettingsPatch(
            provider: "anthropic",
            model: "claude-3-5-sonnet",
            apiKeyEnv: "ANTHROPIC_API_KEY"
        )

        XCTAssertEqual(patch.provider, "anthropic")
        XCTAssertEqual(patch.model, "claude-3-5-sonnet")
        XCTAssertEqual(patch.apiKeyEnv, "ANTHROPIC_API_KEY")
        XCTAssertNil(patch.baseURL)
    }

    func testClaudeSettingsPatchWithBaseURL() {
        let patch = ClaudeSettingsPatch(
            provider: "custom",
            model: "custom-model",
            apiKeyEnv: "CUSTOM_API_KEY",
            baseURL: "https://api.custom.com/v1"
        )

        XCTAssertEqual(patch.baseURL, "https://api.custom.com/v1")
    }

    func testClaudeSettingsMerge() throws {
        var settings = ClaudeSettings()
        settings.provider = "old-provider"
        settings.model = "old-model"
        settings.apiKeyEnv = "OLD_KEY"
        settings.baseURL = "https://old.api.com"

        let patch = ClaudeSettingsPatch(
            provider: "new-provider",
            model: "new-model",
            apiKeyEnv: "NEW_KEY",
            baseURL: "https://new.api.com"
        )

        settings.merge(patch: patch)

        XCTAssertEqual(settings.provider, "new-provider")
        XCTAssertEqual(settings.model, "new-model")
        XCTAssertEqual(settings.apiKeyEnv, "NEW_KEY")
        XCTAssertEqual(settings.baseURL, "https://new.api.com")
    }

    func testClaudeSettingsPartialMerge() throws {
        var settings = ClaudeSettings()
        settings.provider = "old-provider"
        settings.model = "old-model"
        settings.apiKeyEnv = "OLD_KEY"
        settings.baseURL = "https://old.api.com"

        let patch = ClaudeSettingsPatch(
            provider: "new-provider",
            model: "new-model",
            apiKeyEnv: "NEW_KEY",
            baseURL: nil
        )

        settings.merge(patch: patch)

        XCTAssertEqual(settings.provider, "new-provider")
        XCTAssertEqual(settings.model, "new-model")
        XCTAssertEqual(settings.apiKeyEnv, "NEW_KEY")
        XCTAssertEqual(settings.baseURL, "https://old.api.com") // nil in patch should preserve existing value
    }

    func testVendorStatusEnum() {
        let status: VendorStatus = .active
        switch status {
        case .active:
            XCTAssertTrue(true)
        case .missingFields:
            XCTFail("Unexpected status")
        case .writeFailure:
            XCTFail("Unexpected status")
        }
    }
}