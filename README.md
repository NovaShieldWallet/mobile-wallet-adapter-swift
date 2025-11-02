# SolanaSwiftKit

Complete Solana wallet integration for iOS Safari Extensions.

## Installation

```swift
// In Xcode: File → Add Packages
// URL: https://github.com/solana-mobile/mobile-wallet-adapter-swift.git

dependencies: [
    .package(url: "https://github.com/solana-mobile/mobile-wallet-adapter-swift.git", branch: "main")
]
```

## Frameworks

**SolanaSwift** - Core Solana crypto (Ed25519, Base58, KeyPair)  
**SolanaSafariKit** - Safari Extension RPC bridge (GetAccounts, SignPayloads)

## Quick Start

```swift
import SolanaSwift
import SolanaSafariKit

// Generate keypair
let keypair = KeyPair.generate()!

// Safari Extension Handler
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        guard let method = context.requestMethod() else {
            context.completeRpcRequestWith(error: WalletlibRpcErrors.methodNotFound)
            return
        }
        
        switch method {
        case GET_ACCOUNTS_REQUEST_METHOD:
            let storage = KeypairStorage(suiteName: "group.your.app")
            let keypair = storage.getOrCreate()
            let pubkey = keypair.publicKey.data.base64EncodedString()
            context.completeRpcRequestWith(result: GetAccountsResult(addresses: [pubkey]))
            
        case SIGN_PAYLOADS_REQUEST_METHOD:
            guard let params: SignPayloadsParams = context.decodeRpcRequestParameter() else {
                context.completeRpcRequestWith(error: WalletlibRpcErrors.invalidParams)
                return
            }
            let storage = KeypairStorage(suiteName: "group.your.app")
            let keypair = storage.getOrCreate()
            guard let payloadData = Data(base64Encoded: params.payloads[0]) else {
                context.completeRpcRequestWith(error: WalletlibRpcErrors.invalidParams)
                return
            }
            let signature = keypair.sign(payloadData)
            context.completeRpcRequestWith(
                result: SignPayloadsResult(signed_payloads: [signature.data.base64EncodedString()])
            )
            
        default:
            context.completeRpcRequestWith(error: WalletlibRpcErrors.methodNotFound)
        }
    }
}
```

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 14.0+

## License

MIT
