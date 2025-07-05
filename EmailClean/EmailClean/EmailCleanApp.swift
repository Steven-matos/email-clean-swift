import SwiftUI

@main
struct EmailCleanApp: App {
    @StateObject private var appStateManager = AppStateManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appStateManager)
                .preferredColorScheme(.light) // Ensure light mode for consistent color appearance
        }
    }
}

/// Manages the overall app state and navigation
class AppStateManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var emailAccounts: [EmailAccount] = []
    
    init() {
        // Check if user is already authenticated
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        // TODO: Check keychain for existing OAuth tokens
        // For now, assume user is not authenticated
        isAuthenticated = false
    }
    
    func signIn() {
        // TODO: Implement OAuth flow
        withAnimation(.easeInOut(duration: 0.5)) {
            isAuthenticated = true
        }
    }
    
    func signOut() {
        // TODO: Clear tokens from keychain
        withAnimation(.easeInOut(duration: 0.5)) {
            isAuthenticated = false
            currentUser = nil
            emailAccounts.removeAll()
        }
    }
} 