# Troubleshooting Xcode Build Errors

## Error: "Multiple commands produce..."

This error occurs when Xcode tries to copy the same file multiple times into the extension bundle.

### Root Cause:

The extension is copying **entire `node_modules` folder** instead of just the bundled output files.

### Solution:

1. Open your Xcode project
2. Select the **Nova for Safari** extension target
3. Go to **Build Phases** tab
4. Look for **Copy Bundle Resources**
5. Click to expand it
6. **Find and REMOVE these entries:**
   - Any folder references to `js-extension/node_modules`
   - Any folder references to `js-extension/dist`
   - Any files from `node_modules` directory
7. **ONLY keep these files:**
   - `WalletStandardProvider.js` (from Resources)
   - `content.js` (from Scripts)
   - `background.js` (from Scripts)
8. Also check **Compile Sources** phase - remove any `.js` files from there
9. Clean build folder: Product → Clean Build Folder (Shift+Cmd+K)
10. Build again

### What files SHOULD be in your extension:

**For Safari Web Extension, you ONLY need:**
- `WalletStandardProvider.js` (in Resources folder)
- `content.js` (in Scripts folder)
- `background.js` (in Scripts folder)
- Your extension's `Info.plist`

**DO NOT include:**
- `node_modules` folder
- Multiple copies of the same JS files
- Documentation files (README, CHANGELOG, etc.)
- NPM config files
- Package.json or lock files

### Prevent the issue:

1. Make sure your `npm build` script outputs only to ONE location
2. Don't run `npm install` in the extension folder - run it elsewhere
3. Copy ONLY the three required JS files manually to the extension target
4. Check Build Phases → Copy Bundle Resources for duplicates

## Alternative: Use Build Script

If you have a build script that bundles JS, make sure it:
1. Builds to a SINGLE output directory
2. Doesn't include `node_modules`
3. References files correctly in Xcode

### Example Build Script (in Build Phases):

```bash
# Build JS bundle
cd path/to/js-extension
npm run build:publish

# Copy ONLY the output files
cp -f dist/WalletStandardProvider.js "${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}/Resources/"
cp -f dist/content.js "${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}/Scripts/"
cp -f dist/background.js "${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}/Scripts/"
```

### For Solana Example Structure:

The Solana example uses this structure:
```
js-extension/
  src/
    approval/
    content.ts
    background.ts
    injected.ts
    ...
  dist/  ← Build output goes here
  package.json
```

Then copies from `dist/` into the extension. You should do the same.

## Quick Fix Commands:

```bash
# Find and clean up duplicates in your project
cd path/to/your/xcode/project
find . -name "*.js" -type f | grep -v node_modules | sort | uniq -d

# Remove duplicate files from Xcode
# (Do this manually in Xcode, not via command line)
```

### In Xcode UI:
1. Select your project (blue icon)
2. Select extension target
3. Build Phases → Copy Bundle Resources
4. Remove duplicates by clicking the `-` button
5. Keep only unique files

## Critical: How to Fix Your Current Setup

Your error shows files from `/Users/ceo/Desktop/gem-ios/Nova for Safari/js-extension/node_modules/` being copied.

### Step-by-Step Fix:

1. **Remove node_modules from Build Phases:**
   - Open Xcode project
   - Select "Nova for Safari" extension target
   - Build Phases → Copy Bundle Resources
   - Find ANY entry containing `js-extension/node_modules`
   - Click the `-` button to remove it
   - Do this for EVERY node_modules reference

2. **Add ONLY the 3 required files:**
   - Click `+` button in Copy Bundle Resources
   - Navigate to `js-extension/dist/` (or wherever your built files are)
   - Select: `WalletStandardProvider.js`, `content.js`, `background.js`
   - Make sure each is ONLY added ONCE

3. **Alternative: Use a Build Script Instead:**
   Add a new "Run Script" build phase BEFORE "Copy Bundle Resources":
   
   ```bash
   cd "${SRCROOT}/Nova for Safari/js-extension"
   npm run build
   
   # Copy ONLY built files
   cp -v dist/WalletStandardProvider.js "${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}/Resources/"
   cp -v dist/content.js "${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}/Scripts/"
   cp -v dist/background.js "${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}/Scripts/"
   ```

4. **Clean and rebuild:**
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Product → Build (Cmd+B)

## Error: Unable to find module dependency: 'ed25519swift'

If your existing code uses `ed25519swift`, you need to replace it with `Sodium`.

### Solution: Replace ed25519swift with Sodium

**Option 1: Use MobileWalletAdapterSwift Package (Recommended)**

Add the package to your Xcode project:
1. File → Add Packages
2. URL: `https://github.com/NovaShieldWallet/mobile-wallet-adapter-swift.git`
3. Add to your app and extension targets
4. Use `Ed25519Keychain` from the package:

```swift
import MobileWalletAdapterSwift

let keychain = Ed25519Keychain()
let publicKey = try keychain.createIfNeeded()
```

**Option 2: Add swift-sodium Package Directly**

1. File → Add Packages
2. URL: `https://github.com/jedisct1/swift-sodium.git`
3. Version: 0.9.1 or later
4. Add to both app and extension targets

**Option 3: Rewrite KeypairStorage.swift to use Sodium**

Replace your `KeypairStorage.swift`:

```swift
import Foundation
import os.log
import Sodium  // Replace ed25519swift with Sodium

private let APP_GROUP_ID = "group.com.novawallet.ios.Nova-for-Safari"
private let KEYPAIR_KEY = "com.nova.safari.wallet.keypair"

struct StoredKeypair: Codable {
    let publicKey: String // Base64 encoded
    let privateKey: String // Base64 encoded
}

/// Generate or retrieve wallet keypair from App Group storage
func getOrCreateKeypair() -> (publicKey: Data, privateKey: Data)? {
    let logger = OSLog(subsystem: "com.novawallet.ios", category: "KeypairStorage")
    
    guard let defaults = UserDefaults(suiteName: APP_GROUP_ID) else {
        os_log("Failed to access App Group defaults", log: logger, type: .error)
        return nil
    }
    
    // Try to load existing keypair
    if let jsonString = defaults.string(forKey: KEYPAIR_KEY),
       let jsonData = jsonString.data(using: .utf8),
       let stored = try? JSONDecoder().decode(StoredKeypair.self, from: jsonData),
       let publicKey = Data(base64Encoded: stored.publicKey),
       let privateKey = Data(base64Encoded: stored.privateKey) {
        os_log("Loaded existing keypair", log: logger, type: .info)
        return (publicKey, privateKey)
    }
    
    // Generate new keypair using Sodium
    os_log("Generating new keypair...", log: logger, type: .info)
    
    let sodium = Sodium()
    guard let keyPair = sodium.sign.keyPair() else {
        os_log("Failed to generate keypair", log: logger, type: .error)
        return nil
    }
    
    let publicKey = Data(keyPair.publicKey)
    let privateKey = Data(keyPair.secretKey)  // Sodium's secretKey is 64 bytes
    
    // Store in App Group UserDefaults
    let stored = StoredKeypair(
        publicKey: publicKey.base64EncodedString(),
        privateKey: privateKey.base64EncodedString()
    )
    
    do {
        let jsonData = try JSONEncoder().encode(stored)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            defaults.set(jsonString, forKey: KEYPAIR_KEY)
            os_log("Keypair generated and stored", log: logger, type: .info)
            return (publicKey, privateKey)
        }
    } catch {
        os_log("Failed to store keypair: %{public}@", log: logger, type: .error, error.localizedDescription)
    }
    
    return nil
}

/// Sign a payload with the stored private key
func signPayload(_ payload: Data, privateKey: Data) -> Data? {
    let sodium = Sodium()
    guard let signature = sodium.sign.signature(message: Array(payload), secretKey: Array(privateKey)) else {
        print("Failed to sign: signature generation failed")
        return nil
    }
    return Data(signature)
}
```

**Important Notes:**
- Sodium's `secretKey` is 64 bytes (seed + public key concatenated)
- Sodium's `publicKey` is 32 bytes
- `sign.signature()` returns 64-byte Ed25519 signature
- Fully compatible with Solana's Ed25519 signatures

