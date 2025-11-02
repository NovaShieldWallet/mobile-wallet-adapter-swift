import XCTest
@testable import SolanaSwift

final class SolanaSwiftTests: XCTestCase {
    func testKeypairGeneration() throws {
        let keypair = KeyPair.generate()
        XCTAssertNotNil(keypair)
        XCTAssertEqual(keypair?.publicKey.bytes.count, 32)
        XCTAssertEqual(keypair?.privateKey.bytes.count, 64)
    }
    
    func testBase58Encoding() throws {
        let testBytes: [UInt8] = [1, 2, 3, 4, 5]
        let encoded = Base58.fromBytes(testBytes)
        XCTAssertFalse(encoded.isEmpty)
    }
}

