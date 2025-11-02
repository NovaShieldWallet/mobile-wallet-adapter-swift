import Foundation

/// Utility for storing and retrieving KeyPair from UserDefaults
public struct KeypairStorage {
    private let defaults: UserDefaults
    private let key: String
    
    /// Initialize with a UserDefaults suite and key
    /// - Parameters:
    ///   - suiteName: App Group ID for shared storage (e.g., "group.your.app")
    ///   - key: Key to store the keypair under (default: "solana.keypair")
    public init(suiteName: String, key: String = "solana.keypair") {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to initialize UserDefaults with suite name: \(suiteName)")
        }
        self.defaults = defaults
        self.key = key
    }
    
    /// Generate and store a new Ed25519 keypair
    /// - Returns: The generated KeyPair
    @discardableResult
    public func generateAndStore() -> KeyPair {
        let keypair = KeyPair.generate()!
        store(keypair)
        return keypair
    }
    
    /// Store a keypair
    /// - Parameter keypair: The keypair to store
    public func store(_ keypair: KeyPair) {
        let data: [String: String] = [
            "publicKey": Base58.fromBytes(keypair.publicKey.bytes),
            "privateKey": Base58.fromBytes(keypair.privateKey.bytes)
        ]
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                defaults.set(jsonString, forKey: key)
            }
        } catch {
            print("Failed to store keypair: \(error)")
        }
    }
    
    /// Load stored keypair
    /// - Returns: The stored KeyPair, or nil if not found
    public func load() -> KeyPair? {
        guard let jsonString = defaults.string(forKey: key),
              let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let data = try JSONDecoder().decode([String: String].self, from: jsonData)
            guard let bs58PublicKey = data["publicKey"],
                  let bs58PrivKey = data["privateKey"],
                  let publicKey = Key32(base58: bs58PublicKey),
                  let privateKey = Key64(base58: bs58PrivKey) else {
                return nil
            }
            return KeyPair(publicKey: publicKey, privateKey: privateKey)
        } catch {
            print("Failed to load keypair: \(error)")
            return nil
        }
    }
    
    /// Get or create a keypair (generates if doesn't exist)
    /// - Returns: The existing or newly generated KeyPair
    public func getOrCreate() -> KeyPair {
        if let existing = load() {
            return existing
        }
        return generateAndStore()
    }
    
    /// Delete stored keypair
    public func delete() {
        defaults.removeObject(forKey: key)
    }
}

