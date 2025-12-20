import XCTest
@testable import CCSwitch

final class ConfigManagerTests: XCTestCase {
    var tempConfigDir: URL!
    var tempClaudeDir: URL!
    var configManager: ConfigManager!

    override func setUpWithError() throws {
        // 创建临时测试目录
        let tempDir = FileManager.default.temporaryDirectory
        tempConfigDir = tempDir.appendingPathComponent("ccswitch_test")
        tempClaudeDir = tempDir.appendingPathComponent("claude_test")

        // 设置测试配置路径
        testConfigURL = tempConfigDir.appendingPathComponent("ccs.json")
        testClaudeSettingsURL = tempClaudeDir.appendingPathComponent("settings.json")

        // 创建目录
        try FileManager.default.createDirectory(at: tempConfigDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tempClaudeDir, withIntermediateDirectories: true)

        // 创建测试用的 ConfigManager 实例
        configManager = TestConfigManager()
        configManager.initialize()
    }

    override func tearDownWithError() throws {
        // 清理临时文件
        try FileManager.default.removeItem(at: tempConfigDir)
        try FileManager.default.removeItem(at: tempClaudeDir)
    }

    func testCreateDefaultConfig() throws {
        // 测试创建默认配置
        let defaultConfig = CCSConfig.defaultConfig
        XCTAssertEqual(defaultConfig.version, 1)
        XCTAssertEqual(defaultConfig.current, "anthropic")
        XCTAssertEqual(defaultConfig.vendors.count, 2)
        XCTAssertEqual(defaultConfig.vendors[0].id, "anthropic")
        XCTAssertEqual(defaultConfig.vendors[1].id, "deepseek")
    }

    func testSaveAndLoadConfig() throws {
        // 创建测试配置
        let vendor = Vendor(
            id: "test",
            displayName: "Test Vendor",
            claudeSettingsPatch: ClaudeSettingsPatch(
                provider: "test",
                model: "test-model",
                apiKeyEnv: "TEST_API_KEY"
            )
        )

        let config = CCSConfig(
            version: 1,
            current: "test",
            vendors: [vendor]
        )

        // 保存配置
        let data = try JSONEncoder().encode(config)
        try data.write(to: testConfigURL)

        // 加载配置
        let loadedData = try Data(contentsOf: testConfigURL)
        let loadedConfig = try JSONDecoder().decode(CCSConfig.self, from: loadedData)

        XCTAssertEqual(loadedConfig.current, "test")
        XCTAssertEqual(loadedConfig.vendors.count, 1)
        XCTAssertEqual(loadedConfig.vendors[0].displayName, "Test Vendor")
    }

    func testAddVendor() throws {
        let newVendor = Vendor(
            id: "openai",
            displayName: "OpenAI",
            claudeSettingsPatch: ClaudeSettingsPatch(
                provider: "openai",
                model: "gpt-4",
                apiKeyEnv: "OPENAI_API_KEY"
            )
        )

        try configManager.addVendor(newVendor)

        let vendors = configManager.allVendors
        XCTAssertTrue(vendors.contains { $0.id == "openai" })
        XCTAssertEqual(vendors.count, 3) // 默认有2个，新增1个
    }

    func testRemoveVendor() throws {
        // 确保有多个供应商
        let vendors = configManager.allVendors
        XCTAssertGreaterThanOrEqual(vendors.count, 2)

        // 删除非当前供应商
        let vendorToRemove = vendors.first { $0.id != configManager.currentVendor?.id }!
        try configManager.removeVendor(with: vendorToRemove.id)

        let updatedVendors = configManager.allVendors
        XCTAssertFalse(updatedVendors.contains { $0.id == vendorToRemove.id })
    }

    func testSwitchVendor() throws {
        let originalVendor = configManager.currentVendor
        let targetVendor = configManager.allVendors.first { $0.id != originalVendor?.id }!

        try configManager.switchToVendor(with: targetVendor.id)

        let currentVendor = configManager.currentVendor
        XCTAssertEqual(currentVendor?.id, targetVendor.id)
        XCTAssertNotEqual(currentVendor?.id, originalVendor?.id)
    }

    func testInvalidVendorSwitch() throws {
        XCTAssertThrowsError(try configManager.switchToVendor(with: "invalid-id")) { error in
            XCTAssertTrue(error is ConfigError)
            if case ConfigError.vendorNotFound = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected vendorNotFound error")
            }
        }
    }

    func testDuplicateVendor() throws {
        let existingVendor = configManager.allVendors.first!

        XCTAssertThrowsError(try configManager.addVendor(existingVendor)) { error in
            XCTAssertTrue(error is ConfigError)
            if case ConfigError.vendorAlreadyExists = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected vendorAlreadyExists error")
            }
        }
    }
}

// MARK: - Test Helper Classes
private var testConfigURL: URL!
private var testClaudeSettingsURL: URL!

private class TestConfigManager: ConfigManager {
    override func initialize() {
        // 使用测试路径
        // 在实际实现中，需要修改 ConfigManager 以支持依赖注入或路径配置
        super.initialize()
    }
}

private extension URL {
    static var testConfigURL: URL {
        return testConfigURL
    }

    static var testClaudeSettingsURL: URL {
        return testClaudeSettingsURL
    }
}

// 需要在实际实现中为 CCSConfig 和 ClaudeSettings 添加测试路径支持
extension CCSConfig {
    static var testConfigFile: URL {
        return testConfigURL
    }
}

extension ClaudeSettings {
    static var testConfigFile: URL {
        return testClaudeSettingsURL
    }
}