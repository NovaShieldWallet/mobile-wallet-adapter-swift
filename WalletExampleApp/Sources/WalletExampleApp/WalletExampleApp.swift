import SwiftUI
import MobileWalletAdapterSwift

@main
struct WalletExampleApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    setupWallet()
                }
        }
    }
    
    private func setupWallet() {
        // Configure approval handler
        ApprovalCoordinator.shared.setApprovalHandler { request in
            await appState.handleApprovalRequest(request)
        }
        
        // Start listening for extension requests
        ExtensionBridge.shared.startListening()
    }
}

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    @Published var isOnboarded = false
    @Published var publicKey: PublicKey?
    @Published var connectedOrigins: [String] = []
    @Published var pendingApprovals: [ApprovalRequest] = []
    @Published var settings = WalletSettings()
    
    private let adapter = MobileWalletAdapter.shared
    private let keychain = Ed25519Keychain()
    private let passkeyManager = PasskeyManager(
        rpID: Bundle.main.bundleIdentifier ?? "com.example.wallet",
        rpName: "Wallet Example"
    )
    private let sessionLock = SessionLock()
    
    init() {
        checkOnboardingStatus()
        loadConnectedOrigins()
    }
    
    private func checkOnboardingStatus() {
        // Check if keypair exists
        if let _ = try? keychain.loadPublicKey() {
            isOnboarded = true
            publicKey = try? keychain.loadPublicKey()
        }
    }
    
    private func loadConnectedOrigins() {
        connectedOrigins = WalletSession.shared.allConnectedOrigins
    }
    
    func completeOnboarding() async throws {
        // Generate keypair
        let pubKey = try keychain.createIfNeeded()
        publicKey = pubKey
        
        // Register passkey
        try await passkeyManager.register(username: pubKey.base58)
        
        isOnboarded = true
    }
    
    func handleApprovalRequest(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        // Add to pending approvals queue (triggers sheet display)
        pendingApprovals.append(request)
        
        // In a real app, the approval sheet will call approveRequest or rejectRequest
        // For now, we'll process it directly
        return try await processApprovalRequest(request)
    }
    
    func approveRequest(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        // Remove from pending
        if let index = pendingApprovals.firstIndex(where: { $0.id == request.id }) {
            pendingApprovals.remove(at: index)
        }
        return try await processApprovalRequest(request)
    }
    
    func rejectRequest(_ request: ApprovalRequest) {
        if let index = pendingApprovals.firstIndex(where: { $0.id == request.id }) {
            pendingApprovals.remove(at: index)
        }
    }
    
    private func processApprovalRequest(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        // Ensure session is unlocked
        if !sessionLock.isUnlocked {
            try await passkeyManager.authenticate(sessionLock: sessionLock)
        }
        
        // Process based on request type
        switch request.params {
        case .connect:
            WalletSession.shared.connect(origin: request.origin.absoluteString)
            connectedOrigins = WalletSession.shared.allConnectedOrigins
            let pubKey = adapter.publicKey
            return .approved(.connect(ConnectResult(publicKey: pubKey.base58)))
            
        case .signTransaction(let data):
            let signature = try adapter.signTransaction(data, origin: request.origin)
            return .approved(.sign(SignResult(signature: signature.base64EncodedString())))
            
        case .signMessage(let data):
            let signature = try adapter.signMessage(data, origin: request.origin)
            return .approved(.sign(SignResult(signature: signature.base64EncodedString())))
            
        case .sendTransaction(let txHash):
            return .approved(.sendTransaction(SendTransactionResult(signature: txHash)))
            
        case .signTransactions(let datas), .signAllTransactions(let datas):
            let signature = try adapter.signTransaction(datas.first ?? Data(), origin: request.origin)
            return .approved(.sign(SignResult(signature: signature.base64EncodedString())))
            
        case .signMessages(let datas), .signAllMessages(let datas):
            let signature = try adapter.signMessage(datas.first ?? Data(), origin: request.origin)
            return .approved(.sign(SignResult(signature: signature.base64EncodedString())))
        }
    }
    
    func disconnect(origin: String) {
        WalletSession.shared.disconnect(origin: origin)
        connectedOrigins = WalletSession.shared.allConnectedOrigins
    }
    
    func updateSettings(_ newSettings: WalletSettings) {
        settings = newSettings
        adapter.requirePasskeyPerRequest = newSettings.requirePasskeyPerRequest
        adapter.sessionTTL = newSettings.sessionTTL
    }
}

struct WalletSettings {
    var requirePasskeyPerRequest: Bool = false
    var sessionTTL: TimeInterval = 120
}

