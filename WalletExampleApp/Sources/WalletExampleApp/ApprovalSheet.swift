import SwiftUI
import MobileWalletAdapterSwift

struct ApprovalSheet: View {
    @EnvironmentObject var appState: AppState
    let request: ApprovalRequest
    @Environment(\.dismiss) var dismiss
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Origin header
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(request.origin.host?.prefix(1).uppercased() ?? "?"))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(request.origin.host ?? request.origin.absoluteString)
                                .font(.headline)
                            Text("wants to:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    // Request details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Request Details")
                            .font(.headline)
                        
                        requestDetailView
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: approve) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(isProcessing ? "Processing..." : "Approve")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isProcessing)
                        
                        Button(action: reject) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Reject")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Approve Request")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private var requestDetailView: some View {
        switch request.params {
        case .connect:
            Text("Connect to your wallet")
                .font(.body)
            
        case .signTransaction(let data):
            VStack(alignment: .leading, spacing: 8) {
                Text("Sign Transaction")
                    .font(.body)
                    .fontWeight(.semibold)
                Text("Transaction size: \(data.count) bytes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(data.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " "))
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(3)
                    .foregroundColor(.secondary)
            }
            
        case .signMessage(let data):
            VStack(alignment: .leading, spacing: 8) {
                Text("Sign Message")
                    .font(.body)
                    .fontWeight(.semibold)
                if let message = String(data: data, encoding: .utf8) {
                    Text(message)
                        .font(.body)
                        .lineLimit(5)
                } else {
                    Text("\(data.count) bytes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
        case .sendTransaction(let txHash):
            VStack(alignment: .leading, spacing: 8) {
                Text("Send Transaction")
                    .font(.body)
                    .fontWeight(.semibold)
                Text("Signature: \(txHash.prefix(16))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
        case .signTransactions(let datas), .signAllTransactions(let datas):
            VStack(alignment: .leading, spacing: 8) {
                Text("Sign \(datas.count) Transactions")
                    .font(.body)
                    .fontWeight(.semibold)
                Text("Batch signing request")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
        case .signMessages(let datas), .signAllMessages(let datas):
            VStack(alignment: .leading, spacing: 8) {
                Text("Sign \(datas.count) Messages")
                    .font(.body)
                    .fontWeight(.semibold)
                Text("Batch signing request")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func approve() {
        isProcessing = true
        
        Task {
            do {
                _ = try await appState.approveRequest(request)
                dismiss()
            } catch {
                print("Approval failed: \(error)")
                isProcessing = false
            }
        }
    }
    
    private func reject() {
        appState.rejectRequest(request)
        dismiss()
    }
}

