import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Protocol Definition
protocol OAuthServiceProtocol {
    func authenticate(provider: EmailProvider) async throws -> OAuthTokenResponse
    func refreshTokens(provider: EmailProvider, refreshToken: String) async throws -> OAuthTokenResponse
}

// MARK: - Implementation
class OAuthService: NSObject, OAuthServiceProtocol {
    private let backendAPIClient: BackendAPIClientProtocol
    private var currentCodeVerifier: String?
    private var currentCodeChallenge: String?
    private var currentCodeChallengeMethod: String?
    
    init(backendAPIClient: BackendAPIClientProtocol = BackendAPIClient()) {
        self.backendAPIClient = backendAPIClient
        super.init()
    }
    
    func authenticate(provider: EmailProvider) async throws -> OAuthTokenResponse {
        print("🚀 OAuthService.authenticate called for provider: \(provider)")
        print("📦 OAuthService backend useMockMode: \(backendAPIClient.isMockModeEnabled)")

        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        currentCodeVerifier = codeVerifier
        currentCodeChallenge = codeChallenge
        currentCodeChallengeMethod = "S256"
        print("🛠️ OAuthService generated code verifier: \(codeVerifier)")
        print("🛠️ OAuthService generated code challenge: \(codeChallenge)")
        
        // Step 1: Get OAuth URL from backend
        let oauthURL = try await backendAPIClient.initiateOAuthFlow(
            provider: provider,
            codeChallenge: codeChallenge,
            codeChallengeMethod: "S256"
        )
        print("🔗 OAuthService got auth URL from backend: \(oauthURL)")
        
        // Step 2: Present web authentication session
        let authCode = try await presentWebAuthenticationSession(
            url: oauthURL,
            provider: provider
        )
        print("✅ OAuthService received auth code: \(authCode)")
        
        // Step 3: Exchange auth code for tokens
        let tokens = try await backendAPIClient.exchangeOAuthCode(
            provider: provider,
            authCode: authCode,
            codeVerifier: codeVerifier
        )
        currentCodeVerifier = nil
        currentCodeChallenge = nil
        currentCodeChallengeMethod = nil
        return tokens
    }
    
    func refreshTokens(provider: EmailProvider, refreshToken: String) async throws -> OAuthTokenResponse {
        // This would make the actual refresh token API call
        // For now, we'll use the backend client's mock implementation
        let tokens = try await backendAPIClient.exchangeOAuthCode(
            provider: provider,
            authCode: "refresh_\(refreshToken)",
            codeVerifier: currentCodeVerifier
        )
        return tokens
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

// MARK: - PKCE Helpers
private extension OAuthService {
    func generateCodeVerifier() -> String {
        let length = 64
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes.baseAddress!)
        }
        if result != errSecSuccess {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        return base64URLEncode(data)
    }

    func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return base64URLEncode(Data(hash))
    }

    func base64URLEncode(_ data: Data) -> String {
        let encoded = data.base64EncodedString()
        return encoded
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension OAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Ensure UI access happens on main thread
        return DispatchQueue.main.sync {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("No window available for OAuth presentation")
            }
            return window
        }
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