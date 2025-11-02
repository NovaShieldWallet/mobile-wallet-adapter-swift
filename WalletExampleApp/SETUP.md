# Quick Setup Guide

## Create Xcode Project

1. Open Xcode
2. File → New → Project
3. iOS → App
4. Configure:
   - Product Name: `WalletExampleApp`
   - Team: Your team
   - Organization: `com.example`
   - Language: Swift
   - Interface: SwiftUI
5. Save to: This directory (`WalletExampleApp/`)

## Add Package Dependency

1. Select project in Navigator
2. Select your app target
3. Go to "Package Dependencies" tab
4. Click "+"
5. Add Local Package:
   ```
   /Users/ceo/mwa/mobile-wallet-adapter-swift
   ```
6. Select product: `MobileWalletAdapterSwift`

## Copy Source Files

Copy these files from `Sources/WalletExampleApp/` into your Xcode app target:
- All `.swift` files (7 files total)

Or delete the default ContentView/App files and drag all Swift files into the project.

## Configure Capabilities

1. Target → Signing & Capabilities
2. Add:
   - **App Groups**: `group.com.example.wallet`
   - **Associated Domains**: (optional, for passkeys)

## Run

⌘R to run on simulator or device!

