# Safari Extension Integration Guide

This guide explains how to integrate the WalletStandardProvider.js into your iOS app's Safari Web Extension.

## Architecture Overview

```
Web Page (Jupiter/dApp)
    ↓ window.solana
Injected Script (WalletStandardProvider.js)
    ↓ window.postMessage
Content Script (content.js)
    ↓ safari.application messages
Background Script (background.js)
    ↓ App Groups
Extension Handler (Swift) ← YOU IMPLEMENT THIS
    ↓ App Groups
Native iOS App (ExtensionBridge)
```

## Step 1: Create Safari Extension Target

1. In Xcode: File → New → Target → **Safari Web Extension**
2. Name it (e.g., `WalletExtension`)
3. ✅ Check "Embed in Application"
4. Copy all files from `WalletProviderExtension/` to your extension target:
   - `Resources/WalletStandardProvider.js`
   - `Scripts/content.js`
   - `Scripts/background.js`

## Step 2: Configure Extension Manifest

In your extension's `Info.plist`, add content script configuration:

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

## Step 3: Create Extension Handler

Create a new Swift file in your extension target:

**`ExtensionHandler.swift`**

```swift
import SafariServices
import Foundation

@main
class ExtensionHandler: NSObject, NSExtensionRequestHandling {
    
    private let appGroupID = "group.your.app.here" // YOUR APP GROUP ID
    
    func beginRequest(with context: NSExtensionContext) {
        // This is called by Safari when the extension loads
        // You can set up initial state here
    }
    
    // Handle messages from background.js
    // This would need to be implemented via a messaging mechanism
    // Refer to Solana's Safari extension example for the full implementation
}
```

## Step 4: Configure App Groups

1. **In Xcode:** Target → Signing & Capabilities → + App Groups
2. Add: `group.your.app.here` (use the same ID for both app and extension)
3. In your native app code, configure AppGroupStore:

```swift
let store = AppGroupStore(appGroupID: "group.your.app.here")
```

## Step 5: Configure Keychain Sharing (REQUIRED)

**⚠️ Critical:** Without Keychain Sharing, your Safari extension cannot access wallet keys.

1. **In Xcode:** Target → Signing & Capabilities → + Keychain Sharing
2. Add Keychain Access Group: `TEAM_ID.com.yourapp.shared`
   - Replace `TEAM_ID` with your Apple Developer Team ID
   - Find Team ID: Xcode → Signing & Capabilities → Team
3. **Repeat for Extension Target:** Same Keychain Access Group ID
4. **In your code:**

```swift
// Default: Uses com.novawallet.ios access group (already configured)
let keychain = Ed25519Keychain()

// OR specify a different access group:
let keychain = Ed25519Keychain(
    accessGroup: "com.novawallet.ios"  // Default Nova Wallet group
)
```

**Ensure one of these Keychain Groups is in your Keychain Sharing capability:**
- `com.novawallet.ios` ✅ (default)
- `com.novawallet.ios.multisig`
- `com.nova.device.wallet.encrypted`

## Step 6: Message Flow Implementation

The background script needs to communicate with your native app. You have two options:

### Option A: Direct App Groups (Recommended)

Update `background.js` to read/write directly from App Groups using a Safari extension API if available, or:

### Option B: Extension Handler Bridge

Create a custom message bridge in your Extension Handler that:
1. Receives messages from background.js
2. Writes requests to App Groups UserDefaults
3. Posts CFNotificationCenter notifications
4. Polls for responses
5. Sends responses back to background.js

## Step 7: Bridge Implementation

Your extension handler needs to bridge between JavaScript and Swift:

```swift
class ExtensionHandler: NSObject, NSExtensionRequestHandling {
    private func handleWalletRequest(_ request: [String: Any]) {
        // 1. Store in App Groups
        let store = AppGroupStore(appGroupID: appGroupID)
        let jsonRPCRequest = try? parseJSONRPCRequest(request)
        
        // 2. Post notification to wake native app
        try? store.storeRequest(jsonRPCRequest)
        
        // 3. Listen for response (simplified - actual implementation needs async handling)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let response = try? store.retrieveResponse(id: request.id) {
                // Send response back to JavaScript
                self.sendResponseToBackground(response)
            }
        }
    }
    
    private func sendResponseToBackground(_ response: JSONRPCResponse) {
        // Use Safari messaging to send response back to background.js
    }
}
```

## Reference Implementation

For a complete working example, see:
- [Solana Safari Wallet Extension](https://github.com/solana-mobile/SolanaSafariWalletExtension)

This shows the full JavaScript → Swift → App Groups → Native App flow.

## Testing

1. Build and run your app on device (extensions don't work in simulator)
2. Settings → Safari → Extensions → Enable your extension
3. Open Safari → `https://jup.ag`
4. Click "Connect Wallet"
5. Your wallet should appear in the list

## Common Issues

**Wallet not showing:**
- Check that provider script is injected at `document_start`
- Verify `window.solana` exists in browser console
- Ensure extension is enabled in Safari settings

**Connection failures:**
- Verify App Groups are configured and match
- Check that `ExtensionBridge.shared.startListening()` is called in app
- Ensure UserDefaults with App Group suite name is accessible

**Keychain access errors:**
- Verify Keychain Sharing capability is added to both app and extension
- Check Keychain Access Group ID matches in both targets (format: `TEAM_ID.com.yourapp.shared`)
- Ensure `Ed25519Keychain` is initialized with `accessGroup` parameter
- Error `-25243`: Access group mismatch - verify IDs match exactly
- Error `-34018`: Team ID incorrect - check Signing & Capabilities

**Messages not reaching app:**
- Verify message flow: injected → content → background → handler
- Check CFNotificationCenter notifications are being posted
- Ensure AppGroupStore is initialized with correct Group ID

