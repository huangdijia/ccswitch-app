import Foundation

/// Protocol for iCloud storage operations
/// This allows for different implementations (KVS, CloudKit) and improved testability
protocol CloudStorageService {
    /// Save a value to cloud storage
    /// - Parameters:
    ///   - value: The value to save
    ///   - key: The key to associate with the value
    func set(_ value: Any?, forKey key: String)
    
    /// Retrieve a value from cloud storage
    /// - Parameter key: The key associated with the value
    /// - Returns: The value if found, nil otherwise
    func object(forKey key: String) -> Any?
    
    /// Remove a value from cloud storage
    /// - Parameter key: The key to remove
    func removeObject(forKey key: String)
    
    /// Synchronize local storage with the cloud
    /// - Returns: true if successful, false otherwise
    func synchronize() -> Bool
}

extension CloudStorageService {
    /// Save a Codable value to cloud storage
    /// - Parameters:
    ///   - value: The value to save
    ///   - key: The key to associate with the value
    func setCodable<T: Encodable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        set(data, forKey: key)
    }
    
    /// Retrieve a Decodable value from cloud storage
    /// - Parameters:
    ///   - type: The type to decode
    ///   - key: The key associated with the value
    /// - Returns: The decoded value if found, nil otherwise
    func objectCodable<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = object(forKey: key) as? Data else { return nil }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}