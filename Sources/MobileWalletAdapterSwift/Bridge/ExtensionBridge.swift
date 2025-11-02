import Foundation

/// Bridges communication between Safari Web Extension and native app.
public final class ExtensionBridge {
    public static let shared = ExtensionBridge()
    
    private let store: AppGroupStore
    private let coordinator: ApprovalCoordinator
    private let session: WalletSession
    
    public init(store: AppGroupStore = .shared, coordinator: ApprovalCoordinator = .shared, session: WalletSession = .shared) {
        self.store = store
        self.coordinator = coordinator
        self.session = session
    }
    
    /// Processes a JSON-RPC request from the extension.
    public func handleRequest(_ request: JSONRPCRequest) async throws -> JSONRPCResponse {
        guard let originURL = URL(string: request.params.encodeOrigin() ?? "") else {
            return JSONRPC.errorResponse(id: request.id, error: JSONRPCError(code: -32602, message: "Invalid origin"))
        }
        
        let approvalParams = try request.params.toApprovalParams()
        let approvalRequest = ApprovalRequest(
            id: request.id,
            method: request.method,
            origin: originURL,
            params: approvalParams
        )
        
        let response = try await coordinator.requestApproval(approvalRequest)
        
        switch response {
        case .approved(let result):
            return JSONRPC.successResponse(id: request.id, result: result)
        case .rejected:
            return JSONRPC.errorResponse(id: request.id, error: .userRejected)
        }
    }
    
    /// Listens for incoming requests from the extension and processes them.
    public func startListening() {
        // In a real implementation, this would set up CFNotificationCenter observers
        // For now, the extension will call handleRequest directly or via URL scheme
    }
}

// MARK: - Helper Extensions

extension JSONRPCParams {
    func encodeOrigin() -> String? {
        switch self {
        case .connect(let params):
            return params.origin
        case .signTransaction(let params):
            return params.origin
        case .signMessage(let params):
            return params.origin
        case .sendTransaction(let params):
            return params.origin
        case .signTransactions(let params):
            return params.origin
        case .signMessages(let params):
            return params.origin
        case .signAllTransactions(let params):
            return params.origin
        case .signAllMessages(let params):
            return params.origin
        }
    }
    
    func toApprovalParams() throws -> ApprovalParams {
        switch self {
        case .connect:
            return .connect
        case .signTransaction(let params):
            guard let data = Data(base64Encoded: params.tx) else {
                throw ExtensionBridgeError.invalidTransactionData
            }
            return .signTransaction(data)
        case .signMessage(let params):
            guard let data = Data(base64Encoded: params.message) else {
                throw ExtensionBridgeError.invalidMessageData
            }
            return .signMessage(data)
        case .sendTransaction(let params):
            return .sendTransaction(params.txHash)
        case .signTransactions(let params):
            let datas = try params.transactions.map { tx in
                guard let data = Data(base64Encoded: tx) else {
                    throw ExtensionBridgeError.invalidTransactionData
                }
                return data
            }
            return .signTransactions(datas)
        case .signMessages(let params):
            let datas = try params.messages.map { msg in
                guard let data = Data(base64Encoded: msg) else {
                    throw ExtensionBridgeError.invalidMessageData
                }
                return data
            }
            return .signMessages(datas)
        case .signAllTransactions(let params):
            let datas = try params.transactions.map { tx in
                guard let data = Data(base64Encoded: tx) else {
                    throw ExtensionBridgeError.invalidTransactionData
                }
                return data
            }
            return .signAllTransactions(datas)
        case .signAllMessages(let params):
            let datas = try params.messages.map { msg in
                guard let data = Data(base64Encoded: msg) else {
                    throw ExtensionBridgeError.invalidMessageData
                }
                return data
            }
            return .signAllMessages(datas)
        }
    }
}

enum ExtensionBridgeError: Error {
    case invalidTransactionData
    case invalidMessageData
    case invalidOrigin
}

