# iOS Wallet Safari Extension - Complete Integration Checklist

Follow this checklist to integrate the wallet with Safari extensions for Jupiter/dApp connections.

## ✅ Prerequisites
- [ ] iOS 16.0+ project
- [ ] Swift 5.9+
- [ ] Xcode 14.0+
- [ ] Apple Developer account with Team ID

## 🔧 Setup Steps

### Step 1: Add Swift Package
- [ ] File → Add Packages → Add `MobileWalletAdapterSwift`
- [ ] Link to both Main App and Extension targets

### Step 2: Create Safari Extension Target
- [ ] File → New → Target → Safari Web Extension
- [ ] Name it (e.g., `WalletExtension`)
- [ ] ✅ Check "Embed in Application"

### Step 3: Copy Extension Files
- [ ] Copy `WalletProviderExtension/Resources/WalletStandardProvider.js` to extension Resources folder
- [ ] Copy `WalletProviderExtension/Scripts/content.js` to extension Scripts folder
- [ ] Copy `WalletProviderExtension/Scripts/background.js` to extension Scripts folder
- [ ] Reference these files in Xcode build (Target → Build Phases → Copy Files)

### Step 4: Configure Extension Manifest
- [ ] Open extension's `Info.plist`
- [ ] Add SFSafariContentScript entry:
```xml
<key>SFSafariContentScript</key>
<array>
    <dict>
        <key>Matches</key>
        <array>
            <string>https://*/*</string>
        </array>
        <key>Scripts</key>
        <array>
            <string>content.js</string>
        </array>
        <key>RunAt</key>
        <string>document_start</string>
    </dict>
</array>
```

### Step 5: Configure App Groups
- [ ] **Main App**: Signing & Capabilities → + App Groups
  - [ ] Add: `group.com.novawallet.ios.wallet`
- [ ] **Extension Target**: Same steps
  - [ ] Add: `group.com.novawallet.ios.wallet` (MUST MATCH)

### Step 6: Configure Keychain Sharing ⚠️ CRITICAL
- [ ] **Main App**: Signing & Capabilities → + Keychain Sharing
  - [ ] Add Keychain Access Group: `com.novawallet.ios`
  - [ ] Or add one of: `com.novawallet.ios.multisig`, `com.nova.device.wallet.encrypted`
- [ ] **Extension Target**: Same steps
  - [ ] Add: **SAME Keychain Access Group ID** as Main App
- [ ] Verify Team ID matches in both targets

### Step 7: Initialize Wallet in Code
```swift
import MobileWalletAdapterSwift

// In your app's startup code:
let keychain = Ed25519Keychain()  // Uses com.novawallet.ios by default
let publicKey = try keychain.createIfNeeded()

let passkeyManager = PasskeyManager(
    rpID: Bundle.main.bundleIdentifier ?? "com.novawallet.ios",
    rpName: "Nova Wallet"
)
try await passkeyManager.register(username: publicKey.base58)

// Setup approval handler
ApprovalCoordinator.shared.setApprovalHandler { request in
    // Show approval UI, return .approved(result) or .rejected
    return try await handleApproval(request)
}

// Start listening for extension requests
ExtensionBridge.shared.startListening()
```

### Step 8: Create Extension Handler (See INTEGRATION_GUIDE.md)
- [ ] Create `ExtensionHandler.swift` in extension target
- [ ] Implement `NSExtensionRequestHandling`
- [ ] Bridge between JavaScript and App Groups
- [ ] See `WalletProviderExtension/INTEGRATION_GUIDE.md` for implementation

### Step 9: Enable Extension on Device
- [ ] Build and run on physical iOS device (extensions don't work in simulator)
- [ ] Open Settings → Safari → Extensions
- [ ] Find your extension and enable it
- [ ] Set permission to "Allow on Every Website"

## 🧪 Testing

### Test Extension Injection
- [ ] Open Safari on device
- [ ] Go to `https://jup.ag`
- [ ] Open browser console (Settings → Safari → Advanced → Web Inspector)
- [ ] Type: `window.solana`
- [ ] Should see wallet provider object

### Test Connection
- [ ] On Jupiter, click "Connect Wallet"
- [ ] Your wallet should appear in the list
- [ ] Click to connect
- [ ] Approval should appear in your native app
- [ ] Approve and verify connection works

### Test Transaction Signing
- [ ] Try to swap on Jupiter
- [ ] Approval request should appear in app
- [ ] Verify transaction details
- [ ] Approve and confirm transaction completes

## 🐛 Troubleshooting

### Wallet Not Showing
- [ ] Check browser console for `window.solana`
- [ ] Verify extension is enabled in Safari settings
- [ ] Check `document_start` injection in manifest
- [ ] Verify `WalletStandardProvider.js` is in Resources

### Connection Fails
- [ ] Check App Groups match exactly
- [ ] Verify `ExtensionBridge.shared.startListening()` is called
- [ ] Check AppGroupStore uses correct Group ID
- [ ] Look for errors in Xcode console

### Keychain Access Errors
- [ ] Verify Keychain Sharing capability added to both targets
- [ ] Check Keychain Access Group IDs match exactly
- [ ] Ensure Team ID is identical in both targets
- [ ] Verify `Ed25519Keychain()` initialized with correct accessGroup
- [ ] Error `-25243`: Access group mismatch
- [ ] Error `-34018`: Team ID incorrect

### Messages Not Reaching App
- [ ] Check message flow: page → content → background → handler → app
- [ ] Verify CFNotificationCenter notifications posted
- [ ] Check AppGroupStore UserDefaults accessibility
- [ ] Review extension handler implementation

## 📚 Reference

- Full integration guide: `WalletProviderExtension/INTEGRATION_GUIDE.md`
- Solana example: https://github.com/solana-mobile/SolanaSafariWalletExtension
- Main README: `README.md`

## ✅ Final Checklist Before Release

- [ ] All tests pass on device
- [ ] Extension works in production build
- [ ] Keys are securely stored in Keychain
- [ ] Approval UI works correctly
- [ ] Extension properly handles all JSON-RPC methods
- [ ] Error handling implemented
- [ ] User can enable/disable extension
- [ ] Documentation complete

