import XCTest
@testable import CCSwitch

final class ModelTests: XCTestCase {
    
    // MARK: - Vendor Tests
    
    func testVendorCreation() {
        let vendor = Vendor(id: "test", name: "Test Vendor", env: ["KEY": "VALUE"])
        
        XCTAssertEqual(vendor.id, "test")
        XCTAssertEqual(vendor.name, "Test Vendor")
        XCTAssertEqual(vendor.displayName, "Test Vendor")
        XCTAssertEqual(vendor.env["KEY"], "VALUE")
    }
    
    func testVendorCodable() throws {
        let vendor = Vendor(id: "test", name: "Test Vendor", env: ["KEY": "VALUE"])
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(vendor)
        
        let decoder = JSONDecoder()
        let decodedVendor = try decoder.decode(Vendor.self, from: data)
        
        XCTAssertEqual(decodedVendor.id, vendor.id)
        XCTAssertEqual(decodedVendor.name, vendor.name)
        XCTAssertEqual(decodedVendor.env, vendor.env)
    }
    
    func testVendorDecodingWithNonStringValues() throws {
        let json = """
        {
            "id": "test",
            "name": "Test",
            "env": {
                "STRING_VAL": "value",
                "INT_VAL": 123,
                "BOOL_VAL": true,
                "DOUBLE_VAL": 45.67
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let vendor = try JSONDecoder().decode(Vendor.self, from: data)
        
        XCTAssertEqual(vendor.env["STRING_VAL"], "value")
        XCTAssertEqual(vendor.env["INT_VAL"], "123")
        XCTAssertEqual(vendor.env["BOOL_VAL"], "true")
        XCTAssertEqual(vendor.env["DOUBLE_VAL"], "45.67")
    }
    
    // MARK: - CCSConfig Tests
    
    func testCCSConfigCreation() {
        let vendor1 = Vendor(id: "v1", name: "Vendor 1", env: [:])
        let vendor2 = Vendor(id: "v2", name: "Vendor 2", env: [:])
        
        let config = CCSConfig(current: "v1", vendors: [vendor1, vendor2])
        
        XCTAssertEqual(config.current, "v1")
        XCTAssertEqual(config.vendors.count, 2)
    }
    
    func testCCSConfigDefaultCreation() {
        let config = CCSConfig.createDefault()
        
        XCTAssertNotNil(config.current)
        XCTAssertFalse(config.vendors.isEmpty)
        XCTAssertTrue(config.vendors.contains { $0.id == "default" })
    }
    
    func testCCSConfigCodable() throws {
        let vendor = Vendor(id: "test", name: "Test", env: ["KEY": "VALUE"])
        let config = CCSConfig(current: "test", vendors: [vendor])
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(CCSConfig.self, from: data)
        
        XCTAssertEqual(decodedConfig.current, config.current)
        XCTAssertEqual(decodedConfig.vendors.count, config.vendors.count)
        XCTAssertEqual(decodedConfig.vendors[0].id, config.vendors[0].id)
    }
    
    // MARK: - VendorTemplate Tests
    
    func testVendorTemplateCreation() throws {
        let template = VendorTemplate.deepseek
        
        let vendor = try template.createVendor(with: [
            "ANTHROPIC_AUTH_TOKEN": "sk-test-token"
        ])
        
        XCTAssertEqual(vendor.id, "deepseek")
        XCTAssertEqual(vendor.name, "DeepSeek")
        XCTAssertEqual(vendor.env["ANTHROPIC_AUTH_TOKEN"], "sk-test-token")
        XCTAssertEqual(vendor.env["ANTHROPIC_BASE_URL"], "https://api.deepseek.com/anthropic")
        XCTAssertEqual(vendor.env["ANTHROPIC_MODEL"], "deepseek-chat")
    }
    
    func testVendorTemplateMissingRequiredVariable() {
        let template = VendorTemplate.deepseek
        
        XCTAssertThrowsError(try template.createVendor(with: [:])) { error in
            XCTAssertTrue(error is VendorTemplateError)
        }
    }
    
    func testVendorTemplateFindById() {
        let template = VendorTemplate.findTemplate(byId: "deepseek")
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.id, "deepseek")
        
        let notFound = VendorTemplate.findTemplate(byId: "nonexistent")
        XCTAssertNil(notFound)
    }
    
    func testAllVendorTemplates() {
        XCTAssertFalse(VendorTemplate.templates.isEmpty)
        XCTAssertTrue(VendorTemplate.templates.contains { $0.id == "anthropic" })
        XCTAssertTrue(VendorTemplate.templates.contains { $0.id == "deepseek" })
        XCTAssertTrue(VendorTemplate.templates.contains { $0.id == "openai" })
    }
    
    // MARK: - ClaudeSettings Tests
    
    func testClaudeSettingsCreation() {
        let settings = ClaudeSettings()
        XCTAssertNotNil(settings.env)
        XCTAssertTrue(settings.env?.isEmpty ?? false)
    }
    
    func testClaudeSettingsCodable() throws {
        var settings = ClaudeSettings()
        settings.env = ["KEY1": "VALUE1", "KEY2": "VALUE2"]
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(settings)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ClaudeSettings.self, from: data)
        
        XCTAssertEqual(decoded.env, settings.env)
    }
    
    func testClaudeSettingsPreservesOtherFields() throws {
        let json = """
        {
            "env": {
                "KEY": "VALUE"
            },
            "otherField": "otherValue",
            "nestedObject": {
                "nested": "value"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(ClaudeSettings.self, from: data)
        
        XCTAssertEqual(settings.env?["KEY"], "VALUE")
        
        // Re-encode and verify other fields are preserved
        let encoded = try JSONEncoder().encode(settings)
        let jsonString = String(data: encoded, encoding: .utf8)!
        XCTAssertTrue(jsonString.contains("otherField"))
        XCTAssertTrue(jsonString.contains("nestedObject"))
    }
    
    // MARK: - SyncConfiguration Tests
    
    func testSyncConfigurationCreation() {
        let config = SyncConfiguration(isSyncEnabled: true, syncedVendorIds: ["v1", "v2"])
        
        XCTAssertTrue(config.isSyncEnabled)
        XCTAssertEqual(config.syncedVendorIds, ["v1", "v2"])
    }
    
    func testSyncConfigurationDefaults() {
        let config = SyncConfiguration()
        
        XCTAssertFalse(config.isSyncEnabled)
        XCTAssertTrue(config.syncedVendorIds.isEmpty)
    }
    
    func testSyncConfigurationCodable() throws {
        let config = SyncConfiguration(isSyncEnabled: true, syncedVendorIds: ["v1"])
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(SyncConfiguration.self, from: data)
        
        XCTAssertEqual(decodedConfig.isSyncEnabled, config.isSyncEnabled)
        XCTAssertEqual(decodedConfig.syncedVendorIds, config.syncedVendorIds)
    }
}
