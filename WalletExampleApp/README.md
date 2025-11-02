# Wallet Example App - How to Run

A complete SwiftUI example app demonstrating MobileWalletAdapterSwift.

## Quick Start (3 Steps)

### Step 1: Open in Xcode

```bash
cd /Users/ceo/mwa/mobile-wallet-adapter-swift
open Package.swift
```

### Step 2: Create iOS App Target

1. In Xcode: **File → New → Target**
2. Choose **iOS → App**
3. Configure:
   - **Product Name**: `WalletExampleApp`
   - **Team**: Your development team
   - **Interface**: SwiftUI
   - **Language**: Swift
4. Click **Finish**

### Step 3: Add Source Files

**Option A: Copy files**
1. Select your new `WalletExampleApp` target in Navigator
2. Right-click → **Add Files to "WalletExampleApp"...**
3. Navigate to: `mobile-wallet-adapter-swift/WalletExampleApp/Sources/WalletExampleApp/`
4. Select all `.swift` files (7 files)
5. Make sure **"Copy items if needed"** is checked
6. Click **Add**

**Option B: Drag & drop**
1. Drag all 7 Swift files from Finder into your Xcode project
2. Make sure they're added to the `WalletExampleApp` target

### Step 4: Add Package Dependency

1. Select your project (blue icon) in Navigator
2. Select the `WalletExampleApp` target
3. Go to **"Package Dependencies"** tab
4. Click **+** button
5. Click **"Add Local..."**
6. Navigate to: `/Users/ceo/mwa/mobile-wallet-adapter-swift`
7. Click **Add Package**
8. Select product: `MobileWalletAdapterSwift`
9. Click **Add Package**

### Step 5: Delete Default Files

Delete or replace:
- Default `ContentView.swift` (we have our own)
- Default `WalletExampleAppApp.swift` (we have `WalletExampleApp.swift`)

### Step 6: Run!

1. Select iOS Simulator (iPhone 16) or your device
2. Press **⌘R** (or click Play button)
3. App will launch with onboarding screen

## What You'll See

1. **First Launch**: Onboarding screen - tap "Create Wallet"
2. **Main Screen**: Three tabs - Wallet, Connections, Settings
3. **Wallet Tab**: Shows your public key, session status
4. **Connections**: Empty initially (will populate when dApps connect)
5. **Settings**: Configure passkey behavior

## Testing Passkeys

**Important**: Passkeys require a real device with Face ID/Touch ID.

1. Run on a physical iPhone/iPad
2. Tap "Unlock Wallet" button
3. Use Face ID/Touch ID to authenticate
4. Session unlocks for 120 seconds (configurable)

## Testing with Safari Extension

To test full dApp connection flow:

1. Add Safari Web Extension target (see main README)
2. Configure App Groups
3. Enable extension in Safari settings
4. Visit a Solana dApp in Safari
5. Extension will inject provider and send requests to this app
6. Approval sheets will appear automatically

## Troubleshooting

**"No such module MobileWalletAdapterSwift"**
- Make sure package dependency is added
- Try: Product → Clean Build Folder (⇧⌘K)

**Passkey doesn't work**
- Use a real device (simulator has limited support)
- Check that Face ID/Touch ID is enabled

**Build errors**
- Ensure iOS deployment target is 16.0+
- Project → Target → General → Minimum Deployment: iOS 16.0

## Files Included

All files are in `Sources/WalletExampleApp/`:
- `WalletExampleApp.swift` - App entry, approval handler setup
- `ContentView.swift` - Main navigation
- `OnboardingView.swift` - First-time setup
- `WalletView.swift` - Wallet info display
- `ConnectionsView.swift` - Connected dApps list
- `ApprovalSheet.swift` - Request approval modal
- `SettingsView.swift` - Configuration
