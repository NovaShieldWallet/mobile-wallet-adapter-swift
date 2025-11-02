import Testing
@testable import MobileWalletAdapterSwift

// MARK: - Keychain Tests

@Test func testKeychainCreation() async throws {
    let keychain = Ed25519Keychain(tag: "test-key-\(UUID().uuidString)")
    let pubKey = try keychain.createIfNeeded()
    #expect(pubKey.data.count == 32)
    
    // Create again should return same key
    let pubKey2 = try keychain.loadPublicKey()
    #expect(pubKey.data == pubKey2.data)
}

@Test func testKeychainSigning() async throws {
    let keychain = Ed25519Keychain(tag: "test-sign-\(UUID().uuidString)")
    _ = try keychain.createIfNeeded()
    
    let message = Data("Hello, Solana!".utf8)
    let signature = try keychain.sign(message)
    
    #expect(signature.count == 64) // Ed25519 signatures are 64 bytes
    
    // Verify signature (if verify method available)
    let pubKey = try keychain.loadPublicKey()
    #expect(pubKey.data.count == 32)
}

@Test func testKeychainDelete() async throws {
    let tag = "test-delete-\(UUID().uuidString)"
    let keychain = Ed25519Keychain(tag: tag)
    
    _ = try keychain.createIfNeeded()
    try keychain.delete()
    
    // Should throw when trying to load deleted key
    #expect(throws: KeychainError.self) {
        _ = try keychain.loadPublicKey()
    }
}

// MARK: - Session Lock Tests

@Test func testSessionLock() async throws {
    let lock = SessionLock()
    #expect(lock.isUnlocked == false)
    #expect(lock.remainingUnlockTime == nil)
    
    lock.unlockFor(seconds: 60)
    #expect(lock.isUnlocked == true)
    #expect(lock.remainingUnlockTime != nil)
    
    lock.lock()
    #expect(lock.isUnlocked == false)
    #expect(lock.remainingUnlockTime == nil)
}

@Test func testSessionLockRequireUnlock() async throws {
    let lock = SessionLock()
    
    #expect(throws: SessionLockError.self) {
        try lock.requireUnlock()
    }
    
    lock.unlockFor(seconds: 60)
    try lock.requireUnlock() // Should not throw
}

@Test func testSessionLockExpiration() async throws {
    let lock = SessionLock()
    lock.unlockFor(seconds: 0.1) // 100ms
    #expect(lock.isUnlocked == true)
    
    // Wait for expiration
    try await Task.sleep(nanoseconds: 150_000_000) // 150ms
    #expect(lock.isUnlocked == false)
}

// MARK: - Wallet Session Tests

@Test func testWalletSession() async throws {
    let session = WalletSession.shared
    session.disconnectAll() // Clean state
    
    let origin = "https://example.com"
    #expect(session.isConnected(origin: origin) == false)
    
    session.connect(origin: origin)
    #expect(session.isConnected(origin: origin) == true)
    #expect(session.allConnectedOrigins.contains(origin))
    
    session.disconnect(origin: origin)
    #expect(session.isConnected(origin: origin) == false)
}

// MARK: - JSON-RPC Tests

@Test func testJSONRPCRequestEncoding() async throws {
    let params = JSONRPCParams.connect(ConnectParams(origin: "https://test.com"))
    let request = JSONRPCRequest(id: 1, method: "connect", params: params)
    
    let data = try JSONRPC.encodeRequest(request)
    let decoded = try JSONRPC.parseRequest(data)
    
    #expect(decoded.id == request.id)
    #expect(decoded.method == request.method)
}

@Test func testJSONRPCResponseEncoding() async throws {
    let result = JSONRPCResult.connect(ConnectResult(publicKey: "test-key"))
    let response = JSONRPC.successResponse(id: 1, result: result)
    
    let data = try JSONRPC.encodeResponse(response)
    let decoded = try JSONDecoder().decode(JSONRPCResponse.self, from: data)
    
    #expect(decoded.id == response.id)
    #expect(decoded.result != nil)
    #expect(decoded.error == nil)
}

// MARK: - Base58 Tests

@Test func testBase58EncodeDecode() async throws {
    let original = Data([1, 2, 3, 4, 5])
    let encoded = Base58.encode(original)
    let decoded = try #require(Base58.decode(encoded))
    
    #expect(decoded == original)
}

@Test func testBase58PublicKeyEncoding() async throws {
    // Test that a 32-byte public key encodes/decodes correctly
    let keyData = Data((0..<32).map { UInt8($0 % 256) })
    let encoded = Base58.encode(keyData)
    #expect(encoded.count > 0)
    
    let decoded = try #require(Base58.decode(encoded))
    #expect(decoded == keyData)
}
