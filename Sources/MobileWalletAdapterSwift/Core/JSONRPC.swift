import Foundation

/// JSON-RPC 2.0 protocol handler
public enum JSONRPC {
    /// Parses a JSON-RPC request from data
    public static func parseRequest(_ data: Data) throws -> JSONRPCRequest {
        return try JSONDecoder().decode(JSONRPCRequest.self, from: data)
    }
    
    /// Encodes a JSON-RPC response to data
    public static func encodeResponse(_ response: JSONRPCResponse) throws -> Data {
        return try JSONEncoder().encode(response)
    }
    
    /// Encodes a JSON-RPC request to data
    public static func encodeRequest(_ request: JSONRPCRequest) throws -> Data {
        return try JSONEncoder().encode(request)
    }
    
    /// Creates a success response
    public static func successResponse(id: Int, result: JSONRPCResult) -> JSONRPCResponse {
        return JSONRPCResponse(id: id, result: result, error: nil)
    }
    
    /// Creates an error response
    public static func errorResponse(id: Int, error: JSONRPCError) -> JSONRPCResponse {
        return JSONRPCResponse(id: id, result: nil, error: error)
    }
}

