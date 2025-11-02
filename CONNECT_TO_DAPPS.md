# Connecting Your Wallet to dApps (Jupiter, Raydium, etc.)

## ✅ What You Already Have

1. **Core Package** (`MobileWalletAdapterSwift`) - Handles wallet logic, signing, passkeys
2. **Wallet Standard Provider** (`WalletStandardProvider.js`) - JavaScript that dApps detect
3. **Extension Bridge** - Communication between Safari extension and your app
4. **Approval System** - Request handling and user approval UI

## 📋 What You Need to Set Up

### Step 1: Create Safari Extension Target

1. In Xcode: **File → New → Target**
2. Choose **Safari Web Extension**
3. Name it (e.g., `NovaWalletExtension`)
4. ✅ Check "Embed in Application"

### Step 2: Copy Extension Files

Copy these files into your extension target:

**From:** `WalletProviderExtension/Resources/WalletStandardProvider.js`  
**To:** Your extension's Resources folder

**From:** `WalletProviderExtension/Scripts/content.js` (if needed)  
**To:** Your extension's Scripts/content folder

### Step 3: Configure Extension Manifest

Your extension needs a `manifest.json` that:

```json
{
  "manifest_version": 2,
  "name": "Nova Wallet",
  "version": "1.0",
  "description": "Solana wallet for Safari",
  "content_scripts": [
    {
      "matches": ["https://*/*"],
      "js": ["Resources/WalletStandardProvider.js"],
      "run_at": "document_start",
      "all_frames": false
    }
  ],
  "permissions": ["storage", "nativeMessaging"],
  "background": {
    "scripts": ["Resources/background.js"],
    "persistent": false
  }
}
```

### Step 4: Set Up App Groups

**In both your app AND extension targets:**

1. Target → Signing & Capabilities
2. Add **App Groups** capability
3. Add: `group.com.novawallet.ios.wallet` (same ID in both!)

### Step 5: Wire Up in Your App

```swift
import MobileWalletAdapterSwift

func setupWalletForDApps() {
    // 1. Configure App Group Store
    let store = AppGroupStore(appGroupID: "group.com.novawallet.ios.wallet")
    
    // 2. Initialize bridge (listens for extension requests)
    ExtensionBridge.shared.startListening()
    
    // 3. Set approval handler (shows UI when dApp requests connection/signing)
    ApprovalCoordinator.shared.setApprovalHandler { request in
        // Present your approval UI
        return try await self.showApprovalSheet(for: request)
    }
    
    // 4. Generate keypair if needed
    let keychain = Ed25519Keychain()
    _ = try? keychain.createIfNeeded()
    
    // 5. Register passkey for unlock
    let passkeyManager = PasskeyManager(
        rpID: Bundle.main.bundleIdentifier ?? "com.novawallet.ios",
        rpName: "Nova Wallet"
    )
    Task {
        try? await passkeyManager.register(username: "user")
    }
}
```

### Step 6: Enable Extension in Safari

1. Build and run your app on device
2. Settings → Safari → Extensions
3. Find your extension and **enable it** ✅

### Step 7: Test with Jupiter

1. Open Safari on your device
2. Go to `https://jup.ag`
3. Click "Connect Wallet"
4. Your wallet should appear in the list!
5. Approve the connection in your app

## 🎯 How It Works

```
dApp (Jupiter)           Safari Extension           Your App
     │                          │                       │
     ├─ connect() ────────────►│                       │
     │                          ├─ App Group ────────►│
     │                          │                       │
     │                          │                       ├─ Approval UI
     │                          │                       │
     │                          │◄── approved() ───────┤
     │◄── { publicKey } ────────┤                       │
     │                          │                       │
     ├─ signTransaction() ─────►│                       │
     │                          ├─ App Group ────────►│
     │                          │                       │
     │                          │                       ├─ Sign & Return
     │◄── { signature } ────────┤                       │
```

## ✅ Supported dApps

Any dApp that uses **Wallet Standard** or **Solana Wallet Adapter**:

- ✅ Jupiter (`jup.ag`)
- ✅ Raydium
- ✅ Magic Eden
- ✅ Phantom-compatible dApps
- ✅ Any Wallet Standard dApp

## 🔧 Troubleshooting

**"Wallet not found"**
- Make sure extension is enabled in Settings → Safari → Extensions
- Check extension manifest includes `WalletStandardProvider.js`

**"Connection failed"**
- Verify App Groups match in both app and extension
- Check `ExtensionBridge.shared.startListening()` is called
- Verify approval handler is set

**"No approval UI shown"**
- Make sure `ApprovalCoordinator.shared.setApprovalHandler` is called
- Check App Groups communication is working

## 📚 Next Steps

See `README.md` for full setup instructions and API reference.

