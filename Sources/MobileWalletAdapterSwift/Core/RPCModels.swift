import Foundation

/// JSON-RPC 2.0 request model
public struct JSONRPCRequest: Codable {
    public let jsonrpc: String
    public let id: Int
    public let method: String
    public let params: JSONRPCParams
    
    public init(jsonrpc: String = "2.0", id: Int, method: String, params: JSONRPCParams) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.method = method
        self.params = params
    }
}

/// JSON-RPC 2.0 response model
public struct JSONRPCResponse: Codable {
    public let jsonrpc: String
    public let id: Int
    public let result: JSONRPCResult?
    public let error: JSONRPCError?
    
    public init(jsonrpc: String = "2.0", id: Int, result: JSONRPCResult? = nil, error: JSONRPCError? = nil) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.result = result
        self.error = error
    }
}

/// JSON-RPC parameters (union type)
public enum JSONRPCParams: Codable {
    case connect(ConnectParams)
    case signTransaction(SignTransactionParams)
    case signMessage(SignMessageParams)
    case sendTransaction(SendTransactionParams)
    case signTransactions(SignTransactionsParams)
    case signMessages(SignMessagesParams)
    case signAllTransactions(SignAllTransactionsParams)
    case signAllMessages(SignAllMessagesParams)
    
    enum CodingKeys: String, CodingKey {
        case origin, tx, message, transactions, messages, txHash
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .connect(let params):
            try container.encode(params)
        case .signTransaction(let params):
            try container.encode(params)
        case .signMessage(let params):
            try container.encode(params)
        case .sendTransaction(let params):
            try container.encode(params)
        case .signTransactions(let params):
            try container.encode(params)
        case .signMessages(let params):
            try container.encode(params)
        case .signAllTransactions(let params):
            try container.encode(params)
        case .signAllMessages(let params):
            try container.encode(params)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let connect = try? container.decode(ConnectParams.self) {
            self = .connect(connect)
        } else if let signTx = try? container.decode(SignTransactionParams.self) {
            self = .signTransaction(signTx)
        } else if let signMsg = try? container.decode(SignMessageParams.self) {
            self = .signMessage(signMsg)
        } else if let sendTx = try? container.decode(SendTransactionParams.self) {
            self = .sendTransaction(sendTx)
        } else if let signTxs = try? container.decode(SignTransactionsParams.self) {
            self = .signTransactions(signTxs)
        } else if let signMsgs = try? container.decode(SignMessagesParams.self) {
            self = .signMessages(signMsgs)
        } else if let signAllTxs = try? container.decode(SignAllTransactionsParams.self) {
            self = .signAllTransactions(signAllTxs)
        } else if let signAllMsgs = try? container.decode(SignAllMessagesParams.self) {
            self = .signAllMessages(signAllMsgs)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown params type")
        }
    }
}

public struct SignAllTransactionsParams: Codable {
    public let origin: String
    public let transactions: [String] // Array of base64 encoded transactions
    
    public init(origin: String, transactions: [String]) {
        self.origin = origin
        self.transactions = transactions
    }
}

public struct SignAllMessagesParams: Codable {
    public let origin: String
    public let messages: [String] // Array of base64 encoded messages
    
    public init(origin: String, messages: [String]) {
        self.origin = origin
        self.messages = messages
    }
}

public struct ConnectParams: Codable {
    public let origin: String
    public let cluster: String?
    
    public init(origin: String, cluster: String? = nil) {
        self.origin = origin
        self.cluster = cluster
    }
}

public struct SignTransactionParams: Codable {
    public let origin: String
    public let tx: String // Base64 encoded transaction
    
    public init(origin: String, tx: String) {
        self.origin = origin
        self.tx = tx
    }
}

public struct SignMessageParams: Codable {
    public let origin: String
    public let message: String // Base64 encoded message
    
    public init(origin: String, message: String) {
        self.origin = origin
        self.message = message
    }
}

public struct SendTransactionParams: Codable {
    public let origin: String
    public let txHash: String // Transaction signature after signing
    
    public init(origin: String, txHash: String) {
        self.origin = origin
        self.txHash = txHash
    }
}

public struct SignTransactionsParams: Codable {
    public let origin: String
    public let transactions: [String] // Array of base64 encoded transactions
    
    public init(origin: String, transactions: [String]) {
        self.origin = origin
        self.transactions = transactions
    }
}

public struct SignMessagesParams: Codable {
    public let origin: String
    public let messages: [String] // Array of base64 encoded messages
    
    public init(origin: String, messages: [String]) {
        self.origin = origin
        self.messages = messages
    }
}

/// JSON-RPC result (union type)
public enum JSONRPCResult: Codable {
    case connect(ConnectResult)
    case sign(SignResult)
    case sendTransaction(SendTransactionResult)
    case error(JSONRPCError)
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .connect(let result):
            try container.encode(result)
        case .sign(let result):
            try container.encode(result)
        case .sendTransaction(let result):
            try container.encode(result)
        case .error(let error):
            try container.encode(error)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let connect = try? container.decode(ConnectResult.self) {
            self = .connect(connect)
        } else if let sign = try? container.decode(SignResult.self) {
            self = .sign(sign)
        } else if let send = try? container.decode(SendTransactionResult.self) {
            self = .sendTransaction(send)
        } else if let error = try? container.decode(JSONRPCError.self) {
            self = .error(error)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown result type")
        }
    }
}

public struct ConnectResult: Codable {
    public let publicKey: String // Base58 encoded public key
    public let accountLabel: String?
    
    public init(publicKey: String, accountLabel: String? = nil) {
        self.publicKey = publicKey
        self.accountLabel = accountLabel
    }
}

public struct SignResult: Codable {
    public let signature: String // Base64 encoded signature
    
    public init(signature: String) {
        self.signature = signature
    }
}

public struct SendTransactionResult: Codable {
    public let signature: String // Transaction signature
    
    public init(signature: String) {
        self.signature = signature
    }
}

public struct JSONRPCError: Codable {
    public let code: Int
    public let message: String
    public let data: String?
    
    public init(code: Int, message: String, data: String? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    public static let userRejected = JSONRPCError(code: 4001, message: "User rejected the request")
    public static let unauthorized = JSONRPCError(code: 4100, message: "Unauthorized")
    public static let sessionLocked = JSONRPCError(code: 4101, message: "Session is locked. Passkey authentication required.")
    public static let unsupportedMethod = JSONRPCError(code: -32601, message: "Method not found")
}

