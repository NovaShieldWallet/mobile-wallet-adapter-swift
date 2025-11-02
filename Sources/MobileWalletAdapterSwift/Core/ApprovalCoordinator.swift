import Foundation

/// Coordinates approval requests from extensions, queuing and presenting approval UI.
public final class ApprovalCoordinator {
    public static let shared = ApprovalCoordinator()
    
    private var pendingRequests: [PendingRequest] = []
    private let queue = DispatchQueue(label: "com.wallet.approvalqueue")
    private var approvalHandler: ((ApprovalRequest) async throws -> ApprovalResponse)?
    
    public init() {}
    
    /// Sets the handler for presenting approval UI and processing approvals.
    public func setApprovalHandler(_ handler: @escaping (ApprovalRequest) async throws -> ApprovalResponse) {
        queue.sync {
            self.approvalHandler = handler
        }
    }
    
    /// Queues an approval request and waits for user approval.
    public func requestApproval(_ request: ApprovalRequest) async throws -> ApprovalResponse {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let pending = PendingRequest(request: request, continuation: continuation)
                self.pendingRequests.append(pending)
                
                // Process the request if handler is set
                if let handler = self.approvalHandler {
                    Task {
                        do {
                            let response = try await handler(request)
                            self.completeRequest(pending, response: response)
                        } catch {
                            self.failRequest(pending, error: error)
                        }
                    }
                }
            }
        }
    }
    
    private func completeRequest(_ pending: PendingRequest, response: ApprovalResponse) {
        queue.async {
            if let index = self.pendingRequests.firstIndex(where: { $0.id == pending.id }) {
                self.pendingRequests.remove(at: index)
            }
            pending.continuation.resume(returning: response)
        }
    }
    
    private func failRequest(_ pending: PendingRequest, error: Error) {
        queue.async {
            if let index = self.pendingRequests.firstIndex(where: { $0.id == pending.id }) {
                self.pendingRequests.remove(at: index)
            }
            pending.continuation.resume(throwing: error)
        }
    }
    
    /// Gets pending requests for a specific origin
    public func pendingRequests(for origin: String) -> [ApprovalRequest] {
        return queue.sync {
            pendingRequests.filter { $0.request.origin.absoluteString == origin }.map { $0.request }
        }
    }
}

private struct PendingRequest {
    let id = UUID()
    let request: ApprovalRequest
    let continuation: CheckedContinuation<ApprovalResponse, Error>
}

/// Represents an approval request from a dApp
public struct ApprovalRequest {
    public let id: Int
    public let method: String
    public let origin: URL
    public let params: ApprovalParams
    
    public init(id: Int, method: String, origin: URL, params: ApprovalParams) {
        self.id = id
        self.method = method
        self.origin = origin
        self.params = params
    }
}

/// Union type for different approval parameter types
public enum ApprovalParams {
    case connect
    case signTransaction(Data)
    case signMessage(Data)
    case sendTransaction(String)
    case signTransactions([Data])
    case signMessages([Data])
    case signAllTransactions([Data])
    case signAllMessages([Data])
}

/// Represents an approval response
public enum ApprovalResponse {
    case approved(JSONRPCResult)
    case rejected
}

