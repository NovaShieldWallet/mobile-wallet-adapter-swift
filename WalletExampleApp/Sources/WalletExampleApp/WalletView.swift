import SwiftUI
import MobileWalletAdapterSwift

struct WalletView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingCopyAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Public Key Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Wallet Address")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let pubKey = appState.publicKey {
                            HStack {
                                Text(pubKey.base58)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                
                                Spacer()
                                
                                Button(action: {
                                    UIPasteboard.general.string = pubKey.base58
                                    showingCopyAlert = true
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                            }
                        } else {
                            Text("Loading...")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Session Status
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Session Status")
                                .font(.headline)
                            
                            Spacer()
                            
                            Circle()
                                .fill(appState.isUnlocked ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            
                            Text(appState.isUnlocked ? "Unlocked" : "Locked")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let remaining = appState.unlockTimeRemaining {
                            Text("Unlocked for \(Int(remaining)) more seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                        
                        Button(action: unlockWallet) {
                            HStack {
                                Image(systemName: "faceid")
                                Text("Unlock Wallet")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Wallet")
            .alert("Copied!", isPresented: $showingCopyAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private func unlockWallet() {
        Task {
            do {
                let passkeyManager = PasskeyManager(
                    rpID: Bundle.main.bundleIdentifier ?? "com.example.wallet",
                    rpName: "Wallet Example"
                )
                let sessionLock = SessionLock()
                try await passkeyManager.authenticate(sessionLock: sessionLock)
            } catch {
                print("Failed to unlock: \(error)")
            }
        }
    }
}

extension AppState {
    var isUnlocked: Bool {
        let lock = SessionLock()
        return lock.isUnlocked
    }
    
    var unlockTimeRemaining: TimeInterval? {
        let lock = SessionLock()
        return lock.remainingUnlockTime
    }
}

