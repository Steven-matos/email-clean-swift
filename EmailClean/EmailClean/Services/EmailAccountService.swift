import Foundation
import Security

// MARK: - Protocol Definition
protocol EmailAccountServiceProtocol {
    func storeOAuthTokens(provider: EmailProvider, tokens: OAuthTokenResponse) async throws
    func retrieveOAuthTokens(provider: EmailProvider) async throws -> OAuthTokenResponse?
    func deleteOAuthTokens(provider: EmailProvider) async throws
    func refreshOAuthTokens(provider: EmailProvider) async throws -> OAuthTokenResponse
    func isAccountConnected(provider: EmailProvider) async -> Bool
    func getConnectedAccounts() async -> [EmailProvider]
}

// MARK: - Implementation
class EmailAccountService: EmailAccountServiceProtocol {
    private let keychain = KeychainManager()
    
    func storeOAuthTokens(provider: EmailProvider, tokens: OAuthTokenResponse) async throws {
        let tokenData = try JSONEncoder().encode(tokens)
        let key = "oauth_tokens_\(provider.rawValue)"
        
        try await keychain.save(key: key, data: tokenData)
    }
    
    func retrieveOAuthTokens(provider: EmailProvider) async throws -> OAuthTokenResponse? {
        let key = "oauth_tokens_\(provider.rawValue)"
        
        guard let tokenData = try await keychain.load(key: key) else {
            return nil
        }
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: tokenData)
    }
    
    func deleteOAuthTokens(provider: EmailProvider) async throws {
        let key = "oauth_tokens_\(provider.rawValue)"
        try await keychain.delete(key: key)
    }
    
    func refreshOAuthTokens(provider: EmailProvider) async throws -> OAuthTokenResponse {
        guard let currentTokens = try await retrieveOAuthTokens(provider: provider),
              let refreshToken = currentTokens.refreshToken else {
            throw EmailAccountError.noRefreshToken
        }
        
        // Make refresh token request to the provider
        let newTokens = try await performTokenRefresh(
            provider: provider,
            refreshToken: refreshToken
        )
        
        // Store the new tokens
        try await storeOAuthTokens(provider: provider, tokens: newTokens)
        
        return newTokens
    }
    
    func isAccountConnected(provider: EmailProvider) async -> Bool {
        do {
            let tokens = try await retrieveOAuthTokens(provider: provider)
            return tokens != nil
        } catch {
            return false
        }
    }
    
    func getConnectedAccounts() async -> [EmailProvider] {
        var connectedProviders: [EmailProvider] = []
        
        for provider in EmailProvider.allCases {
            if await isAccountConnected(provider: provider) {
                connectedProviders.append(provider)
            }
        }
        
        return connectedProviders
    }
    
    private func performTokenRefresh(provider: EmailProvider, refreshToken: String) async throws -> OAuthTokenResponse {
        // This would make actual API calls to refresh tokens
        // For now, we'll simulate the refresh
        
        switch provider {
        case .gmail:
            return try await refreshGmailTokens(refreshToken: refreshToken)
        case .yahoo:
            return try await refreshYahooTokens(refreshToken: refreshToken)
        }
    }
    
    private func refreshGmailTokens(refreshToken: String) async throws -> OAuthTokenResponse {
        // Gmail token refresh implementation
        // This would use URLSession to make the actual API call
        return OAuthTokenResponse(
            accessToken: "refreshed_gmail_token",
            refreshToken: refreshToken,
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: "https://www.googleapis.com/auth/gmail.readonly"
        )
    }
    
    
    private func refreshYahooTokens(refreshToken: String) async throws -> OAuthTokenResponse {
        // Yahoo token refresh implementation
        return OAuthTokenResponse(
            accessToken: "refreshed_yahoo_token",
            refreshToken: refreshToken,
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: "mail-r"
        )
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    private let service = "com.emailclean.EmailClean"
    
    func save(key: String, data: Data) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainError.unableToStore
        }
    }
    
    func load(key: String) async throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unableToLoad
        }
    }
    
    func delete(key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unableToDelete
        }
    }
    
    /**
     * Saves data with custom service and account identifiers
     * Used for storing multiple Yahoo accounts
     */
    func save(data: Data, service: String, account: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore
        }
    }
    
    /**
     * Loads data with custom service and account identifiers
     */
    func load(service: String, account: String) async throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unableToLoad
        }
    }
    
    /**
     * Deletes data with custom service and account identifiers
     */
    func delete(service: String, account: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
    
    /**
     * Lists all accounts for a specific service
     */
    func listAccounts(for service: String) async throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let items = result as? [[String: Any]] else {
                return []
            }
            
            return items.compactMap { item in
                item[kSecAttrAccount as String] as? String
            }
        case errSecItemNotFound:
            return []
        default:
            throw KeychainError.unableToLoad
        }
    }
}

// MARK: - Error Types
enum EmailAccountError: Error, LocalizedError {
    case noRefreshToken
    case unsupportedProvider
    case tokenExpired
    case invalidTokenResponse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noRefreshToken:
            return "No refresh token available"
        case .unsupportedProvider:
            return "Unsupported email provider"
        case .tokenExpired:
            return "Token has expired"
        case .invalidTokenResponse:
            return "Invalid token response"
        case .networkError:
            return "Network error occurred"
        }
    }
}

enum KeychainError: Error, LocalizedError {
    case unableToStore
    case unableToLoad
    case unableToDelete
    
    var errorDescription: String? {
        switch self {
        case .unableToStore:
            return "Unable to store item in keychain"
        case .unableToLoad:
            return "Unable to load item from keychain"
        case .unableToDelete:
            return "Unable to delete item from keychain"
        }
    }
} 