import Foundation
import CryptoKit
@preconcurrency import AuthenticationServices
import Security

/**
 * YahooOAuthService handles OAuth 2.0 authentication flow for Yahoo Mail API
 * Supports multiple Yahoo accounts per user with secure token storage
 */
class YahooOAuthService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthenticating = false
    @Published var authenticationError: String?
    @Published var connectedAccounts: [YahooAccount] = []
    
    // MARK: - Private Properties
    private var currentAuthSession: ASWebAuthenticationSession?
    private let keychain = KeychainManager()
    private var currentCodeVerifier: String?
    
    // MARK: - OAuth Configuration
    private struct YahooConfig {
        static let clientID = "dj0yJmk9dGhNU1NJTzJIbE01JmQ9WVdrOU1rVXpSVVpEVTNRbWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PWMx"
        static let authURL = "https://api.login.yahoo.com/oauth2/request_auth"
        static let tokenURL = "https://api.login.yahoo.com/oauth2/get_token"
        static let redirectURI = "emailclean://oauth/yahoo"
        static let scopes = ["openid", "email", "profile"]
        static let userInfoURL = "https://api.login.yahoo.com/openid/v1/userinfo"
    }
    
    // MARK: - Public Methods
    
    /**
     * Initiates Yahoo OAuth authentication flow
     * Allows users to add multiple Yahoo accounts
     */
    func authenticateWithYahoo() async {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("🚀 [YahooOAuth] Starting OAuth authentication at: \(timestamp)")
        print("🌐 [YahooOAuth] Using Client ID prefix: \(YahooConfig.clientID.prefix(12))…")
        print("🌐 [YahooOAuth] Configured redirect URI: \(YahooConfig.redirectURI)")
        print("🌐 [YahooOAuth] Configured scopes: \(YahooConfig.scopes.joined(separator: ", "))")
        
        // Test URL scheme registration on the main actor
        await MainActor.run {
            if let testURL = URL(string: "emailclean://oauth/test") {
                let canOpen = UIApplication.shared.canOpenURL(testURL)
                print("🔍 [YahooOAuth] canOpenURL('emailclean://oauth/test'): \(canOpen)")
            }
        }
        
        await MainActor.run {
            isAuthenticating = true
            authenticationError = nil
        }
        
        do {
            print("🔧 [YahooOAuth] Step 1: Building Yahoo OAuth URL…")
            let authURL = try buildAuthURL()
            print("🔗 [YahooOAuth] Built OAuth URL: \(authURL.absoluteString)")
            if let components = URLComponents(url: authURL, resolvingAgainstBaseURL: false) {
                let formattedParams = components
                    .queryItems?
                    .sorted { $0.name < $1.name }
                    .map { "\($0.name)=\($0.value ?? "nil")" }
                    .joined(separator: " | ") ?? "<none>"
                print("🧩 [YahooOAuth] Query parameters (sorted): \(formattedParams)")
            }
            
            print("🔧 [YahooOAuth] Step 2: Starting ASWebAuthenticationSession…")
            let result = try await performAuthentication(with: authURL)
            print("✅ [YahooOAuth] ASWebAuthenticationSession returned: \(result ?? "nil")")
            
            guard let authCode = result else {
                print("❌ [YahooOAuth] No authorization code returned.")
                await MainActor.run {
                    authenticationError = "No authorization code returned."
                    isAuthenticating = false
                }
                return
            }
            
            print("🔧 [YahooOAuth] Step 3: Exchanging authorization code for tokens…")
            let tokens = try await exchangeCodeForTokens(code: authCode)
            print("✅ [YahooOAuth] Token exchange succeeded. Access token length: \(tokens.accessToken.count)")
            
            print("🔧 [YahooOAuth] Step 4: Fetching user info…")
            let userInfo = try await fetchUserInfo(accessToken: tokens.accessToken)
            print("✅ [YahooOAuth] Retrieved user info: email=\(userInfo.email), name=\(userInfo.name)")
            
            let account = YahooAccount(
                id: UUID().uuidString,
                email: userInfo.email,
                name: userInfo.name,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                expiresAt: Date().addingTimeInterval(TimeInterval(tokens.expiresIn))
            )
            
            print("💾 [YahooOAuth] Saving account to keychain for email: \(account.email)")
            try await storeAccount(account)
            
            await MainActor.run {
                // Check if account already exists (prevent duplicates)
                if !connectedAccounts.contains(where: { $0.email == account.email }) {
                    connectedAccounts.append(account)
                    print("🎉 [YahooOAuth] New account added: \(account.email)")
                } else {
                    print("ℹ️ [YahooOAuth] Account already exists, updating: \(account.email)")
                    // Update existing account
                    if let index = connectedAccounts.firstIndex(where: { $0.email == account.email }) {
                        connectedAccounts[index] = account
                    }
                }
                isAuthenticating = false
            }
            print("🎉 [YahooOAuth] Account successfully saved and UI updated.")
        } catch {
            print("❌ [YahooOAuth] Error during authentication: \(error)")
            print("❌ [YahooOAuth] Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ [YahooOAuth] NSError domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ [YahooOAuth] NSError userInfo: \(nsError.userInfo)")
            }
            await MainActor.run {
                authenticationError = error.localizedDescription
                isAuthenticating = false
            }
        }
    }
    
    /**
     * Refreshes tokens for all connected accounts that are expired or close to expiring
     */
    func refreshExpiredTokens() async {
        print("🔄 [YahooOAuth] Checking for expired tokens...")
        
        for account in connectedAccounts {
            // Refresh tokens that are expired or will expire in the next 5 minutes
            if account.isExpired || account.expiresAt.timeIntervalSinceNow < 300 {
                print("🔄 [YahooOAuth] Refreshing token for expired account: \(account.email)")
                do {
                    _ = try await refreshToken(for: account)
                    print("✅ [YahooOAuth] Successfully refreshed token for: \(account.email)")
                } catch {
                    print("❌ [YahooOAuth] Failed to refresh token for \(account.email): \(error)")
                }
            }
        }
    }
    
    /**
     * Refreshes access token for a specific Yahoo account
     */
    func refreshToken(for account: YahooAccount) async throws -> YahooAccount {
        let refreshRequest = YahooTokenRefreshRequest(
            grantType: "refresh_token",
            refreshToken: account.refreshToken,
            clientID: YahooConfig.clientID
        )
        
        let tokens = try await performTokenRefresh(request: refreshRequest)
        
        let updatedAccount = YahooAccount(
            id: account.id,
            email: account.email,
            name: account.name,
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokens.expiresIn))
        )
        
        try await updateStoredAccount(updatedAccount)
        
        await MainActor.run {
            if let index = connectedAccounts.firstIndex(where: { $0.id == account.id }) {
                connectedAccounts[index] = updatedAccount
            }
        }
        
        return updatedAccount
    }
    
    /**
     * Removes a Yahoo account and cleans up stored tokens
     */
    func removeAccount(_ account: YahooAccount) async throws {
        try await keychain.delete(service: "yahoo_oauth", account: account.email)
        
        await MainActor.run {
            connectedAccounts.removeAll { $0.id == account.id }
        }
    }
    
    /**
     * Checks if a Yahoo account with the given email is already connected
     */
    func isAccountConnected(email: String) -> Bool {
        return connectedAccounts.contains { $0.email == email }
    }
    
    /**
     * Gets a connected Yahoo account by email
     */
    func getAccount(email: String) -> YahooAccount? {
        return connectedAccounts.first { $0.email == email }
    }
    
    /**
     * Loads all stored Yahoo accounts on app launch
     */
    func loadStoredAccounts() async {
        print("📱 [YahooOAuth] Loading stored Yahoo accounts from Keychain...")
        
        do {
            // Get list of all Yahoo accounts stored in Keychain
            let accountEmails = try await keychain.listAccounts(for: "yahoo_oauth")
            print("📱 [YahooOAuth] Found \(accountEmails.count) stored Yahoo accounts: \(accountEmails)")
            
            var loadedAccounts: [YahooAccount] = []
            
            // Load each account from Keychain
            for email in accountEmails {
                do {
                    if let accountData = try await keychain.load(service: "yahoo_oauth", account: email) {
                        let account = try JSONDecoder().decode(YahooAccount.self, from: accountData)
                        loadedAccounts.append(account)
                        print("✅ [YahooOAuth] Loaded account: \(account.email)")
                    }
                } catch {
                    print("❌ [YahooOAuth] Failed to load account for \(email): \(error)")
                }
            }
            
            // Update UI on main thread
            let finalAccounts = loadedAccounts
            await MainActor.run {
                // Replace all accounts with loaded ones (this ensures no duplicates from Keychain)
                connectedAccounts = finalAccounts
                print("📱 [YahooOAuth] Updated connectedAccounts with \(finalAccounts.count) accounts from Keychain")
            }
            
            print("📱 [YahooOAuth] Successfully loaded \(loadedAccounts.count) Yahoo accounts")
            
        } catch {
            print("❌ [YahooOAuth] Failed to load stored accounts: \(error)")
            await MainActor.run {
                connectedAccounts = []
            }
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Builds Yahoo OAuth authorization URL with required parameters
     */
    private func buildAuthURL() throws -> URL {
        let buildStartTimestamp = ISO8601DateFormatter().string(from: Date())
        print("🛠️ [YahooOAuth] buildAuthURL invoked at: \(buildStartTimestamp)")
        guard var components = URLComponents(string: YahooConfig.authURL) else {
            print("❌ [YahooOAuth] Invalid base auth URL: \(YahooConfig.authURL)")
            throw YahooOAuthError.invalidAuthURL
        }
        
        let state = UUID().uuidString
        let nonce = UUID().uuidString
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        currentCodeVerifier = codeVerifier
        print("🛠️ [YahooOAuth] Generated state: \(state)")
        print("🛠️ [YahooOAuth] Generated nonce: \(nonce)")
        print("🛠️ [YahooOAuth] Generated code verifier: \(codeVerifier)")
        print("🛠️ [YahooOAuth] Generated code challenge: \(codeChallenge)")

        let queryItems = [
            URLQueryItem(name: "client_id", value: YahooConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: YahooConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: YahooConfig.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "nonce", value: nonce),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        
        components.queryItems = queryItems
        print("🧮 [YahooOAuth] percentEncodedQuery before replacement: \(String(describing: components.percentEncodedQuery))")
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        print("🧮 [YahooOAuth] percentEncodedQuery after replacement: \(String(describing: components.percentEncodedQuery))")
        guard let percentEncodedQuery = components.percentEncodedQuery,
              let encodedPercentEncodedQuery = percentEncodedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ [YahooOAuth] Failed to percent-encode query parameters")
            throw YahooOAuthError.invalidAuthURL
        }
        components.percentEncodedQuery = encodedPercentEncodedQuery
        print("🧮 [YahooOAuth] percentEncodedQuery after final encoding: \(encodedPercentEncodedQuery)")
        
        guard let url = components.url else {
            print("❌ [YahooOAuth] Failed to construct final OAuth URL from components")
            throw YahooOAuthError.invalidAuthURL
        }
        
        print("🔧 [YahooOAuth] Final OAuth parameters summary:")
        print("   • Client ID prefix: \(YahooConfig.clientID.prefix(12))…")
        print("   • Redirect URI: \(YahooConfig.redirectURI)")
        print("   • Scope: \(YahooConfig.scopes.joined(separator: " "))")
        print("   • State: \(state)")
        print("   • Nonce: \(nonce)")
        print("   • Code Challenge: \(codeChallenge)")
        if let currentCodeVerifier {
            print("   • Stored code verifier for exchange: \(currentCodeVerifier)")
        }
        print("🔗 [YahooOAuth] Final OAuth URL: \(url.absoluteString)")
        return url
    }
    
    /**
     * Performs ASWebAuthenticationSession for OAuth flow
     */
    private func performAuthentication(with url: URL) async throws -> String? {
        print("🚀 [YahooOAuth] Starting ASWebAuthenticationSession with URL: \(url.absoluteString)")
        let presentationTimestamp = ISO8601DateFormatter().string(from: Date())
        print("🕒 [YahooOAuth] ASWebAuthenticationSession started at: \(presentationTimestamp)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "emailclean"
            ) { callbackURL, error in
                let callbackTimestamp = ISO8601DateFormatter().string(from: Date())
                print("📱 [YahooOAuth] ASWebAuthenticationSession callback at: \(callbackTimestamp)")
                print("📱 [YahooOAuth] Callback URL: \(callbackURL?.absoluteString ?? "nil")")
                print("📱 [YahooOAuth] Error: \(error?.localizedDescription ?? "nil")")
                
                if let error = error {
                    let nsError = error as NSError
                    print("❌ [YahooOAuth] ASWebAuthenticationSession error domain: \(nsError.domain)")
                    print("❌ [YahooOAuth] ASWebAuthenticationSession error code: \(nsError.code)")
                    print("❌ [YahooOAuth] ASWebAuthenticationSession userInfo: \(nsError.userInfo)")
                    if nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: OAuthError.userCancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    print("❌ [YahooOAuth] No callback URL received.")
                    continuation.resume(throwing: YahooOAuthError.missingAuthCode)
                    return
                }
                
                guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
                    print("❌ [YahooOAuth] Failed to parse callback URL components.")
                    continuation.resume(throwing: YahooOAuthError.invalidCallback)
                    return
                }
                let callbackParams = components.queryItems?.map { "\($0.name)=\($0.value ?? "nil")" }.joined(separator: " | ") ?? "<none>"
                print("🧩 [YahooOAuth] Callback query parameters: \(callbackParams)")
                
                if let errorParam = components.queryItems?.first(where: { $0.name == "error" })?.value {
                    let description = components.queryItems?.first(where: { $0.name == "error_description" })?.value ?? "Unknown error"
                    print("❌ [YahooOAuth] OAuth error returned by provider: \(errorParam) – \(description)")
                    continuation.resume(throwing: YahooOAuthError.providerError(description))
                    return
                }
                
                guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    print("❌ [YahooOAuth] Authorization code missing in callback.")
                    continuation.resume(throwing: YahooOAuthError.missingAuthCode)
                    return
                }
                
                print("✅ [YahooOAuth] Received authorization code: \(code)")
                continuation.resume(returning: code)
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            print("🪟 [YahooOAuth] presentationContextProvider set to self. prefersEphemeralWebBrowserSession=true")
            let started = session.start()
            print("🚀 [YahooOAuth] ASWebAuthenticationSession started (result): \(started)")
            
            Task { @MainActor in
                self.currentAuthSession = session
            }
        }
    }
    
    /**
     * Exchanges authorization code for access and refresh tokens
     */
    private func exchangeCodeForTokens(code: String) async throws -> YahooTokenResponse {
        let tokenRequest = YahooTokenRequest(
            grantType: "authorization_code",
            code: code,
            redirectURI: YahooConfig.redirectURI,
            clientID: YahooConfig.clientID,
            codeVerifier: currentCodeVerifier
        )

        let tokens = try await performTokenExchange(request: tokenRequest)
        currentCodeVerifier = nil
        return tokens
    }
    
    /**
     * Fetches user information using access token
     */
    private func fetchUserInfo(accessToken: String) async throws -> YahooUserInfo {
        guard let url = URL(string: YahooConfig.userInfoURL) else {
            throw YahooOAuthError.invalidUserInfoURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw YahooOAuthError.userInfoFetchFailed
        }
        
        return try JSONDecoder().decode(YahooUserInfo.self, from: data)
    }
    
    /**
     * Performs token exchange HTTP request
     */
    private func performTokenExchange(request: YahooTokenRequest) async throws -> YahooTokenResponse {
        guard let url = URL(string: YahooConfig.tokenURL) else {
            throw YahooOAuthError.invalidTokenURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = request.toURLEncodedString()
        urlRequest.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw YahooOAuthError.tokenExchangeFailed
        }
        
        return try JSONDecoder().decode(YahooTokenResponse.self, from: data)
    }
    
    /**
     * Performs token refresh HTTP request
     */
    private func performTokenRefresh(request: YahooTokenRefreshRequest) async throws -> YahooTokenResponse {
        guard let url = URL(string: YahooConfig.tokenURL) else {
            throw YahooOAuthError.invalidTokenURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = request.toURLEncodedString()
        urlRequest.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw YahooOAuthError.tokenRefreshFailed
        }
        
        return try JSONDecoder().decode(YahooTokenResponse.self, from: data)
    }
    
    /**
     * Stores Yahoo account securely in Keychain
     */
    private func storeAccount(_ account: YahooAccount) async throws {
        let accountData = try JSONEncoder().encode(account)
        try await keychain.save(data: accountData, service: "yahoo_oauth", account: account.email)
    }
    
    /**
     * Updates stored Yahoo account in Keychain
     */
    private func updateStoredAccount(_ account: YahooAccount) async throws {
        try await storeAccount(account) // Overwrites existing
    }

    private func generateCodeVerifier() -> String {
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

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return base64URLEncode(Data(hash))
    }

    private func base64URLEncode(_ data: Data) -> String {
        let encoded = data.base64EncodedString()
        return encoded
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension YahooOAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Ensure UI access happens on main thread
        return DispatchQueue.main.sync {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("No window available for Yahoo OAuth presentation")
            }
            return window
        }
    }
}

// MARK: - Supporting Types

/**
 * Yahoo account model for multiple account support
 */
struct YahooAccount: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
}

/**
 * Yahoo OAuth token response model
 */
struct YahooTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

/**
 * Yahoo user information model
 */
struct YahooUserInfo: Codable {
    let sub: String
    let email: String
    let emailVerified: Bool
    let name: String
    let givenName: String
    let familyName: String
    
    enum CodingKeys: String, CodingKey {
        case sub, email, name
        case emailVerified = "email_verified"
        case givenName = "given_name"
        case familyName = "family_name"
    }
}

/**
 * Yahoo token request model (Public Client - no client secret)
 */
struct YahooTokenRequest {
    let grantType: String
    let code: String
    let redirectURI: String
    let clientID: String
    let codeVerifier: String?
    
    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case code
        case redirectURI = "redirect_uri"
        case clientID = "client_id"
        case codeVerifier = "code_verifier"
    }
    
    func toURLEncodedString() -> String {
        var params: [String: String] = [
            "grant_type": grantType,
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientID
        ]
        if let codeVerifier {
            params["code_verifier"] = codeVerifier
        }
        return params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }
}

/**
 * Yahoo token refresh request model (Public Client - no client secret)
 */
struct YahooTokenRefreshRequest {
    let grantType: String
    let refreshToken: String
    let clientID: String
    
    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
        case clientID = "client_id"
    }
    
    func toURLEncodedString() -> String {
        let params = [
            "grant_type": grantType,
            "refresh_token": refreshToken,
            "client_id": clientID
        ]
        
        return params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    }
}

/**
 * Yahoo OAuth specific errors
 */
enum YahooOAuthError: LocalizedError {
    case invalidAuthURL
    case missingAuthCode
    case invalidTokenURL
    case tokenExchangeFailed
    case tokenRefreshFailed
    case invalidUserInfoURL
    case userInfoFetchFailed
    case providerError(String)
    case invalidCallback
    
    var errorDescription: String? {
        switch self {
        case .invalidAuthURL:
            return "Invalid Yahoo OAuth authorization URL"
        case .missingAuthCode:
            return "Missing authorization code from Yahoo"
        case .invalidTokenURL:
            return "Invalid Yahoo token URL"
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for tokens"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        case .invalidUserInfoURL:
            return "Invalid Yahoo user info URL"
        case .userInfoFetchFailed:
            return "Failed to fetch user information from Yahoo"
        case .providerError(let description):
            return "OAuth provider returned an error: \(description)"
        case .invalidCallback:
            return "Invalid callback URL received from Yahoo"
        }
    }
}
