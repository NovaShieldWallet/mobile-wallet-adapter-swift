import Foundation

/// Parameters for signPayloads RPC request
public struct SignPayloadsParams: Codable, Sendable {
    /// Base64-encoded public key address
    public let address: String
    /// Array of base64-encoded payloads to sign
    public let payloads: [String]
}

/// Result type for signPayloads RPC request
public struct SignPayloadsResult: Codable, Sendable {
    /// Array of base64-encoded signatures
    public let signed_payloads: [String]
    
    public init(signed_payloads: [String]) {
        self.signed_payloads = signed_payloads
    }
}

/// Method identifier for signPayloads request
public let SIGN_PAYLOADS_REQUEST_METHOD = "signPayloads"

