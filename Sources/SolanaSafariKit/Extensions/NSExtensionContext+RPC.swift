import Foundation
import SafariServices

public extension NSExtensionContext {
    
    /// Retrieves the request ID from the RPC request
    func requestId() -> String? {
        guard let item = self.inputItems.first as? NSExtensionItem,
              let rawMessage = item.userInfo?[SFExtensionMessageKey] as? [String: Any],
              let id = rawMessage["id"] as? String else {
            return nil
        }
        return id
    }
    
    /// Retrieves the method name from the RPC request
    func requestMethod() -> String? {
        guard let item = self.inputItems.first as? NSExtensionItem,
              let rawMessage = item.userInfo?[SFExtensionMessageKey] as? [String: Any],
              let method = rawMessage["method"] as? String else {
            return nil
        }
        return method
    }
    
    /// Decodes RPC request parameters into a specified Decodable type
    /// - Parameter type: The type to decode into
    /// - Returns: An instance of the specified type, or nil if decoding fails
    func decodeRpcRequestParameter<T: Decodable>(toType type: T.Type = T.self) -> T? {
        guard let item = self.inputItems.first as? NSExtensionItem,
              let rawMessage = item.userInfo?[SFExtensionMessageKey] as? [String: Any],
              let paramsJsonString = rawMessage["params"] as? String else {
            return nil
        }
        
        guard let jsonData = paramsJsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let params = try decoder.decode(T.self, from: jsonData)
            return params
        } catch {
            return nil
        }
    }
    
    /// Completes the RPC request with a success result
    /// - Parameter result: The result to encode and return
    func completeRpcRequestWith<T: Encodable>(result: T) {
        do {
            let encoder = JSONEncoder()
            let resultJsonData = try encoder.encode(result)
            let resultJsonString = String(data: resultJsonData, encoding: .utf8)
            
            let response = NSExtensionItem()
            response.userInfo = [
                SFExtensionMessageKey: [
                    "jsonrpc": "2.0",
                    "id": self.requestId() as Any,
                    "result": resultJsonString as Any,
                    "error": NSNull()
                ]
            ]
            self.completeRequest(returningItems: [response])
        } catch {
            self.completeRpcRequestWith(error: WalletlibRpcErrors.internalError)
        }
    }
    
    /// Completes the RPC request with an error
    /// - Parameter error: Dictionary containing error information
    func completeRpcRequestWith(error: [String: Any]) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: error]
        self.completeRequest(returningItems: [response])
    }
    
    /// Completes the RPC request with an error code and message
    /// - Parameters:
    ///   - errorCode: The error code
    ///   - errorMessage: The error message
    func completeRpcRequestWith(errorCode: Int, errorMessage: String) {
        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: [
                "jsonrpc": "2.0",
                "id": self.requestId() as Any,
                "result": NSNull(),
                "error": [
                    "code": errorCode,
                    "message": errorMessage
                ]
            ]
        ]
        self.completeRequest(returningItems: [response])
    }
}

