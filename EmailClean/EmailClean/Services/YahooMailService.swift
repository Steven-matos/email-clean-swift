import Foundation

/**
 * YahooMailService handles Yahoo Mail API operations
 * Supports fetching emails, managing folders, and email operations
 */
class YahooMailService: ObservableObject {
    
    // MARK: - Private Properties
    private let baseURL = "https://mail.yahooapis.com/ws/mail/v1.1"
    
    // MARK: - Public Methods
    
    /**
     * Fetches emails from a specific Yahoo account and folder
     * @param account: Yahoo account to fetch emails from
     * @param folder: Folder name (e.g., "Inbox", "Sent")
     * @param limit: Maximum number of emails to fetch
     * @param offset: Offset for pagination (default: 0)
     * @return: Array of Yahoo emails
     */
    func fetchEmails(from account: YahooAccount, folder: String = "Inbox", limit: Int = 50, offset: Int = 0) async throws -> [YahooEmail] {
        // Ensure we have a valid access token
        let validAccount = try await ensureValidToken(for: account)
        
        let endpoint = "\(baseURL)/mailbox/\(folder)"
        
        guard let url = URL(string: endpoint) else {
            throw YahooMailError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(validAccount.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add query parameters for pagination
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "sort", value: "date"),
            URLQueryItem(name: "order", value: "desc")
        ]
        
        if let finalURL = components?.url {
            request.url = finalURL
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooMailError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let yahooResponse = try JSONDecoder().decode(YahooMailResponse.self, from: data)
            return yahooResponse.messages.map { $0.toEmail() }
        case 401:
            throw YahooMailError.unauthorized
        case 403:
            throw YahooMailError.forbidden
        default:
            throw YahooMailError.serverError(httpResponse.statusCode)
        }
    }
    
    /**
     * Fetches emails progressively in batches to handle large volumes
     * @param account: Yahoo account to fetch emails from
     * @param folder: Folder name (e.g., "Inbox", "Sent")
     * @param batchSize: Number of emails to fetch per batch (default: 25)
     * @param maxBatches: Maximum number of batches to fetch (default: 10)
     * @param onProgress: Callback called after each batch is fetched
     * @return: Array of all fetched Yahoo emails
     */
    func fetchEmailsProgressively(
        from account: YahooAccount,
        folder: String = "Inbox",
        batchSize: Int = 25,
        maxBatches: Int = 10,
        onProgress: @escaping (Int, [YahooEmail]) -> Void = { _, _ in }
    ) async throws -> [YahooEmail] {
        print("📧 [YahooMailService] Starting progressive email fetch for \(account.email)")
        print("📧 [YahooMailService] Batch size: \(batchSize), Max batches: \(maxBatches)")
        
        var allEmails: [YahooEmail] = []
        var currentOffset = 0
        var batchCount = 0
        
        while batchCount < maxBatches {
            print("📧 [YahooMailService] Fetching batch \(batchCount + 1) (offset: \(currentOffset))")
            
            do {
                let batchEmails = try await fetchEmails(
                    from: account,
                    folder: folder,
                    limit: batchSize,
                    offset: currentOffset
                )
                
                print("📧 [YahooMailService] Batch \(batchCount + 1) fetched \(batchEmails.count) emails")
                
                // If we got fewer emails than requested, we've reached the end
                if batchEmails.count < batchSize {
                    allEmails.append(contentsOf: batchEmails)
                    onProgress(batchCount + 1, allEmails)
                    print("📧 [YahooMailService] Reached end of emails (got \(batchEmails.count) < \(batchSize))")
                    break
                }
                
                allEmails.append(contentsOf: batchEmails)
                onProgress(batchCount + 1, allEmails)
                
                currentOffset += batchSize
                batchCount += 1
                
                // Small delay between batches to be respectful to the API
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
            } catch {
                print("❌ [YahooMailService] Error fetching batch \(batchCount + 1): \(error)")
                // Continue with next batch or break if it's a critical error
                if case YahooMailError.unauthorized = error {
                    throw error // Stop on auth errors
                }
                batchCount += 1
                currentOffset += batchSize
            }
        }
        
        print("📧 [YahooMailService] Progressive fetch completed. Total emails: \(allEmails.count)")
        return allEmails
    }
    
    /**
     * Fetches email details by ID
     * @param account: Yahoo account
     * @param emailId: Email identifier
     * @return: Detailed email information
     */
    func fetchEmailDetails(from account: YahooAccount, emailId: String) async throws -> YahooEmailDetails {
        let validAccount = try await ensureValidToken(for: account)
        
        let endpoint = "\(baseURL)/message/\(emailId)"
        
        guard let url = URL(string: endpoint) else {
            throw YahooMailError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(validAccount.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooMailError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(YahooEmailDetails.self, from: data)
        case 401:
            throw YahooMailError.unauthorized
        case 404:
            throw YahooMailError.emailNotFound
        default:
            throw YahooMailError.serverError(httpResponse.statusCode)
        }
    }
    
    /**
     * Marks emails as read/unread
     * @param account: Yahoo account
     * @param emailIds: Array of email IDs
     * @param isRead: Read status to set
     */
    func markEmailsAsRead(from account: YahooAccount, emailIds: [String], isRead: Bool) async throws {
        let validAccount = try await ensureValidToken(for: account)
        
        let endpoint = "\(baseURL)/messages/mark"
        
        guard let url = URL(string: endpoint) else {
            throw YahooMailError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(validAccount.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = YahooMarkRequest(
            messageIds: emailIds,
            read: isRead
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooMailError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return // Success
        case 401:
            throw YahooMailError.unauthorized
        default:
            throw YahooMailError.serverError(httpResponse.statusCode)
        }
    }
    
    /**
     * Deletes emails
     * @param account: Yahoo account
     * @param emailIds: Array of email IDs to delete
     */
    func deleteEmails(from account: YahooAccount, emailIds: [String]) async throws {
        let validAccount = try await ensureValidToken(for: account)
        
        let endpoint = "\(baseURL)/messages/delete"
        
        guard let url = URL(string: endpoint) else {
            throw YahooMailError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(validAccount.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = YahooDeleteRequest(messageIds: emailIds)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooMailError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return // Success
        case 401:
            throw YahooMailError.unauthorized
        default:
            throw YahooMailError.serverError(httpResponse.statusCode)
        }
    }
    
    /**
     * Fetches available folders for a Yahoo account
     * @param account: Yahoo account
     * @return: Array of folder information
     */
    func fetchFolders(from account: YahooAccount) async throws -> [YahooFolder] {
        let validAccount = try await ensureValidToken(for: account)
        
        let endpoint = "\(baseURL)/folders"
        
        guard let url = URL(string: endpoint) else {
            throw YahooMailError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(validAccount.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooMailError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let foldersResponse = try JSONDecoder().decode(YahooFoldersResponse.self, from: data)
            return foldersResponse.folders
        case 401:
            throw YahooMailError.unauthorized
        default:
            throw YahooMailError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Ensures the account has a valid access token, refreshes if necessary
     */
    private func ensureValidToken(for account: YahooAccount) async throws -> YahooAccount {
        if account.isExpired {
            // Token is expired, need to refresh
            let yahooOAuthService = YahooOAuthService()
            return try await yahooOAuthService.refreshToken(for: account)
        }
        return account
    }
}

// MARK: - Supporting Types

/**
 * Yahoo email model
 */
struct YahooEmail: Identifiable, Codable {
    let id: String
    let subject: String
    let sender: String
    let senderEmail: String
    let recipient: String
    let date: Date
    let isRead: Bool
    let isImportant: Bool
    let snippet: String
    let folder: String
    let hasAttachments: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, subject, sender, recipient, date, snippet, folder
        case senderEmail = "sender_email"
        case isRead = "is_read"
        case isImportant = "is_important"
        case hasAttachments = "has_attachments"
    }
}

/**
 * Yahoo email details model
 */
struct YahooEmailDetails: Codable {
    let id: String
    let subject: String
    let sender: YahooEmailContact
    let recipients: [YahooEmailContact]
    let date: Date
    let body: String
    let attachments: [YahooAttachment]
    let isRead: Bool
    let isImportant: Bool
    let folder: String
    
    enum CodingKeys: String, CodingKey {
        case id, subject, sender, recipients, date, body, attachments, folder
        case isRead = "is_read"
        case isImportant = "is_important"
    }
}

/**
 * Yahoo email contact model
 */
struct YahooEmailContact: Codable {
    let name: String
    let email: String
}

/**
 * Yahoo attachment model
 */
struct YahooAttachment: Codable {
    let id: String
    let filename: String
    let contentType: String
    let size: Int
    let downloadURL: String
    
    enum CodingKeys: String, CodingKey {
        case id, filename, size
        case contentType = "content_type"
        case downloadURL = "download_url"
    }
}

/**
 * Yahoo folder model
 */
struct YahooFolder: Codable {
    let id: String
    let name: String
    let unreadCount: Int
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case unreadCount = "unread_count"
        case totalCount = "total_count"
    }
}

/**
 * Yahoo API response models
 */
struct YahooMailResponse: Codable {
    let messages: [YahooMessageResponse]
}

struct YahooMessageResponse: Codable {
    let id: String
    let subject: String
    let from: String
    let to: String
    let date: Date
    let isRead: Bool
    let isImportant: Bool
    let snippet: String
    let folder: String
    let hasAttachments: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, subject, from, to, date, snippet, folder
        case isRead = "is_read"
        case isImportant = "is_important"
        case hasAttachments = "has_attachments"
    }
    
    func toEmail() -> YahooEmail {
        return YahooEmail(
            id: id,
            subject: subject,
            sender: from,
            senderEmail: from,
            recipient: to,
            date: date,
            isRead: isRead,
            isImportant: isImportant,
            snippet: snippet,
            folder: folder,
            hasAttachments: hasAttachments
        )
    }
}

struct YahooFoldersResponse: Codable {
    let folders: [YahooFolder]
}

struct YahooMarkRequest: Codable {
    let messageIds: [String]
    let read: Bool
    
    enum CodingKeys: String, CodingKey {
        case messageIds = "message_ids"
        case read
    }
}

struct YahooDeleteRequest: Codable {
    let messageIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case messageIds = "message_ids"
    }
}

/**
 * Yahoo Mail API errors
 */
enum YahooMailError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case emailNotFound
    case serverError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Yahoo Mail API URL"
        case .invalidResponse:
            return "Invalid response from Yahoo Mail API"
        case .unauthorized:
            return "Unauthorized access to Yahoo Mail API"
        case .forbidden:
            return "Forbidden access to Yahoo Mail API"
        case .emailNotFound:
            return "Email not found"
        case .serverError(let code):
            return "Yahoo Mail API server error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
