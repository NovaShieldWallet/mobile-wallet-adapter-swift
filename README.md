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

## Quick Start

> **For Nova Wallet developers**: See [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) for specific setup instructions with your App Groups.

### Step 0: Configure Xcode Project (Required First!)

**Before writing any code, you must configure your Xcode project:**

#### 1. Enable App Groups Capability

**Why**: Required for Safari Extension ↔ App communication

1. Open your Xcode project
2. Select your **app target** in the Project Navigator
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Select **App Groups**
6. Click **+** next to App Groups
7. Enter: `group.com.yourcompany.wallet` (replace with your domain/company)
8. ✅ Check the box to enable it

**Important**: If you're using a Safari Extension, add the **same App Group** to your extension target too!

#### 2. Configure Passkey Support (Optional but Recommended)

**Option A: Bundle ID (Simplest - Recommended)**
- ✅ **No additional setup needed!** Just use your bundle ID in code
- Works immediately, no domain required

**Option B: Custom Domain (Advanced)**
1. In **Signing & Capabilities**, click **+ Capability**
2. Select **Associated Domains**
3. Click **+** and add: `webcredentials:your-domain.com`
4. You'll need to own the domain and configure it (see Apple docs)

#### 3. Set Minimum iOS Version

1. Select your app target
2. Go to **General** tab
3. Set **Minimum Deployments** to **iOS 16.0** (required for passkeys)

#### 4. Configure App Group in Code

Once App Groups are enabled, configure it in your code:

```swift
// Set your App Group ID (must match what you entered in Xcode)
let store = AppGroupStore(appGroupID: "group.com.yourcompany.wallet")
```

### 1. Basic Setup

```swift
import MobileWalletAdapterSwift

// Initialize wallet adapter
let adapter = MobileWalletAdapter.shared

// Create keypair (if needed)
let keychain = Ed25519Keychain()
let publicKey = try keychain.createIfNeeded()
print("Public key: \(publicKey.base58)")

// Set up passkey authentication
// Simplest approach: use your app's bundle identifier
let passkeyManager = PasskeyManager(
    rpID: Bundle.main.bundleIdentifier ?? "com.yourcompany.wallet",
    rpName: "My Wallet"  // This appears in system passkey dialogs
)
try await passkeyManager.register(username: publicKey.base58)
```

**What are `rpID` and `rpName`?**
- **`rpID`**: A unique string that identifies your wallet app to the passkey system
  - **Easy option**: Just use `Bundle.main.bundleIdentifier` (your app's bundle ID)
  - **Advanced option**: Use a domain like `"wallet.example.com"` only if you need web integration
- **`rpName`**: The friendly name users see in iOS passkey prompts (like "My Wallet" or "Nova Wallet")

### 2. Connect from Safari Extension

The extension injects a Wallet Standard provider. When a dApp calls `connect()`, the native app receives the request via App Groups.

```swift
// In your app delegate or main coordinator
let bridge = ExtensionBridge.shared

// Handle incoming requests
bridge.startListening()
```

### 3. Signing Transactions

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

**About `sendTransaction`:**
- Returns **signed transaction bytes** (full transaction with signature appended)
- The **dApp is responsible** for submitting to a Solana RPC endpoint
- This follows Wallet Standard best practices - allows dApp to choose RPC endpoint/commitment level
- If your wallet app wants to submit directly, use an RPC client like `Solana.swift` or `web3.swift`

## Configuration

### App Groups Setup Checklist

**✅ Already done in "Step 0" above?** Great! If not, follow these steps:

**For Main App:**
1. Target → Signing & Capabilities
2. Click **+ Capability** → **App Groups**
3. Add: `group.com.yourdomain.wallet` (replace with your domain)
4. ✅ Enable the checkbox

**For Safari Extension (if you have one):**
1. Select your **extension target**
2. Same steps as above
3. **IMPORTANT**: Use the **exact same App Group ID** as the main app

**In Code:**
```swift
// Use the same ID you configured in Xcode
let store = AppGroupStore(appGroupID: "group.com.yourdomain.wallet")
```

### Associated Domains (for Passkeys)

**Option 1: Use App Bundle Identifier (Simplest)**
- No additional setup needed
- Use your app's bundle ID as `rpID`:
  ```swift
  let passkeyManager = PasskeyManager(
      rpID: Bundle.main.bundleIdentifier ?? "com.yourcompany.wallet",
      rpName: "My Wallet"
  )
  ```

**Option 2: Use Custom Domain (For Web Integration)**
1. Enable Associated Domains capability in Xcode
2. Add domain: `applinks:your-domain.com` or `webcredentials:your-domain.com`
3. Configure `PasskeyManager` with your domain:
   ```swift
   let passkeyManager = PasskeyManager(
       rpID: "your-domain.com",        // Must match associated domain
       rpName: "Your Wallet Name"       // User-visible name
   )
   ```
   
**Which to choose?**
- **Bundle ID**: Simpler, no server setup needed, passkeys are app-scoped
- **Domain**: More flexible, allows passkey sharing between web and app, requires domain ownership

### Safari Web Extension

1. Create Safari Web Extension target in Xcode
2. Configure extension entitlements:
   - Same App Group as main app
   - Associated Domains (if using web-based passkeys)

3. Inject Wallet Standard provider (see `Providers/WalletStandardProvider.js`)

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

