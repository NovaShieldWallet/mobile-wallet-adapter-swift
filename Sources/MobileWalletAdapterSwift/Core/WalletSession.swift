import Foundation

/// Manages wallet session state, including connected origins and permissions.
public final class WalletSession {
    public static let shared = WalletSession()
    
    private var connectedOrigins: Set<String> = []
    private let queue = DispatchQueue(label: "com.wallet.session")
    
    public init() {}
    
    /// Records that an origin has connected
    public func connect(origin: String) {
        queue.async {
            self.connectedOrigins.insert(origin)
        }
    }
    
    /// Records that an origin has disconnected
    public func disconnect(origin: String) {
        queue.async {
            self.connectedOrigins.remove(origin)
        }
    }
    
    /// Checks if an origin is connected
    public func isConnected(origin: String) -> Bool {
        return queue.sync {
            connectedOrigins.contains(origin)
        }
    }
    
    /// Gets all connected origins
    public var allConnectedOrigins: [String] {
        return queue.sync {
            Array(connectedOrigins)
        }
    }
    
    /// Clears all connections
    public func disconnectAll() {
        queue.async {
            self.connectedOrigins.removeAll()
        }
    }
}

/// Represents a wallet account
public struct WalletAccount {
    public let publicKey: PublicKey
    public let label: String?
    
    public init(publicKey: PublicKey, label: String? = nil) {
        self.publicKey = publicKey
        self.label = label
    }
}

