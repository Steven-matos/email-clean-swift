import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var selectedProvider: EmailProvider?
    
    private let emailAccountService: EmailAccountServiceProtocol
    private let oauthService: OAuthServiceProtocol
    private let backendAPIClient: BackendAPIClientProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        emailAccountService: EmailAccountServiceProtocol = EmailAccountService(),
        oauthService: OAuthServiceProtocol = OAuthService(),
        backendAPIClient: BackendAPIClientProtocol = BackendAPIClient()
    ) {
        self.emailAccountService = emailAccountService
        self.oauthService = oauthService
        self.backendAPIClient = backendAPIClient
    }
    
    func connectEmailAccount(provider: EmailProvider) {
        Task {
            await performOAuthFlow(provider: provider)
        }
    }
    
    private func performOAuthFlow(provider: EmailProvider) async {
        isLoading = true
        selectedProvider = provider
        
        do {
            // Step 1: Perform OAuth authentication
            let tokenResponse = try await oauthService.authenticate(provider: provider)
            
            // Step 2: Store tokens securely
            try await emailAccountService.storeOAuthTokens(
                provider: provider,
                tokens: tokenResponse
            )
            
            // Step 3: Register account with backend
            let accountInfo = try await backendAPIClient.registerEmailAccount(
                provider: provider,
                accessToken: tokenResponse.accessToken
            )
            
            // Step 4: Update app state
            await MainActor.run {
                isLoading = false
                selectedProvider = nil
                // Notify AppStateManager to update authentication state
                NotificationCenter.default.post(
                    name: .userAuthenticated,
                    object: accountInfo
                )
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                selectedProvider = nil
                showError(error)
            }
        }
    }
    
    private func showError(_ error: Error) {
        if let oauthError = error as? OAuthError {
            errorMessage = oauthError.localizedDescription
        } else if let apiError = error as? APIError {
            errorMessage = apiError.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        showError = true
    }
    

}

// Note: OAuthTokenResponse and APIError are now defined in BackendAPIClient.swift 