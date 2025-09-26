import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var serviceManager = ServiceManager.shared
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
                            .environmentObject(serviceManager)
                            .tabItem {
                                Image(systemName: "envelope")
                                Text("Mail")
                            }
                            .tag(0)
                        
                        YahooAccountManagerView()
                            .environmentObject(serviceManager)
                            .tabItem {
                                Image(systemName: "person.2")
                                Text("Accounts")
                            }
                            .tag(1)
                        
                        AccountSettingsView()
                            .environmentObject(serviceManager)
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
        .onAppear {
            Task {
                await serviceManager.initialize()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager())
} 