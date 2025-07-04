import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var selectedProvider: EmailProvider?
    
    private let emailAccountService: EmailAccountServiceProtocol
    private let backendAPIClient: BackendAPIClientProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        emailAccountService: EmailAccountServiceProtocol = EmailAccountService(),
        backendAPIClient: BackendAPIClientProtocol = BackendAPIClient()
    ) {
        self.emailAccountService = emailAccountService
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
            // Step 1: Initiate OAuth flow
            let oauthURL = try await backendAPIClient.initiateOAuthFlow(provider: provider)
            
            // Step 2: Present web view for OAuth (placeholder)
            // In a real implementation, this would open a web view or Safari
            // For now, we'll simulate the OAuth flow
            try await simulateOAuthFlow(provider: provider, oauthURL: oauthURL)
            
            // Step 3: Handle OAuth callback and exchange code for tokens
            // This would normally happen in a URL scheme handler
            let mockAuthCode = "mock_auth_code_\(provider.rawValue)"
            let tokenResponse = try await backendAPIClient.exchangeOAuthCode(
                provider: provider,
                authCode: mockAuthCode
            )
            
            // Step 4: Store tokens securely
            try await emailAccountService.storeOAuthTokens(
                provider: provider,
                tokens: tokenResponse
            )
            
            // Step 5: Register account with backend
            let accountInfo = try await backendAPIClient.registerEmailAccount(
                provider: provider,
                accessToken: tokenResponse.accessToken
            )
            
            // Step 6: Update app state
            await MainActor.run {
                // This would typically be handled by AppStateManager
                // For now, we'll just mark as successful
                isLoading = false
                selectedProvider = nil
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                selectedProvider = nil
                showError(error)
            }
        }
    }
    
    private func simulateOAuthFlow(provider: EmailProvider, oauthURL: URL) async throws {
        // Simulate OAuth flow delay
        try await Task.sleep(for: .seconds(2))
        
        // In a real implementation, this would:
        // 1. Open SFSafariViewController or ASWebAuthenticationSession
        // 2. Handle the OAuth callback URL
        // 3. Extract the authorization code
        
        print("OAuth flow initiated for \(provider.displayName)")
        print("OAuth URL: \(oauthURL)")
    }
    
    private func showError(_ error: Error) {
        if let apiError = error as? APIError {
            errorMessage = apiError.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        showError = true
    }
}

// MARK: - OAuth Token Response Model
struct OAuthTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(String)
    case authenticationFailed
    case serverError(Int)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .unknownError:
            return "An unknown error occurred"
        }
    }
} 