import Foundation

/// RPC error structure
public struct RPCError: Sendable {
    public let code: Int
    public let message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}

/// Standard RPC error codes
public enum WalletlibRpcErrors {
    /// Parse error (-32700)
    public static var parseError: [String: Any] {
        makeError(code: -32700, message: "Parse error")
    }
    
    /// Invalid request (-32600)
    public static var invalidRequest: [String: Any] {
        makeError(code: -32600, message: "Invalid Request")
    }
    
    /// Method not found (-32601)
    public static var methodNotFound: [String: Any] {
        makeError(code: -32601, message: "Method not found")
    }
    
    /// Invalid params (-32602)
    public static var invalidParams: [String: Any] {
        makeError(code: -32602, message: "Invalid params")
    }
    
    /// Internal error (-32603)
    public static var internalError: [String: Any] {
        makeError(code: -32603, message: "Internal error")
    }
    
    /// Payload not signed (-3)
    public static var notSigned: [String: Any] {
        makeError(code: -3, message: "Payload not signed")
    }
    
    private static func makeError(code: Int, message: String) -> [String: Any] {
        return ["error": ["code": code, "message": message]]
    }
}

