import Foundation

// MARK: - Protocol Definition
protocol BackendAPIClientProtocol {
    func initiateOAuthFlow(provider: EmailProvider) async throws -> URL
    func exchangeOAuthCode(provider: EmailProvider, authCode: String) async throws -> OAuthTokenResponse
    func registerEmailAccount(provider: EmailProvider, accessToken: String) async throws -> EmailAccount
    func fetchEmails(accountId: String?, category: EmailCategory?) async throws -> [Email]
    func markEmailAsRead(emailId: String) async throws
    func deleteEmail(emailId: String) async throws
    func archiveEmail(emailId: String) async throws
    func recategorizeEmail(emailId: String, newCategory: EmailCategory) async throws
    func reportSpam(emailId: String) async throws
    func whitelistSender(senderEmail: String) async throws
    func blacklistSender(senderEmail: String) async throws
    func updateUserPreferences(preferences: UserPreferences) async throws
    func getUserStatistics() async throws -> UserStatistics
}

// MARK: - Implementation
class BackendAPIClient: BackendAPIClientProtocol {
    private let session = URLSession.shared
    private let baseURL = "https://api.emailclean.com/v1" // Replace with actual backend URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        // Configure date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
    }
    
    // MARK: - OAuth Flow
    func initiateOAuthFlow(provider: EmailProvider) async throws -> URL {
        let endpoint = "\(baseURL)/auth/oauth/initiate"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OAuthInitiateRequest(provider: provider.rawValue)
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let oauthResponse = try decoder.decode(OAuthInitiateResponse.self, from: data)
        return oauthResponse.authorizationURL
    }
    
    func exchangeOAuthCode(provider: EmailProvider, authCode: String) async throws -> OAuthTokenResponse {
        let endpoint = "\(baseURL)/auth/oauth/exchange"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OAuthExchangeRequest(
            provider: provider.rawValue,
            authorizationCode: authCode
        )
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        // For demo purposes, return mock tokens
        return OAuthTokenResponse(
            accessToken: "demo_access_token_\(provider.rawValue)",
            refreshToken: "demo_refresh_token_\(provider.rawValue)",
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: provider.oauthScopes.joined(separator: " ")
        )
    }
    
    func registerEmailAccount(provider: EmailProvider, accessToken: String) async throws -> EmailAccount {
        let endpoint = "\(baseURL)/accounts/register"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body = RegisterAccountRequest(
            provider: provider.rawValue,
            accessToken: accessToken
        )
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        // For demo purposes, return mock account
        return EmailAccount(
            name: "\(provider.displayName) Account",
            email: "user@\(provider.rawValue.lowercased()).com",
            provider: provider,
            isConnected: true,
            lastSyncDate: Date(),
            syncStatus: .completed
        )
    }
    
    // MARK: - Email Operations
    func fetchEmails(accountId: String? = nil, category: EmailCategory? = nil) async throws -> [Email] {
        var components = URLComponents(string: "\(baseURL)/emails")!
        var queryItems: [URLQueryItem] = []
        
        if let accountId = accountId {
            queryItems.append(URLQueryItem(name: "account_id", value: accountId))
        }
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        await addAuthenticationHeaders(to: &request)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        // For demo purposes, return sample emails
        return Email.sampleEmails
    }
    
    func markEmailAsRead(emailId: String) async throws {
        let endpoint = "\(baseURL)/emails/\(emailId)/read"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        await addAuthenticationHeaders(to: &request)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    func deleteEmail(emailId: String) async throws {
        let endpoint = "\(baseURL)/emails/\(emailId)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        await addAuthenticationHeaders(to: &request)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    func archiveEmail(emailId: String) async throws {
        let endpoint = "\(baseURL)/emails/\(emailId)/archive"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        await addAuthenticationHeaders(to: &request)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    func recategorizeEmail(emailId: String, newCategory: EmailCategory) async throws {
        let endpoint = "\(baseURL)/emails/\(emailId)/categorize"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await addAuthenticationHeaders(to: &request)
        
        let body = RecategorizeRequest(category: newCategory.rawValue)
        request.httpBody = try encoder.encode(body)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    func reportSpam(emailId: String) async throws {
        let endpoint = "\(baseURL)/emails/\(emailId)/spam"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        await addAuthenticationHeaders(to: &request)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    func whitelistSender(senderEmail: String) async throws {
        let endpoint = "\(baseURL)/senders/whitelist"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await addAuthenticationHeaders(to: &request)
        
        let body = SenderActionRequest(senderEmail: senderEmail)
        request.httpBody = try encoder.encode(body)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    func blacklistSender(senderEmail: String) async throws {
        let endpoint = "\(baseURL)/senders/blacklist"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await addAuthenticationHeaders(to: &request)
        
        let body = SenderActionRequest(senderEmail: senderEmail)
        request.httpBody = try encoder.encode(body)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    func updateUserPreferences(preferences: UserPreferences) async throws {
        let endpoint = "\(baseURL)/user/preferences"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await addAuthenticationHeaders(to: &request)
        
        request.httpBody = try encoder.encode(preferences)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    func getUserStatistics() async throws -> UserStatistics {
        let endpoint = "\(baseURL)/user/statistics"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        await addAuthenticationHeaders(to: &request)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        // For demo purposes, return sample statistics
        return UserStatistics(
            totalEmailsProcessed: 2347,
            emailsAutoDeleted: 1456,
            emailsCategorized: 2347,
            timeSavedMinutes: 182,
            spamEmailsBlocked: 89,
            averageEmailsPerDay: 47.3,
            topEmailCategory: .promotions
        )
    }
    
    // MARK: - Helper Methods
    private func addAuthenticationHeaders(to request: inout URLRequest) async {
        // In a real implementation, this would retrieve the current user's auth token
        // For demo purposes, we'll use a placeholder token
        request.setValue("Bearer demo_user_token", forHTTPHeaderField: "Authorization")
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidURL
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 400:
            throw APIError.invalidURL
        case 401:
            throw APIError.authenticationFailed
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.unknownError
        }
    }
}

// MARK: - Request/Response Models
struct OAuthInitiateRequest: Codable {
    let provider: String
}

struct OAuthInitiateResponse: Codable {
    let authorizationURL: URL
    let state: String
    
    enum CodingKeys: String, CodingKey {
        case authorizationURL = "authorization_url"
        case state
    }
}

struct OAuthExchangeRequest: Codable {
    let provider: String
    let authorizationCode: String
    
    enum CodingKeys: String, CodingKey {
        case provider
        case authorizationCode = "authorization_code"
    }
}

struct RegisterAccountRequest: Codable {
    let provider: String
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case provider
        case accessToken = "access_token"
    }
}

struct RecategorizeRequest: Codable {
    let category: String
}

struct SenderActionRequest: Codable {
    let senderEmail: String
    
    enum CodingKeys: String, CodingKey {
        case senderEmail = "sender_email"
    }
} 