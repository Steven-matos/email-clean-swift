import SwiftUI

@main
struct EmailCleanApp: App {
    @StateObject private var appStateManager = AppStateManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appStateManager)
                .preferredColorScheme(.light) // Ensure light mode for consistent color appearance
                .onOpenURL { url in
                    // Handle OAuth callback URLs
                    handleOAuthCallback(url: url)
                }
        }
    }
    
    private func handleOAuthCallback(url: URL) {
        // This will be handled by ASWebAuthenticationSession automatically
        // But we can add additional logging here
        print("Received OAuth callback URL: \(url)")
    }
}

/// Manages the overall app state and navigation
class AppStateManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var emailAccounts: [EmailAccount] = []
    
    private let emailAccountService: EmailAccountServiceProtocol
    
    init(emailAccountService: EmailAccountServiceProtocol = EmailAccountService()) {
        self.emailAccountService = emailAccountService
        checkAuthenticationStatus()
        setupNotificationObservers()
    }
    
    private func checkAuthenticationStatus() {
        Task {
            let connectedAccounts = await emailAccountService.getConnectedAccounts()
            await MainActor.run {
                isAuthenticated = !connectedAccounts.isEmpty
            }
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .userAuthenticated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let account = notification.object as? EmailAccount {
                self?.handleUserAuthenticated(account: account)
            }
        }
    }
    
    private func handleUserAuthenticated(account: EmailAccount) {
        withAnimation(.easeInOut(duration: 0.5)) {
            isAuthenticated = true
            if !emailAccounts.contains(where: { $0.id == account.id }) {
                emailAccounts.append(account)
            }
        }
    }
    
    func signOut() {
        Task {
            // Clear all OAuth tokens
            for provider in EmailProvider.allCases {
                try? await emailAccountService.deleteOAuthTokens(provider: provider)
            }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isAuthenticated = false
                    currentUser = nil
                    emailAccounts.removeAll()
                }
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userAuthenticated = Notification.Name("userAuthenticated")
} 