import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Global background
            Color.primaryBackground
                .ignoresSafeArea()
            
            Group {
                if appStateManager.isAuthenticated {
                    TabView(selection: $selectedTab) {
                        MainMailboxView()
                            .tabItem {
                                Image(systemName: "envelope")
                                Text("Mail")
                            }
                            .tag(0)
                        
                        YahooAccountManagerView()
                            .tabItem {
                                Image(systemName: "person.2")
                                Text("Accounts")
                            }
                            .tag(1)
                        
                        AccountSettingsView()
                            .tabItem {
                                Image(systemName: "gearshape")
                                Text("Settings")
                            }
                            .tag(2)
                    }
                    .accentColor(.blue)
                } else {
                    LoginView()
                }
            }
            .animation(.easeInOut(duration: 0.5), value: appStateManager.isAuthenticated)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager())
} 