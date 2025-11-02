import Foundation

/// Handles canonical serialization of Solana messages and transactions.
public enum MessagePacking {
    /// Serializes a Solana transaction into the canonical byte format.
    /// Format: [signature_count, signatures..., message]
    public static func serializeTransaction(_ transaction: SolanaTransaction) throws -> Data {
        var data = Data()
        
        // Signature count (compact-u16)
        let sigCount = transaction.signatures?.count ?? 0
        data.append(contentsOf: compactU16(UInt16(sigCount)))
        
        // Signatures (if present)
        if let signatures = transaction.signatures {
            for sig in signatures {
                data.append(sig.signature)
            }
        }
        
        // Serialize message
        let message = try serializeMessage(
            recentBlockhash: transaction.recentBlockhash,
            feePayer: transaction.feePayer,
            instructions: transaction.instructions
        )
        data.append(message)
        
        return data
    }
    
    /// Serializes a Solana message (transaction without signatures).
    /// Format: [header, account_addresses[], recent_blockhash, instructions[]]
    private static func serializeMessage(
        recentBlockhash: String,
        feePayer: PublicKey,
        instructions: [Instruction]
    ) throws -> Data {
        var data = Data()
        
        // Collect all account keys
        var accounts = Set<AccountKey>()
        accounts.insert(AccountKey(key: feePayer, isSigner: true, isWritable: true))
        
        for instruction in instructions {
            accounts.insert(AccountKey(key: instruction.programId, isSigner: false, isWritable: false))
            for account in instruction.accounts {
                accounts.insert(AccountKey(
                    key: account.publicKey,
                    isSigner: account.isSigner,
                    isWritable: account.isWritable
                ))
            }
        }
        
        // Sort: signers first (writable, then readonly), then non-signers (writable, then readonly)
        let sortedAccounts = accounts.sorted { a, b in
            if a.isSigner != b.isSigner {
                return a.isSigner
            }
            if a.isWritable != b.isWritable {
                return a.isWritable
            }
            return a.key.data.lexicographicallyPrecedes(b.key.data)
        }
        
        // Header: num_required_signatures (u8), num_readonly_signed_accounts (u8), num_readonly_unsigned_accounts (u8)
        let numSigners = sortedAccounts.filter { $0.isSigner }.count
        let numReadonlySigned = sortedAccounts.filter { $0.isSigner && !$0.isWritable }.count
        let numReadonlyUnsigned = sortedAccounts.filter { !$0.isSigner && !$0.isWritable }.count
        
        data.append(UInt8(numSigners))
        data.append(UInt8(numReadonlySigned))
        data.append(UInt8(numReadonlyUnsigned))
        
        // Account addresses
        for account in sortedAccounts {
            data.append(account.key.data)
        }
        
        // Recent blockhash (base58 decoded, 32 bytes)
        guard let blockhashData = Base58.decode(recentBlockhash),
              blockhashData.count == 32 else {
            throw MessagePackingError.invalidBlockhash
        }
        data.append(blockhashData)
        
        // Instructions
        data.append(contentsOf: compactU16(UInt16(instructions.count)))
        
        for instruction in instructions {
            // Program ID index
            let programIndex = sortedAccounts.firstIndex { $0.key.data == instruction.programId.data }!
            data.append(UInt8(programIndex))
            
            // Account indices (compact-u16 array)
            var accountIndices: [UInt8] = []
            for account in instruction.accounts {
                let index = sortedAccounts.firstIndex { $0.key.data == account.publicKey.data }!
                accountIndices.append(UInt8(index))
            }
            data.append(contentsOf: compactU16(UInt16(accountIndices.count)))
            data.append(contentsOf: accountIndices)
            
            // Instruction data (compact-u16 length + data)
            data.append(contentsOf: compactU16(UInt16(instruction.data.count)))
            data.append(instruction.data)
        }
        
        return data
    }
    
    /// Compact-u16 encoding used by Solana
    private static func compactU16(_ value: UInt16) -> Data {
        var data = Data()
        var val = value
        
        repeat {
            var byte = UInt8(val & 0x7F)
            val >>= 7
            if val > 0 {
                byte |= 0x80
            }
            data.append(byte)
        } while val > 0
        
        return data
    }
}

// MARK: - Helper Types

private struct AccountKey: Hashable {
    let key: PublicKey
    let isSigner: Bool
    let isWritable: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key.data)
    }
    
    static func == (lhs: AccountKey, rhs: AccountKey) -> Bool {
        lhs.key.data == rhs.key.data
    }
}

public enum MessagePackingError: Error {
    case invalidBlockhash
    case serializationFailed
}

