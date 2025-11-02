import Foundation
import Security
import Sodium

/// Manages Ed25519 keypair generation and storage in iOS Keychain.
/// Private keys are never exported; only signing operations are performed.
public final class Ed25519Keychain {
    private let tag: String
    private let service = "com.wallet.mwa"
    private let sodium = Sodium()
    
    public init(tag: String = "default-ed25519-key") {
        self.tag = tag
    }
    
    /// Creates a new Ed25519 keypair if one doesn't exist, or returns the existing public key.
    @discardableResult
    public func createIfNeeded() throws -> PublicKey {
        if let existingPub = try? loadPublicKey() {
            return existingPub
        }
        
        // Generate Ed25519 keypair using Sodium
        guard let keyPair = sodium.sign.keyPair() else {
            throw KeychainError.generationFailed
        }
        
        // Store private key in Keychain (Sodium's private key is 64 bytes: seed + public key)
        // For Ed25519, we can extract the seed from the first 32 bytes
        let privateKeyData = Data(keyPair.secretKey)
        try storePrivateKey(privateKeyData)
        
        // Store public key reference
        let publicKeyData = Data(keyPair.publicKey)
        try storePublicKeyReference(publicKeyData)
        
        return PublicKey(publicKeyData)
    }
    
    /// Signs data using the stored Ed25519 private key.
    public func sign(_ data: Data) throws -> Data {
        let privateKeyData = try loadPrivateKey()
        guard let signature = sodium.sign.signature(message: Array(data), secretKey: Array(privateKeyData)) else {
            throw KeychainError.signingFailed
        }
        return Data(signature)
    }
    
    /// Returns the public key if a keypair exists.
    public func loadPublicKey() throws -> PublicKey {
        // Try to load from public key reference first
        if let pubKeyData = try? loadPublicKeyReference() {
            return PublicKey(pubKeyData)
        }
        
        // Fallback: derive from private key
        let privateKeyData = try loadPrivateKey()
        // For Ed25519, the public key is in bytes 32-64 of the private key
        guard privateKeyData.count >= 64 else {
            throw KeychainError.invalidData
        }
        let publicKeyData = privateKeyData.subdata(in: 32..<64)
        return PublicKey(publicKeyData)
    }
    
    // MARK: - Private Keychain Operations
    
    private func storePrivateKey(_ privateKey: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(tag).private",
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsPermanent as String: true,
            kSecValueData as String: privateKey,
            kSecReturnData as String: false
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    private func storePublicKeyReference(_ publicKey: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(tag).public",
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsPermanent as String: true,
            kSecValueData as String: publicKey,
            kSecReturnData as String: false
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    private func loadPublicKeyReference() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(tag).public",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.loadFailed(status)
        }
        
        guard data.count == 32 else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    private func loadPrivateKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(tag).private",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.loadFailed(status)
        }
        
        guard data.count == 64 else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    /// Deletes the stored keypair. Use with caution.
    public func delete() throws {
        // Delete both private and public key entries
        for accountSuffix in [".private", ".public"] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "\(tag)\(accountSuffix)"
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.deleteFailed(status)
            }
        }
    }
}

// MARK: - PublicKey

public struct PublicKey {
    public let data: Data
    
    public init(_ data: Data) {
        guard data.count == 32 else {
            fatalError("Ed25519 public key must be 32 bytes")
        }
        self.data = data
    }
    
    public init(fromPrivateKey privateKey: Data) throws {
        // Extract public key from private key (bytes 32-64)
        guard privateKey.count >= 64 else {
            throw KeychainError.invalidData
        }
        self.data = privateKey.subdata(in: 32..<64)
    }
    
    public var base58: String {
        // Simple base58 encoding (for Solana addresses)
        return Base58.encode(data)
    }
}

// MARK: - KeychainError

public enum KeychainError: Error {
    case generationFailed
    case storeFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData
    case signingFailed
}

