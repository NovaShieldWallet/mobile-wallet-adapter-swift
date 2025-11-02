import SwiftUI
import MobileWalletAdapterSwift

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "wallet.pass.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text("Welcome to Wallet Example")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Create your wallet to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: createWallet) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isCreating ? "Creating..." : "Create Wallet")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isCreating)
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func createWallet() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                try await appState.completeOnboarding()
            } catch {
                errorMessage = "Failed to create wallet: \(error.localizedDescription)"
                isCreating = false
            }
        }
    }
}

