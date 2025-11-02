# Developer Setup Guide

**Package already added?** Great! Follow these steps to connect your wallet to Jupiter and other Solana dApps.

## ✅ Step 1: Verify App Groups Setup

You mentioned you added these App Groups in Xcode. Let's make sure they're configured correctly:

### In Xcode:
1. Select your **app target**
2. Go to **Signing & Capabilities**
3. Verify these App Groups are enabled (both checkboxes checked):
   - ✅ `group.com.novawallet.ios.wallet`
   - ✅ `group.com.novawallet.ios`

### In Your Code:
Use the wallet App Group:

```swift
import MobileWalletAdapterSwift

// Configure App Group Store (add this in your app startup)
let store = AppGroupStore(appGroupID: "group.com.novawallet.ios.wallet")
```

## ✅ Step 2: Set Up Passkey Authentication

**Simplest approach** - use your bundle ID (no domain setup needed):

```swift
// In your app initialization (AppDelegate or App file)
let passkeyManager = PasskeyManager(
    rpID: Bundle.main.bundleIdentifier ?? "com.novawallet.ios",
    rpName: "Nova Wallet"
)
```

## ✅ Step 3: Initialize Wallet Adapter

Add this to your app startup:

```swift
import MobileWalletAdapterSwift

// In AppDelegate.didFinishLaunching or App.onAppear
func setupWallet() {
    // 1. Create keypair if needed
    let keychain = Ed25519Keychain()
    do {
        let publicKey = try keychain.createIfNeeded()
        print("Wallet public key: \(publicKey.base58)")
    } catch {
        print("Error creating wallet: \(error)")
    }
    
    // 2. Set up approval handler (required for dApp connections)
    ApprovalCoordinator.shared.setApprovalHandler { request in
        // Show approval UI - approve or reject the request
        return try await self.handleApprovalRequest(request)
    }
    
    // 3. Start listening for requests from Safari Extension
    ExtensionBridge.shared.startListening()
}

// Handle approval requests (you'll implement this)
func handleApprovalRequest(_ request: ApprovalRequest) async throws -> ApprovalResponse {
    // Show UI to user (origin, transaction details, etc.)
    // Return .approved(result) or .rejected
}
```

## ✅ Step 4: Set Up Safari Extension

To connect to Jupiter and other websites, you need a Safari Web Extension:

### 4a. Add Extension Target
1. File → New → Target
2. Select **Safari Web Extension**
3. Name it: `NovaWalletExtension`
4. ✅ Check "Embed in Application"

### 4b. Configure Extension
1. Select your **extension target**
2. **Signing & Capabilities** tab
3. Add **App Groups** capability
4. Add the **same App Group**: `group.com.novawallet.ios.wallet` ✅
5. Copy `WalletProviderExtension/Resources/WalletStandardProvider.js` to your extension

### 4c. Enable in Safari
1. Build and run your app
2. On device: Settings → Safari → Extensions
3. Enable your extension ✅

## ✅ Step 5: Test with Jupiter

1. Open Safari on your device
2. Go to: `https://jup.ag`
3. Click "Connect Wallet"
4. Your wallet extension should appear
5. Approval sheet will show in your app
6. Approve to connect!

## Quick Checklist

- [ ] App Groups added in Xcode (both app and extension targets)
- [ ] App Group ID matches in code: `group.com.novawallet.ios.wallet`
- [ ] PasskeyManager initialized with bundle ID
- [ ] ApprovalCoordinator handler set up
- [ ] ExtensionBridge.startListening() called
- [ ] Safari Extension created and configured
- [ ] Extension enabled in Safari settings

## Common Issues

**"No wallet found"**
- Make sure Safari Extension is enabled in Settings → Safari → Extensions

**"App Group not working"**
- Verify App Group ID matches exactly (including `group.` prefix)
- Check both app and extension targets have the same ID

**"Passkey doesn't work"**
- Use a real device (simulator has limited passkey support)
- Make sure Face ID/Touch ID is enabled

## Full Documentation

For complete details, see the main [README.md](README.md).

