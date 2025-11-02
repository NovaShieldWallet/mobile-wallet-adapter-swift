import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass")
                }
            
            ConnectionsView()
                .tabItem {
                    Label("Connections", systemImage: "link")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .sheet(item: Binding(
            get: { appState.pendingApprovals.first },
            set: { _ in }
        )) { request in
            ApprovalSheet(request: request)
        }
    }
}

