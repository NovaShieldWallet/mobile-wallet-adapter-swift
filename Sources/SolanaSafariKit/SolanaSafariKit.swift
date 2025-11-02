import Foundation

/// SolanaSafariKit - Safari Extension integration for Solana wallets
///
/// This framework provides minimal helpers for Safari Web Extension integration:
/// - NSExtensionContext RPC helpers
/// - GetAccounts and SignPayloads models
/// - Standard RPC error types
/// - Pre-built JavaScript bundles
///
/// Example usage:
/// ```swift
/// import SafariServices
/// import SolanaSafariKit
///
/// class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
///     func beginRequest(with context: NSExtensionContext) {
///         guard let method = context.requestMethod() else {
///             context.completeRpcRequestWith(error: WalletlibRpcErrors.methodNotFound)
///             return
///         }
///
///         switch method {
///         case GET_ACCOUNTS_REQUEST_METHOD:
///             // Handle getAccounts
///         case SIGN_PAYLOADS_REQUEST_METHOD:
///             // Handle signPayloads
///         default:
///             context.completeRpcRequestWith(error: WalletlibRpcErrors.methodNotFound)
///         }
///     }
/// }
/// ```
public struct SolanaSafariKit {
    /// Framework version
    public static let version = "1.0.0"
}

