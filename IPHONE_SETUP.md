# iPhone Setup - Connect Wallet to dApps in Safari

## Quick Overview

To connect your wallet to Jupiter, Raydium, etc. on iPhone Safari, you need:
1. Your iOS app with the wallet
2. A Safari Web Extension
3. App Groups for communication
4. Extension enabled in iPhone Settings

## Step-by-Step: iPhone Setup

### 1. Add Safari Extension to Your Xcode Project

1. Open your wallet app project in Xcode
2. **File → New → Target**
3. Select **Safari Web Extension** (under iOS)
4. Name it: `NovaWalletExtension` (or your name)
5. ✅ Check **"Embed in Application"**
6. Click **Finish**

### 2. Configure Extension Files

**Copy the provider script:**

1. In Xcode, select your extension target
2. Right-click extension folder → **Add Files to "NovaWalletExtension"...**
3. Navigate to: `WalletProviderExtension/Resources/WalletStandardProvider.js`
4. ✅ Check "Copy items if needed"
5. ✅ Make sure it's added to the extension target (not the app target)

**Create extension manifest:**

Create `Info.plist` or `manifest.json` for your extension with:

```json
{
  "NSExtension": {
    "NSExtensionPointIdentifier": "com.apple.Safari.web-extension",
    "NSExtensionPrincipalClass": "SafariWebExtensionHandler"
  },
  "SFSafariContentScript": [
    {
      "Matches": ["https://*/*", "http://*/*"],
      "Scripts": ["WalletStandardProvider.js"],
      "RunAt": "document_start"
    }
  ]
}
```

### 3. Set Up App Groups (iPhone Requirement)

**In your Main App target:**
1. Select your app target in Xcode
2. **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** and add: `group.com.novawallet.ios.wallet`
6. ✅ Enable it

**In your Extension target:**
1. Select extension target
2. Same steps as above
3. **Use the exact same App Group ID**: `group.com.novawallet.ios.wallet`
4. ✅ Enable it

**This is how iPhone app ↔ extension communicate!**

### 4. Code Setup in Your App

In your app's `App.swift` or `SceneDelegate`:

```swift
import MobileWalletAdapterSwift

func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
    // Configure App Group Store
    let store = AppGroupStore(appGroupID: "group.com.novawallet.ios.wallet")
    
    // Start listening for requests from Safari extension
    ExtensionBridge.shared.startListening()
    
    // Set up approval handler (shows UI when dApp requests connection)
    ApprovalCoordinator.shared.setApprovalHandler { [weak self] request in
        // Present approval UI on main thread
        await MainActor.run {
            return try await self?.showApprovalUI(for: request) ?? .rejected
        }
    }
    
    // Initialize wallet if needed
    let keychain = Ed25519Keychain()
    _ = try? keychain.createIfNeeded()
    
    // Register passkey (for unlock)
    Task {
        let passkeyManager = PasskeyManager(
            rpID: Bundle.main.bundleIdentifier ?? "com.novawallet.ios",
            rpName: "Nova Wallet"
        )
        try? await passkeyManager.register(username: "wallet")
    }
}

@MainActor
func showApprovalUI(for request: ApprovalRequest) async throws -> ApprovalResponse {
    // Show your approval sheet/modal
    // Return .approved(result) or .rejected
    return .approved(.connect(ConnectResult(publicKey: "...")))
}
```

### 5. Build and Install on iPhone

1. Connect your iPhone via USB
2. In Xcode, select your iPhone as the device
3. Select your **app target** (not extension)
4. Build and run (⌘R)
5. Both app and extension will install

### 6. Enable Extension in iPhone Settings

**This is critical - users must enable it:**

1. On iPhone: **Settings → Safari → Extensions**
2. Find your extension (e.g., "Nova Wallet Extension")
3. Tap it
4. Toggle **"Nova Wallet Extension"** ON ✅
5. Tap **"All Websites"** → Select **"Allow"**

### 7. Test with Jupiter on iPhone

1. Open **Safari** on iPhone
2. Go to: `https://jup.ag`
3. Tap **"Connect Wallet"**
4. Your wallet should appear in the list! 🎉
5. Tap it
6. Your app opens with approval prompt
7. Approve → Returns to Safari → Connected!

## How It Works on iPhone

```
iPhone Safari              Extension              Your App
     │                         │                      │
     │─ Load jup.ag            │                      │
     │                          │                      │
     │─ Inject provider         │                      │
     │                          │                      │
     │─ User taps              │                      │
     │  "Connect Wallet"        │                      │
     │                          │                      │
     │─ connect() request ─────►│                      │
     │                          ├─ App Group ────────►│
     │                          │                      │
     │                          │                      ├─ Show approval UI
     │                          │                      │
     │                          │◄─ approved() ────────┤
     │◄─ { publicKey } ─────────┤                      │
     │                          │                      │
     │                          │                      │
     │─ signTransaction() ─────►│                      │
     │                          ├─ App Group ────────►│
     │                          │                      │
     │                          │                      ├─ Sign transaction
     │◄─ { signature } ──────────┤                      │
```

## Requirements Checklist

- [ ] Safari Extension target created in Xcode
- [ ] `WalletStandardProvider.js` copied to extension
- [ ] Extension manifest/Info.plist configured
- [ ] App Groups capability added to **both** app and extension
- [ ] Same App Group ID in both: `group.com.novawallet.ios.wallet`
- [ ] `ExtensionBridge.shared.startListening()` called in app
- [ ] Approval handler set up
- [ ] App built and installed on iPhone
- [ ] Extension enabled in Settings → Safari → Extensions
- [ ] Tested with Jupiter or another dApp

## iPhone-Specific Notes

1. **App Groups are mandatory** - This is how iOS allows app ↔ extension communication
2. **Extension must be enabled manually** - Users need to go to Settings → Safari → Extensions
3. **Requires iOS 16+** - For passkey support (can work without passkeys on iOS 15+)
4. **Both app and extension install together** - When you build the app, extension installs automatically
5. **Extension runs in Safari context** - It can inject scripts into web pages

## Troubleshooting on iPhone

**"Extension not found in Settings"**
- Make sure extension target is embedded in app
- Rebuild and reinstall app on iPhone
- Check extension is listed in Xcode project

**"Wallet doesn't appear in dApp"**
- Verify extension is enabled in Settings → Safari → Extensions
- Check `WalletStandardProvider.js` is in extension bundle
- Verify manifest includes HTTPS matches

**"Approval UI doesn't show"**
- Check App Groups match exactly
- Verify `ExtensionBridge.shared.startListening()` is called
- Check approval handler is set before app finishes launching

**"Connection fails"**
- Verify App Group ID matches in both targets
- Check both app and extension are signed with same team
- Verify `AppGroupStore` uses correct group ID

## Next Steps

Once set up, your wallet works with:
- ✅ Jupiter (`jup.ag`)
- ✅ Raydium
- ✅ Magic Eden  
- ✅ Any Wallet Standard dApp

Users just need to:
1. Enable extension in Settings
2. Visit dApp in Safari
3. Tap "Connect Wallet"
4. Your wallet appears!

