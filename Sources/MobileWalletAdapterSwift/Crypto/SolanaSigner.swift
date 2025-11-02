import Foundation
import Sodium

/// Signs Solana messages and transactions using Ed25519.
public final class SolanaSigner {
    private let keychain: Ed25519Keychain
    
    public init(keychain: Ed25519Keychain) {
        self.keychain = keychain
    }
    
    /// Signs a raw message (pre-packed bytes).
    public func sign(message: Data) throws -> Data {
        return try keychain.sign(message)
    }
    
    /// Signs a Solana transaction.
    /// The transaction should be serialized using MessagePacking.
    public func signTransaction(_ transaction: SolanaTransaction) throws -> Data {
        let serialized = try MessagePacking.serializeTransaction(transaction)
        return try sign(message: serialized)
    }
    
    /// Verifies a signature against a message and public key.
    public static func verify(signature: Data, message: Data, publicKey: Data) throws -> Bool {
        guard signature.count == 64 else {
            throw SigningError.invalidSignatureLength
        }
        guard publicKey.count == 32 else {
            throw SigningError.invalidPublicKeyLength
        }
        
        let sodium = Sodium()
        return sodium.sign.verify(message: Array(message), publicKey: Array(publicKey), signature: Array(signature))
    }
}

// MARK: - SolanaTransaction

public struct SolanaTransaction {
    public let recentBlockhash: String
    public let feePayer: PublicKey
    public let instructions: [Instruction]
    public let signatures: [Signature]?
    
    public init(
        recentBlockhash: String,
        feePayer: PublicKey,
        instructions: [Instruction],
        signatures: [Signature]? = nil
    ) {
        self.recentBlockhash = recentBlockhash
        self.feePayer = feePayer
        self.instructions = instructions
        self.signatures = signatures
    }
}

public struct Instruction {
    public let programId: PublicKey
    public let accounts: [AccountMeta]
    public let data: Data
    
    public init(programId: PublicKey, accounts: [AccountMeta], data: Data) {
        self.programId = programId
        self.accounts = accounts
        self.data = data
    }
}

public struct AccountMeta {
    public let publicKey: PublicKey
    public let isSigner: Bool
    public let isWritable: Bool
    
    public init(publicKey: PublicKey, isSigner: Bool, isWritable: Bool) {
        self.publicKey = publicKey
        self.isSigner = isSigner
        self.isWritable = isWritable
    }
}

public struct Signature {
    public let publicKey: PublicKey
    public let signature: Data
}

// MARK: - SigningError

public enum SigningError: Error {
    case invalidSignatureLength
    case invalidPublicKeyLength
    case verificationFailed(Error)
    case serializationFailed
}

