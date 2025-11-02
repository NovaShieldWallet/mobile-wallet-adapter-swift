import Foundation

/// SolanaSwift - Core Solana crypto primitives for iOS
///
/// This framework provides essential Solana functionality:
/// - Ed25519 keypair generation and signing
/// - Base58 encoding/decoding
/// - Transaction serialization
/// - Public/Private key management
///
/// Example usage:
/// ```swift
/// import SolanaSwift
///
/// // Generate keypair
/// let keypair = KeyPair.generate()!
///
/// // Sign data
/// let signature = keypair.sign(messageData)
///
/// // Base58 encoding
/// let address = Base58.fromBytes(keypair.publicKey.bytes)
/// ```
public struct SolanaSwift {
    /// Framework version
    public static let version = "1.0.0"
}

