import Foundation

/// Implementation of CloudStorageService using NSUbiquitousKeyValueStore
class ICloudStorageService: CloudStorageService {
    private let store: NSUbiquitousKeyValueStore
    
    init(store: NSUbiquitousKeyValueStore = .default) {
        self.store = store
    }
    
    func set(_ value: Any?, forKey key: String) {
        store.set(value, forKey: key)
    }
    
    func object(forKey key: String) -> Any? {
        return store.object(forKey: key)
    }
    
    func removeObject(forKey key: String) {
        store.removeObject(forKey: key)
    }
    
    func synchronize() -> Bool {
        return store.synchronize()
    }
}
