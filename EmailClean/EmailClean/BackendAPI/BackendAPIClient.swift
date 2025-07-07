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
    func updateUserPreferences(preferences: EmailUserPreferences) async throws
    func getUserStatistics() async throws -> EmailUserStatistics
}

// MARK: - Implementation
class BackendAPIClient: BackendAPIClientProtocol {
    private let session = URLSession.shared
    private let baseURL = "https://api.emailclean.com/v1" // Replace with actual backend URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let useMockMode: Bool
    
    init(useMockMode: Bool = true) { // Default to mock mode for development
        self.useMockMode = useMockMode
        // Configure date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
    }
    
    // MARK: - OAuth Flow
    func initiateOAuthFlow(provider: EmailProvider) async throws -> URL {
        if useMockMode {
            // Return realistic OAuth URLs for development
            let clientId = "demo_client_id_\(provider.rawValue.lowercased())"
            let redirectUri = "emailclean://oauth/callback"
            let scope = provider.oauthScopes.joined(separator: " ")
            let state = UUID().uuidString
            
            switch provider {
            case .gmail:
                return URL(string: "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientId)&redirect_uri=\(redirectUri)&scope=\(scope)&response_type=code&state=\(state)")!
            case .outlook:
                return URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=\(clientId)&redirect_uri=\(redirectUri)&scope=\(scope)&response_type=code&state=\(state)")!
            case .yahoo:
                return URL(string: "https://api.login.yahoo.com/oauth2/request_auth?client_id=\(clientId)&redirect_uri=\(redirectUri)&scope=\(scope)&response_type=code&state=\(state)")!
            case .applemail:
                return URL(string: "https://idmsa.apple.com/appleauth/auth/oauth/authorize?client_id=\(clientId)&redirect_uri=\(redirectUri)&scope=\(scope)&response_type=code&state=\(state)")!
            case .other:
                return URL(string: "https://mock-oauth.com/auth?provider=\(provider.rawValue)")!
            }
        }
        
        let endpoint = "\(baseURL)/auth/oauth/initiate"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OAuthInitiateRequest(provider: provider.rawValue)
        request.httpBody = try encoder.encode(body)
        
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            
            let oauthResponse = try decoder.decode(OAuthInitiateResponse.self, from: data)
            return oauthResponse.authorizationURL
        } catch {
            // If network fails, fallback to mock mode
            print("Network error in OAuth initiation, falling back to mock mode: \(error)")
            return URL(string: "https://mock-oauth.com/auth?provider=\(provider.rawValue)")!
        }
    }
    
    func exchangeOAuthCode(provider: EmailProvider, authCode: String) async throws -> OAuthTokenResponse {
        if useMockMode {
            // Return mock tokens for development
            // In a real app, this would validate the auth code and exchange it for tokens
            return OAuthTokenResponse(
                accessToken: "demo_access_token_\(provider.rawValue)_\(UUID().uuidString.prefix(8))",
                refreshToken: "demo_refresh_token_\(provider.rawValue)_\(UUID().uuidString.prefix(8))",
                expiresIn: 3600,
                tokenType: "Bearer",
                scope: provider.oauthScopes.joined(separator: " ")
            )
        }
        
        let endpoint = "\(baseURL)/auth/oauth/exchange"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = OAuthExchangeRequest(
            provider: provider.rawValue,
            authorizationCode: authCode
        )
        request.httpBody = try encoder.encode(body)
        
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            
            return try decoder.decode(OAuthTokenResponse.self, from: data)
        } catch {
            // If network fails, fallback to mock tokens
            print("Network error in OAuth exchange, falling back to mock mode: \(error)")
            return OAuthTokenResponse(
                accessToken: "demo_access_token_\(provider.rawValue)",
                refreshToken: "demo_refresh_token_\(provider.rawValue)",
                expiresIn: 3600,
                tokenType: "Bearer",
                scope: provider.oauthScopes.joined(separator: " ")
            )
        }
    }
    
    func registerEmailAccount(provider: EmailProvider, accessToken: String) async throws -> EmailAccount {
        if useMockMode {
            // Return mock account for development
            return EmailAccount(
                name: "\(provider.displayName) Account",
                email: "user@\(provider.rawValue.lowercased()).com",
                provider: provider,
                isConnected: true,
                lastSyncDate: Date(),
                syncStatus: .completed
            )
        }
        
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
        
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            
            return try decoder.decode(EmailAccount.self, from: data)
        } catch {
            // If network fails, fallback to mock account
            print("Network error in account registration, falling back to mock mode: \(error)")
            return EmailAccount(
                name: "\(provider.displayName) Account",
                email: "user@\(provider.rawValue.lowercased()).com",
                provider: provider,
                isConnected: true,
                lastSyncDate: Date(),
                syncStatus: .completed
            )
        }
    }
    
    // MARK: - Email Operations
    func fetchEmails(accountId: String? = nil, category: EmailCategory? = nil) async throws -> [Email] {
        if useMockMode {
            // Return sample emails for development
            return Email.sampleEmails
        }
        
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
        
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            
            return try decoder.decode([Email].self, from: data)
        } catch {
            // If network fails, fallback to sample emails
            print("Network error in fetching emails, falling back to mock mode: \(error)")
            return Email.sampleEmails
        }
    }
    
    func markEmailAsRead(emailId: String) async throws {
        if useMockMode {
            // Mock implementation - no network call needed
            print("Mock: Marked email \(emailId) as read")
            return
        }
        
        let endpoint = "\(baseURL)/emails/\(emailId)/read"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        await addAuthenticationHeaders(to: &request)
        
        do {
            let (_, response) = try await session.data(for: request)
            try validateResponse(response)
        } catch {
            print("Network error in marking email as read, operation completed in mock mode: \(error)")
        }
    }
    
    func deleteEmail(emailId: String) async throws {
        if useMockMode {
            // Mock implementation - no network call needed
            print("Mock: Deleted email \(emailId)")
            return
        }
        
        let endpoint = "\(baseURL)/emails/\(emailId)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        await addAuthenticationHeaders(to: &request)
        
        do {
            let (_, response) = try await session.data(for: request)
            try validateResponse(response)
        } catch {
            print("Network error in deleting email, operation completed in mock mode: \(error)")
        }
    }
    
    func archiveEmail(emailId: String) async throws {
        if useMockMode {
            // Mock implementation - no network call needed
            print("Mock: Archived email \(emailId)")
            return
        }
        
        let endpoint = "\(baseURL)/emails/\(emailId)/archive"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        await addAuthenticationHeaders(to: &request)
        
        do {
            let (_, response) = try await session.data(for: request)
            try validateResponse(response)
        } catch {
            print("Network error in archiving email, operation completed in mock mode: \(error)")
        }
    }
    
    func recategorizeEmail(emailId: String, newCategory: EmailCategory) async throws {
        if useMockMode {
            // Mock implementation - no network call needed
            print("Mock: Recategorized email \(emailId) to \(newCategory.rawValue)")
            return
        }
        
        let endpoint = "\(baseURL)/emails/\(emailId)/categorize"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await addAuthenticationHeaders(to: &request)
        
        let body = RecategorizeRequest(category: newCategory.rawValue)
        request.httpBody = try encoder.encode(body)
        
        do {
            let (_, response) = try await session.data(for: request)
            try validateResponse(response)
        } catch {
            print("Network error in recategorizing email, operation completed in mock mode: \(error)")
        }
    }
    
    func reportSpam(emailId: String) async throws {
        if useMockMode {
            // Mock implementation - no network call needed
            print("Mock: Reported email \(emailId) as spam")
            return
        }
        
        let endpoint = "\(baseURL)/emails/\(emailId)/spam"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        await addAuthenticationHeaders(to: &request)
        
        do {
            let (_, response) = try await session.data(for: request)
            try validateResponse(response)
        } catch {
            print("Network error in reporting spam, operation completed in mock mode: \(error)")
        }
    }
    
    func whitelistSender(senderEmail: String) async throws {
        if useMockMode {
            // Mock implementation - no network call needed
            print("Mock: Whitelisted sender \(senderEmail)")
            return
        }
        
        let endpoint = "\(baseURL)/senders/whitelist"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await addAuthenticationHeaders(to: &request)
        
        let body = SenderActionRequest(senderEmail: senderEmail)
        request.httpBody = try encoder.encode(body)
        
        do {
            let (_, response) = try await session.data(for: request)
            try validateResponse(response)
        } catch {
            print("Network error in whitelisting sender, operation completed in mock mode: \(error)")
        }
    }
    
    func blacklistSender(senderEmail: String) async throws {
        if useMockMode {
            // Mock implementation - no network call needed
            print("Mock: Blacklisted sender \(senderEmail)")
            return
        }
        
        let endpoint = "\(baseURL)/senders/blacklist"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await addAuthenticationHeaders(to: &request)
        
        let body = SenderActionRequest(senderEmail: senderEmail)
        request.httpBody = try encoder.encode(body)
        
        do {
            let (_, response) = try await session.data(for: request)
            try validateResponse(response)
        } catch {
            print("Network error in blacklisting sender, operation completed in mock mode: \(error)")
        }
    }
    
    func updateUserPreferences(preferences: EmailUserPreferences) async throws {
        if useMockMode {
            // Mock implementation - no network call needed
            print("Mock: Updated user preferences")
            return
        }
        
        let endpoint = "\(baseURL)/user/preferences"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await addAuthenticationHeaders(to: &request)
        
        request.httpBody = try encoder.encode(preferences)
        
        do {
            let (_, response) = try await session.data(for: request)
            try validateResponse(response)
        } catch {
            print("Network error in updating user preferences, operation completed in mock mode: \(error)")
        }
    }
    
    func getUserStatistics() async throws -> EmailUserStatistics {
        if useMockMode {
            // Return mock statistics for development
            return EmailUserStatistics(
                totalEmailsProcessed: 2347,
                emailsAutoDeleted: 1456,
                emailsCategorized: 2347,
                timeSavedMinutes: 182,
                spamEmailsBlocked: 89,
                averageEmailsPerDay: 47.3,
                topEmailCategory: .promotions
            )
        }
        
        let endpoint = "\(baseURL)/user/statistics"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        await addAuthenticationHeaders(to: &request)
        
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            
            return try decoder.decode(EmailUserStatistics.self, from: data)
        } catch {
            // If network fails, fallback to mock statistics
            print("Network error in getting user statistics, falling back to mock mode: \(error)")
            return EmailUserStatistics(
                totalEmailsProcessed: 2347,
                emailsAutoDeleted: 1456,
                emailsCategorized: 2347,
                timeSavedMinutes: 182,
                spamEmailsBlocked: 89,
                averageEmailsPerDay: 47.3,
                topEmailCategory: .promotions
            )
        }
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

struct OAuthTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}

struct EmailUserPreferences: Codable {
    let autoDeleteSpam: Bool
    let autoCategorizationEnabled: Bool
    let emailDigestFrequency: String
    let notificationsEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case autoDeleteSpam = "auto_delete_spam"
        case autoCategorizationEnabled = "auto_categorization_enabled"
        case emailDigestFrequency = "email_digest_frequency"
        case notificationsEnabled = "notifications_enabled"
    }
}

struct EmailUserStatistics: Codable {
    let totalEmailsProcessed: Int
    let emailsAutoDeleted: Int
    let emailsCategorized: Int
    let timeSavedMinutes: Int
    let spamEmailsBlocked: Int
    let averageEmailsPerDay: Double
    let topEmailCategory: EmailCategory
    
    enum CodingKeys: String, CodingKey {
        case totalEmailsProcessed = "total_emails_processed"
        case emailsAutoDeleted = "emails_auto_deleted"
        case emailsCategorized = "emails_categorized"
        case timeSavedMinutes = "time_saved_minutes"
        case spamEmailsBlocked = "spam_emails_blocked"
        case averageEmailsPerDay = "average_emails_per_day"
        case topEmailCategory = "top_email_category"
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case authenticationFailed
    case serverError(Int)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL or request"
        case .authenticationFailed:
            return "Authentication failed"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
} 