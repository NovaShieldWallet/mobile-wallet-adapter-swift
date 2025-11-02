import Foundation

/// Main public API for Mobile Wallet Adapter Swift.
/// Provides wallet functionality with passkey-gated unlock.
public protocol WalletService {
    var publicKey: PublicKey { get }
    func connect(origin: URL) async throws -> WalletAccount
    func signMessage(_ msg: Data, origin: URL) async throws -> Data
    func signTransaction(_ tx: Data, origin: URL) async throws -> Data
    func sendTransaction(_ tx: Data, origin: URL) async throws -> String
}

/// Main implementation of Mobile Wallet Adapter.
public final class MobileWalletAdapter: WalletService {
    public static let shared = MobileWalletAdapter()
    
    private let keychain: Ed25519Keychain
    private let signer: SolanaSigner
    private let sessionLock: SessionLock
    #if os(iOS)
    @available(iOS 16.0, *)
    private var passkeyManager: PasskeyManager?
    #endif
    private let session: WalletSession
    private let coordinator: ApprovalCoordinator
    
    /// Whether passkey authentication is required per request (true) or session-based (false)
    public var requirePasskeyPerRequest: Bool = false
    
    /// Session TTL in seconds (default: 120)
    public var sessionTTL: TimeInterval = 120
    
    private init() {
        self.keychain = Ed25519Keychain()
        self.signer = SolanaSigner(keychain: keychain)
        self.sessionLock = SessionLock()
        #if os(iOS)
        if #available(iOS 16.0, *) {
            self.passkeyManager = PasskeyManager()
        }
        #endif
        self.session = WalletSession.shared
        self.coordinator = ApprovalCoordinator.shared
        
        setupApprovalHandler()
    }
    
    /// Public key of the wallet
    public var publicKey: PublicKey {
        get {
            // Try to load existing, or create if needed
            do {
                return try keychain.loadPublicKey()
            } catch {
                // If load fails, try creating
                do {
                    return try keychain.createIfNeeded()
                } catch {
                    // Last resort: return a dummy key (shouldn't happen in practice)
                    fatalError("Failed to load or create public key: \(error)")
                }
            }
        }
    }
    
    /// Connects a dApp origin to the wallet
    public func connect(origin: URL) async throws -> WalletAccount {
        let originString = origin.absoluteString
        
        // Check if already connected
        if session.isConnected(origin: originString) {
            return WalletAccount(publicKey: try publicKey)
        }
        
        // Ensure session is unlocked
        try await ensureUnlocked()
        
        // Record connection
        session.connect(origin: originString)
        
        return WalletAccount(publicKey: try publicKey)
    }
    
    /// Signs a message
    public func signMessage(_ msg: Data, origin: URL) async throws -> Data {
        try await ensureUnlocked()
        
        guard session.isConnected(origin: origin.absoluteString) else {
            throw WalletError.notConnected
        }
        
        return try signer.sign(message: msg)
    }
    
    /// Signs a transaction
    public func signTransaction(_ tx: Data, origin: URL) async throws -> Data {
        try await ensureUnlocked()
        
        guard session.isConnected(origin: origin.absoluteString) else {
            throw WalletError.notConnected
        }
        
        return try signer.sign(message: tx)
    }
    
    /// Signs a transaction and returns the signature as a base58-encoded string.
    /// The dApp is responsible for submitting to a Solana RPC endpoint.
    /// Returns the transaction signature (base58 encoded).
    public func sendTransaction(_ tx: Data, origin: URL) async throws -> String {
        try await ensureUnlocked()
        
        guard session.isConnected(origin: origin.absoluteString) else {
            throw WalletError.notConnected
        }
        
        // Sign the transaction
        let signature = try signer.sign(message: tx)
        
        // Return signature as base58-encoded string
        // The dApp will use this signature to submit the transaction
        return Base58.encode(signature)
    }
    
    // MARK: - Private Helpers
    
    private func ensureUnlocked() async throws {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            if requirePasskeyPerRequest || !sessionLock.isUnlocked {
                guard let passkeyManager = passkeyManager else {
                    throw WalletError.internalError
                }
                try await passkeyManager.authenticate(sessionLock: sessionLock)
            }
        }
        #endif
        
        try sessionLock.requireUnlock()
    }
    
    private func setupApprovalHandler() {
        coordinator.setApprovalHandler { [weak self] request in
            guard let self = self else {
                throw WalletError.internalError
            }
            
            // In a real implementation, this would present UI and wait for user approval
            // For now, auto-approve for testing (DO NOT use in production)
            return try await self.processApprovalRequest(request)
        }
    }
    
    private func processApprovalRequest(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        // Ensure unlocked
        try await ensureUnlocked()
        
        switch request.params {
        case .connect:
            session.connect(origin: request.origin.absoluteString)
            let pubKey = try self.publicKey
            return .approved(.connect(ConnectResult(publicKey: pubKey.base58)))
            
        case .signTransaction(let data):
            let signature = try signer.sign(message: data)
            return .approved(.sign(SignResult(signature: signature.base64EncodedString())))
            
        case .signMessage(let data):
            let signature = try signer.sign(message: data)
            return .approved(.sign(SignResult(signature: signature.base64EncodedString())))
            
        case .signTransactions(let datas):
            // For multiple transactions, sign each and return array
            // Simplified: return first signature
            let signature = try signer.sign(message: datas.first ?? Data())
            return .approved(.sign(SignResult(signature: signature.base64EncodedString())))
            
        case .signMessages(let datas):
            // Simplified: return first signature
            let signature = try signer.sign(message: datas.first ?? Data())
            return .approved(.sign(SignResult(signature: signature.base64EncodedString())))
            
        case .signAllTransactions(let datas):
            // Sign all transactions
            let signatures = try datas.map { data in
                try signer.sign(message: data).base64EncodedString()
            }
            // Return array of signatures (would need SignAllResult type, using sign for now)
            return .approved(.sign(SignResult(signature: signatures.first ?? "")))
            
        case .signAllMessages(let datas):
            // Sign all messages
            let signatures = try datas.map { data in
                try signer.sign(message: data).base64EncodedString()
            }
            return .approved(.sign(SignResult(signature: signatures.first ?? "")))
            
        case .sendTransaction(let txHash):
            // Already signed, just return the hash
            return .approved(.sendTransaction(SendTransactionResult(signature: txHash)))
        }
    }
}

// MARK: - WalletError

public enum WalletError: Error {
    case notConnected
    case sessionLocked
    case internalError
    case signingFailed(Error)
}

extension Data {
    func base64EncodedString() -> String {
        return self.base64EncodedString()
    }
}

