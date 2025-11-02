import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingDisconnectAlert = false
    @State private var originToDisconnect: String?
    
    var body: some View {
        NavigationView {
            Group {
                if appState.connectedOrigins.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "link")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Connections")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Connected dApps will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(appState.connectedOrigins, id: \.self) { origin in
                            ConnectionRow(origin: origin) {
                                originToDisconnect = origin
                                showingDisconnectAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Connections")
            .alert("Disconnect", isPresented: $showingDisconnectAlert) {
                Button("Cancel", role: .cancel) {
                    originToDisconnect = nil
                }
                Button("Disconnect", role: .destructive) {
                    if let origin = originToDisconnect {
                        appState.disconnect(origin: origin)
                    }
                    originToDisconnect = nil
                }
            } message: {
                if let origin = originToDisconnect {
                    Text("Disconnect from \(origin)?")
                }
            }
        }
    }
}

struct ConnectionRow: View {
    let origin: String
    let onDisconnect: () -> Void
    
    var body: some View {
        HStack {
            // Domain icon
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(origin.prefix(1)).uppercased()))
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(origin)
                    .font(.headline)
                
                Text("Connected")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Button(action: onDisconnect) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

