import XCTest
@testable import CCSwitch

final class CloudStorageServiceTests: XCTestCase {
    var mockService: MockCloudStorageService!
    
    override func setUp() {
        super.setUp()
        mockService = MockCloudStorageService()
    }
    
    func testSetAndObject() {
        mockService.set("value", forKey: "key")
        XCTAssertEqual(mockService.object(forKey: "key") as? String, "value")
    }
    
    func testRemoveObject() {
        mockService.set("value", forKey: "key")
        mockService.removeObject(forKey: "key")
        XCTAssertNil(mockService.object(forKey: "key"))
    }
    
    func testSynchronize() {
        let result = mockService.synchronize()
        XCTAssertTrue(result)
        XCTAssertTrue(mockService.synchronizeCalled)
    }
    
    func testCodableSupport() throws {
        let config = SyncConfiguration(isSyncEnabled: true, syncedVendorIds: ["v1"])
        
        try mockService.setCodable(config, forKey: "sync_config")
        
        let decoded: SyncConfiguration? = try mockService.objectCodable(SyncConfiguration.self, forKey: "sync_config")
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.isSyncEnabled, true)
        XCTAssertEqual(decoded?.syncedVendorIds, ["v1"])
    }
    
    func testCodableMissingKey() throws {
        let decoded: SyncConfiguration? = try mockService.objectCodable(SyncConfiguration.self, forKey: "missing")
        XCTAssertNil(decoded)
    }
}