import Foundation

/// Result type for getAccounts RPC request
public struct GetAccountsResult: Codable, Sendable {
    /// Array of base64-encoded public keys
    public let addresses: [String]
    
    public init(addresses: [String]) {
        self.addresses = addresses
    }
}

/// Method identifier for getAccounts request
public let GET_ACCOUNTS_REQUEST_METHOD = "getAccounts"

