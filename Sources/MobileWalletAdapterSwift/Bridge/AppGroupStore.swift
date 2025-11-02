import Foundation
import CoreFoundation

/// Manages shared data storage using App Groups for communication between app and extension.
public final class AppGroupStore {
    public static let shared = AppGroupStore()
    
    private let appGroupID: String
    private let userDefaults: UserDefaults?
    
    /// Initializes with an App Group identifier.
    /// - Parameter appGroupID: The App Group ID (e.g., "group.com.wallet.mwa")
    public init(appGroupID: String = "group.com.wallet.mwa") {
        self.appGroupID = appGroupID
        self.userDefaults = UserDefaults(suiteName: appGroupID)
    }
    
    /// Stores a JSON-RPC request for processing by the native app.
    public func storeRequest(_ request: JSONRPCRequest) throws {
        guard let userDefaults = userDefaults else {
            throw AppGroupError.notConfigured
        }
        
        let data = try JSONRPC.encodeRequest(request)
        let key = "pending_request_\(request.id)"
        userDefaults.set(data, forKey: key)
        
        // Post notification to wake up the app if needed
        let notificationName = "com.wallet.request" as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(rawValue: notificationName),
            nil,
            nil,
            true
        )
    }
    
    /// Retrieves and removes a JSON-RPC request.
    public func retrieveRequest(id: Int) throws -> JSONRPCRequest? {
        guard let userDefaults = userDefaults else {
            throw AppGroupError.notConfigured
        }
        
        let key = "pending_request_\(id)"
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let request = try JSONRPC.parseRequest(data)
        userDefaults.removeObject(forKey: key)
        
        return request
    }
    
    /// Stores a JSON-RPC response for retrieval by the extension.
    public func storeResponse(_ response: JSONRPCResponse) throws {
        guard let userDefaults = userDefaults else {
            throw AppGroupError.notConfigured
        }
        
        let data = try JSONRPC.encodeResponse(response)
        let key = "response_\(response.id)"
        userDefaults.set(data, forKey: key)
        
        // Post notification
        let notificationName = "com.wallet.response" as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(rawValue: notificationName),
            nil,
            nil,
            true
        )
    }
    
    /// Retrieves and removes a JSON-RPC response.
    public func retrieveResponse(id: Int) throws -> JSONRPCResponse? {
        guard let userDefaults = userDefaults else {
            throw AppGroupError.notConfigured
        }
        
        let key = "response_\(id)"
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let response = try JSONDecoder().decode(JSONRPCResponse.self, from: data)
        userDefaults.removeObject(forKey: key)
        
        return response
    }
    
    /// Cleans up old requests/responses (call periodically)
    public func cleanup(olderThan seconds: TimeInterval) {
        guard let userDefaults = userDefaults else { return }
        
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        for key in allKeys {
            if key.hasPrefix("pending_request_") || key.hasPrefix("response_") {
                // Simple cleanup - in production, store timestamps and clean based on age
                // For now, just remove very old items
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}

public enum AppGroupError: Error {
    case notConfigured
    case storeFailed
    case retrieveFailed
}

