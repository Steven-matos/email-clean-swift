import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        Group {
            if appStateManager.isAuthenticated {
                MainMailboxView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appStateManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager())
} 