import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        ZStack {
            // Global background
            Color.primaryBackground
                .ignoresSafeArea()
            
            Group {
                if appStateManager.isAuthenticated {
                    MainMailboxView()
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