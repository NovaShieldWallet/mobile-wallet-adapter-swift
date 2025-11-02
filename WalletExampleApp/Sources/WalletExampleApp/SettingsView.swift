import SwiftUI
import MobileWalletAdapterSwift

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var settings: WalletSettings
    
    init() {
        _settings = State(initialValue: WalletSettings())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Passkey Settings")) {
                    Toggle("Require Passkey Per Request", isOn: $settings.requirePasskeyPerRequest)
                        .onChange(of: settings.requirePasskeyPerRequest) { newValue in
                            settings.requirePasskeyPerRequest = newValue
                            appState.updateSettings(settings)
                        }
                    
                    if !settings.requirePasskeyPerRequest {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session Duration")
                                .font(.subheadline)
                            
                            HStack {
                                Slider(
                                    value: Binding(
                                        get: { settings.sessionTTL },
                                        set: { newValue in
                                            settings.sessionTTL = newValue
                                            appState.updateSettings(settings)
                                        }
                                    ),
                                    in: 30...300,
                                    step: 30
                                )
                                
                                Text("\(Int(settings.sessionTTL))s")
                                    .frame(width: 50)
                                    .font(.system(.body, design: .monospaced))
                            }
                            
                            Text("Wallet stays unlocked for this duration after passkey authentication")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Wallet will require passkey authentication before each signing request")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Package")
                        Spacer()
                        Text("MobileWalletAdapterSwift")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Danger Zone")) {
                    Button(role: .destructive, action: {
                        // In production, implement proper wallet reset
                        print("Reset wallet - not implemented in example")
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Reset Wallet")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            settings = appState.settings
        }
    }
}

