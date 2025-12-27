import Foundation
@testable import CCSwitch

class MockCloudStorageService: CloudStorageService {
    var storage: [String: Any] = [:]
    var synchronizeCalled = false
    
    func set(_ value: Any?, forKey key: String) {
        if let value = value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
    }
    
    func object(forKey key: String) -> Any? {
        return storage[key]
    }
    
    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
    
    func synchronize() -> Bool {
        synchronizeCalled = true
        return true
    }
}
