# MobileWalletAdapterSwift

A Swift Package that lets your iOS wallet connect to Solana dApps in Safari. Your users can sign transactions with optional passkey protection for extra security.

**Repository:** [https://github.com/NovaShieldWallet/mobile-wallet-adapter-swift](https://github.com/NovaShieldWallet/mobile-wallet-adapter-swift)

## Overview

Build a Solana wallet that works with dApps in Safari, just like Glow or Phantom. Key features:

- **Secure key storage** - Ed25519 keys safely stored in iOS Keychain
- **Safari integration** - dApps can connect through a Web Extension
- **Passkey unlock** - Optional biometric unlock using Face ID/Touch ID (passkeys)
- **Transaction signing** - Sign Solana transactions and messages
- **Easy to integrate** - Simple Swift API, works out of the box

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 14.0+

## Installation

### Swift Package Manager

**In Xcode:**
1. File → Add Packages...
2. Enter the repository URL: `https://github.com/NovaShieldWallet/mobile-wallet-adapter-swift.git`
3. Click Add Package
4. Select product: `MobileWalletAdapterSwift`
5. Click Add Package

**In Package.swift:**

```swift
dependencies: [
    .package(url: "https://github.com/NovaShieldWallet/mobile-wallet-adapter-swift.git", from: "0.1.0")
]
```

Then add to your target:
```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "MobileWalletAdapterSwift", package: "mobile-wallet-adapter-swift")
    ]
)
```

## Setup

### 1. Add Safari Extension Target

This is required for dApp connections (Jupiter, Raydium, etc.).

1. File → New → Target → **Safari Web Extension**
2. Name it (e.g., `WalletExtension`)
3. ✅ Check "Embed in Application"

### 2. Configure App Groups

**Main App:**
- Target → Signing & Capabilities → + App Groups
- Add: `group.com.novawallet.ios.wallet` (or your App Group ID)

**Extension Target:**
- Same steps, **same App Group ID** (must match exactly)

### 3. Configure Extension

Copy `WalletProviderExtension/Resources/WalletStandardProvider.js` to your extension's resources and inject it on `document_start` for all HTTPS pages.

### 4. Code Setup

```swift
import MobileWalletAdapterSwift

// AppGroupStore (use your App Group ID)
AppGroupStore.shared.appGroupID = "group.com.novawallet.ios.wallet"

// Initialize adapter
let adapter = MobileWalletAdapter.shared

// Create keypair
let keychain = Ed25519Keychain()
let publicKey = try keychain.createIfNeeded()

// Setup passkey
let passkeyManager = PasskeyManager(
    rpID: Bundle.main.bundleIdentifier ?? "com.novawallet.ios",
    rpName: "Nova Wallet"
)
try await passkeyManager.register(username: publicKey.base58)

// Setup approval handler (required)
ApprovalCoordinator.shared.setApprovalHandler { request in
    // Show approval UI, return .approved(result) or .rejected
    return try await handleApproval(request)
}

// Start listening for extension requests
ExtensionBridge.shared.startListening()
```

### 5. Connect from Safari Extension

When a dApp (like Jupiter) calls `connect()`, your extension relays the request to your app via App Groups. The approval handler you set up will receive the request.

```swift
func handleApproval(_ request: ApprovalRequest) async throws -> ApprovalResponse {
    // Unlock if needed
    if !SessionLock.shared.isUnlocked {
        try await passkeyManager.authenticate(sessionLock: SessionLock.shared)
    }
    
    // Process request based on method
    switch request.params {
    case .connect:
        WalletSession.shared.connect(origin: request.origin.absoluteString)
        let pubKey = adapter.publicKey
        return .approved(.connect(ConnectResult(publicKey: pubKey.base58)))
        
    case .signTransaction(let data):
        let sig = try adapter.signTransaction(data, origin: request.origin)
        return .approved(.sign(SignResult(signature: sig.base64EncodedString())))
        
    default:
        return .rejected
    }
}
```

### 6. Test Connection

```swift
let adapter = MobileWalletAdapter.shared

// Authenticate with passkey (if session locked)
let sessionLock = SessionLock.shared
if !sessionLock.isUnlocked {
    try await passkeyManager.authenticate(sessionLock: sessionLock)
}

// Sign transaction (returns signature)
let txData = Data(/* transaction bytes */)
let origin = URL(string: "https://jup.ag")!
let signature = try await adapter.signTransaction(txData, origin: origin)

// Sign and send (returns signed transaction bytes for dApp to broadcast)
// Note: The dApp is responsible for submitting to RPC endpoint
let signedTxBytes = try await adapter.sendTransaction(txData, origin: origin)
```

1. Build and run app on device
2. Settings → Safari → Extensions → Enable your extension
3. Open Safari → Go to `https://jup.ag`
4. Click "Connect Wallet"
5. Your wallet should appear; approval sheet shows in app

## Configuration Details

### App Groups

Both app and extension must use the same App Group ID:

```swift
AppGroupStore.shared.appGroupID = "group.com.novawallet.ios.wallet"
```

### Passkeys

Use bundle ID (no domain setup required):

```swift
PasskeyManager(
    rpID: Bundle.main.bundleIdentifier ?? "com.novawallet.ios",
    rpName: "Nova Wallet"
)
```

For domain-based passkeys, add Associated Domains capability and use your domain as `rpID`.

## Architecture

```
┌─────────────────┐
│  Safari dApp    │
└────────┬────────┘
         │ Wallet Standard API
         ▼
┌─────────────────┐
│ Safari Extension│  ← Injects provider, relays requests
└────────┬────────┘
         │ App Groups + CFNotificationCenter
         ▼
┌─────────────────┐
│  Native App     │  ← ApprovalCoordinator queues requests
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Passkey Auth    │  ← Unlocks session (120s TTL)
└────────┬─────────┘
         │
         ▼
┌─────────────────┐
│ Ed25519 Signing │  ← Keychain-stored keys
└─────────────────┘
```

## Technical Details

### Ed25519 Implementation

**Library**: `swift-sodium` (v0.9.1+) - libsodium wrapper providing production-ready Ed25519 cryptography.

- Uses **libsodium** under the hood (same library used by Signal, Tor, and many production crypto apps)
- Signatures are 64 bytes (RFC 8032 Ed25519 standard)
- Keys stored securely in iOS Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
- **Verified compatibility**: Signatures work with Solana's Ed25519 signature verification

**Test Vectors**: See `Tests/` for Ed25519 test vector verification using known-good test cases.

### Passkey Usage

**⚠️ Important: Passkeys are used ONLY for authentication/unlock, NOT for signing Solana transactions.**

- WebAuthn uses **P-256** (NIST curve)
- Solana uses **Ed25519** (Twisted Edwards curve)
- **These are incompatible** - passkeys cannot produce Ed25519 signatures
- Passkeys unlock access to locally stored Ed25519 keys
- All Solana signing is performed by Ed25519 keys stored in iOS Keychain

### Modules

### Core
- `WalletSession`: Manages connected origins
- `ApprovalCoordinator`: Queues and presents approval requests
- `RPCModels`: JSON-RPC 2.0 request/response types
- `JSONRPC`: Protocol handlers

### Crypto
- `Ed25519Keychain`: Key generation and Keychain storage
- `SolanaSigner`: Transaction/message signing
- `MessagePacking`: Solana message serialization

### Auth
- `PasskeyManager`: WebAuthn registration/authentication
- `SessionLock`: Time-based unlock state

### Bridge
- `ExtensionBridge`: Extension ↔ App communication
- `AppGroupStore`: Shared state via App Groups

## API Reference

### WalletService Protocol

```swift
public protocol WalletService {
    var publicKey: PublicKey { get }
    func connect(origin: URL) async throws -> WalletAccount
    func signMessage(_ msg: Data, origin: URL) async throws -> Data
    func signTransaction(_ tx: Data, origin: URL) async throws -> Data
    func sendTransaction(_ tx: Data, origin: URL) async throws -> String
}
```

### MobileWalletAdapter

```swift
let adapter = MobileWalletAdapter.shared

// Properties
adapter.requirePasskeyPerRequest = false  // Session-based (default)
adapter.sessionTTL = 120  // seconds

// Methods
let account = try await adapter.connect(origin: url)
let signature = try await adapter.signTransaction(txData, origin: url)
```

## Security Considerations

1. **Private Keys**: Never exported from Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
2. **Passkey Unlock**: Required before any signing operation (configurable per-request or session-based)
3. **Origin Validation**: All requests include origin for approval UI
4. **App Groups**: Secured by iOS entitlements; only app + extension can access
5. **No Auto-Approval**: Always present approval UI (implement custom `ApprovalCoordinator` handler)

## Testing

```bash
# Run unit tests
swift test

# Or in Xcode
xcodebuild test -scheme MobileWalletAdapterSwift -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Example App

See `WalletExampleApp/` for a complete implementation including:
- Onboarding flow (keypair generation + passkey registration)
- Connections management UI
- Approval sheets with transaction preview
- Settings (passkey per-request toggle, session TTL)

## Bridge Communication

Extension ↔ app communication uses **JSON-RPC 2.0** protocol:

- **Transport**: App Groups (UserDefaults) + Darwin notifications
- **Storage**: Requests stored as `pending_request_{id}`, responses as `response_{id}`
- **Notifications**: `com.wallet.request` and `com.wallet.response` (CFNotificationCenter)
- **Timeout**: 30 seconds per request
- **Protocol**: JSON-RPC 2.0 with method names: `connect`, `signTransaction`, `signMessage`, `sendTransaction`, `signAllTransactions`, `signAllMessages`

See the code in `Bridge/ExtensionBridge.swift` and `Bridge/AppGroupStore.swift` for implementation details.

## Troubleshooting

### App Groups Not Working
- **Check Xcode**: Target → Signing & Capabilities → App Groups must be enabled
- **Verify ID matches**: The ID in code must match exactly what's in Xcode (including `group.` prefix)
- **Extension setup**: If using Safari Extension, it must have the same App Group ID
- **Team signing**: Make sure both app and extension are signed with the same team

### Passkey Authentication Fails
- **Bundle ID method**: Use `Bundle.main.bundleIdentifier` - no additional setup needed
- **Domain method**: Ensure Associated Domains capability is added in Xcode
- **Check rpID**: The `rpID` must match exactly (bundle ID or domain as configured)
- **Verify registration**: Make sure `PasskeyManager.register()` was called successfully
- **Device required**: Passkeys need a real device with Face ID/Touch ID (simulator has limitations)

### Extension Not Receiving Requests
- **App Groups**: Must be configured in both app and extension targets
- **Same ID**: App Group ID must be identical in both targets
- **Safari settings**: Enable the extension in Settings → Safari → Extensions
- **Injection**: Ensure provider script is injected on `document_start` in extension manifest

### Keychain Access Errors
- **Capability**: Usually no extra capability needed (Keychain is automatic)
- **If sharing**: Only add Keychain Sharing capability if you need to share keys between apps
- **Permissions**: Keychain access is automatic for your app bundle

## License

See repository for license information.

## Contributing

Contributions welcome! Please open issues or pull requests on [GitHub](https://github.com/NovaShieldWallet/mobile-wallet-adapter-swift).

## References

- [Mobile Wallet Adapter 2.0 Spec](https://github.com/solana-mobile/mobile-wallet-adapter)
- [Wallet Standard](https://github.com/wallet-standard/wallet-standard)
- [WebAuthn / Passkeys](https://developer.apple.com/documentation/authenticationservices/publickeycredential)

