import Foundation
import AuthenticationServices
import UIKit

// MARK: - Protocol Definition
protocol OAuthServiceProtocol {
    func authenticate(provider: EmailProvider) async throws -> OAuthTokenResponse
    func refreshTokens(provider: EmailProvider, refreshToken: String) async throws -> OAuthTokenResponse
}

// MARK: - Implementation
class OAuthService: NSObject, OAuthServiceProtocol {
    private let backendAPIClient: BackendAPIClientProtocol
    
    init(backendAPIClient: BackendAPIClientProtocol = BackendAPIClient()) {
        self.backendAPIClient = backendAPIClient
        super.init()
    }
    
    func authenticate(provider: EmailProvider) async throws -> OAuthTokenResponse {
        // Step 1: Get OAuth URL from backend
        let oauthURL = try await backendAPIClient.initiateOAuthFlow(provider: provider)
        
        // Step 2: Present web authentication session
        let authCode = try await presentWebAuthenticationSession(
            url: oauthURL,
            provider: provider
        )
        
        // Step 3: Exchange auth code for tokens
        return try await backendAPIClient.exchangeOAuthCode(
            provider: provider,
            authCode: authCode
        )
    }
    
    func refreshTokens(provider: EmailProvider, refreshToken: String) async throws -> OAuthTokenResponse {
        // This would make the actual refresh token API call
        // For now, we'll use the backend client's mock implementation
        return try await backendAPIClient.exchangeOAuthCode(
            provider: provider,
            authCode: "refresh_\(refreshToken)"
        )
    }
    
    private func presentWebAuthenticationSession(url: URL, provider: EmailProvider) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "emailclean"
            ) { callbackURL, error in
                if let error = error {
                    // Handle cancellation gracefully
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: OAuthError.userCancelled)
                    } else {
                        continuation.resume(throwing: OAuthError.authenticationFailed(error))
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: OAuthError.noCallbackURL)
                    return
                }
                
                // Extract authorization code from callback URL
                guard let authCode = self.extractAuthCode(from: callbackURL) else {
                    continuation.resume(throwing: OAuthError.invalidCallbackURL)
                    return
                }
                
                continuation.resume(returning: authCode)
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            
            if !session.start() {
                continuation.resume(throwing: OAuthError.sessionStartFailed)
            }
        }
    }
    
    private func extractAuthCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return nil
        }
        return code
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension OAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for OAuth presentation")
        }
        return window
    }
}

// MARK: - OAuth Errors
enum OAuthError: LocalizedError {
    case authenticationFailed(Error)
    case noCallbackURL
    case invalidCallbackURL
    case sessionStartFailed
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .noCallbackURL:
            return "No callback URL received from OAuth provider"
        case .invalidCallbackURL:
            return "Invalid callback URL format"
        case .sessionStartFailed:
            return "Failed to start OAuth session"
        case .userCancelled:
            return "Authentication was cancelled"
        }
    }
} 