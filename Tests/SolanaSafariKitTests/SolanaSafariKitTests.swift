import XCTest
@testable import SolanaSafariKit

final class SolanaSafariKitTests: XCTestCase {
    func testGetAccountsModel() throws {
        let addresses = ["test_address_1", "test_address_2"]
        let result = GetAccountsResult(addresses: addresses)
        XCTAssertEqual(result.addresses.count, 2)
        XCTAssertEqual(result.addresses[0], "test_address_1")
    }
    
    func testSignPayloadsModel() throws {
        let result = SignPayloadsResult(signed_payloads: ["signature1"])
        XCTAssertEqual(result.signed_payloads.count, 1)
    }
}

