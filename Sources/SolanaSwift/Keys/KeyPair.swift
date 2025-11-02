//
//  KeyPair.swift
//  SolanaSwift
//
//  Simplified Ed25519 KeyPair implementation
//

import Foundation
import Ed25519

public struct KeyPair: Equatable, Codable, Hashable {
    
    public let publicKey: PublicKey
    public let privateKey: PrivateKey
    
    public init(publicKey: PublicKey, privateKey: PrivateKey) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    /// Generate a random Ed25519 keypair
    public static func generate() -> KeyPair? {
        var publicKeyBytes = [UInt8](repeating: 0, count: 32)
        var privateKeyBytes = [UInt8](repeating: 0, count: 64)
        
        ed25519_create_keypair(&publicKeyBytes, &privateKeyBytes, nil)
        
        guard let publicKey = Key32(publicKeyBytes),
              let privateKey = Key64(privateKeyBytes) else {
            return nil
        }
        
        return KeyPair(publicKey: publicKey, privateKey: privateKey)
    }
    
    /// Sign data with this keypair's private key
    public func sign(_ data: Data) -> Signature {
        var signatureBytes = [UInt8](repeating: 0, count: 64)
        let message = [UInt8](data)
        
        ed25519_sign(&signatureBytes, message, message.count, publicKey.bytes, privateKey.bytes)
        
        return Signature(signatureBytes)!
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case publicKey
        case privateKey
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let publicKeyData = try container.decode(Data.self, forKey: .publicKey)
        let privateKeyData = try container.decode(Data.self, forKey: .privateKey)
        
        guard let publicKey = Key32([UInt8](publicKeyData)),
              let privateKey = Key64([UInt8](privateKeyData)) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid key data"
                )
            )
        }
        
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(publicKey.data, forKey: .publicKey)
        try container.encode(privateKey.data, forKey: .privateKey)
    }
}
