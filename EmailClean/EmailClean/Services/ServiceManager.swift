import SwiftUI
import Combine

/**
 * ServiceManager provides shared instances of services across the app
 * Ensures consistent data flow and state management
 */
@MainActor
class ServiceManager: ObservableObject {
    
    // MARK: - Shared Service Instances
    static let shared = ServiceManager()
    
    let yahooOAuthService: YahooOAuthService
    let yahooMailService: YahooMailService
    let emailAccountService: EmailAccountServiceProtocol
    let backendAPIClient: BackendAPIClientProtocol
    
    // MARK: - Published Properties
    @Published var allEmails: [Email] = []
    @Published var isLoading = false
    @Published var lastRefreshDate: Date?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        self.yahooOAuthService = YahooOAuthService()
        self.yahooMailService = YahooMailService()
        self.emailAccountService = EmailAccountService()
        self.backendAPIClient = BackendAPIClient()
        
        setupObservers()
    }
    
    /**
     * Initializes the ServiceManager by loading stored accounts
     * Should be called once when the app starts
     */
    func initialize() async {
        print("🚀 [ServiceManager] Initializing ServiceManager...")
        await yahooOAuthService.loadStoredAccounts()
        
        // Refresh any expired tokens to ensure accounts remain active
        await yahooOAuthService.refreshExpiredTokens()
        
        print("🚀 [ServiceManager] ServiceManager initialization completed")
    }
    
    // MARK: - Setup
    
    /**
     * Sets up observers to automatically sync data across services
     */
    private func setupObservers() {
        // Observe Yahoo account changes and refresh emails
        yahooOAuthService.$connectedAccounts
            .sink { [weak self] accounts in
                print("📊 [ServiceManager] Yahoo accounts changed: \(accounts.count) accounts")
                Task {
                    await self?.refreshAllEmails()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /**
     * Refreshes emails from all connected Yahoo accounts
     */
    func refreshAllEmails() async {
        isLoading = true
        
        do {
            print("📧 [ServiceManager] Starting email refresh...")
            print("📧 [ServiceManager] Connected Yahoo accounts: \(yahooOAuthService.connectedAccounts.count)")
            
            var allEmails: [Email] = []
            
            if yahooOAuthService.connectedAccounts.isEmpty {
                print("📧 [ServiceManager] No Yahoo accounts connected")
                // Don't fetch any emails if no accounts are connected
                allEmails = []
            } else {
                // Fetch emails from connected Yahoo accounts using progressive loading
                for account in yahooOAuthService.connectedAccounts {
                    print("📧 [ServiceManager] Starting progressive email fetch from account: \(account.email)")
                    
                    do {
                        // Use progressive loading to handle large volumes efficiently
                        let yahooEmails = try await yahooMailService.fetchEmailsProgressively(
                            from: account,
                            folder: "Inbox",
                            batchSize: 25, // Fetch 25 emails per batch
                            maxBatches: 10 // Maximum 10 batches (250 emails total)
                        ) { batchNumber, currentEmails in
                            // Update UI progressively as emails are loaded
                            Task { @MainActor in
                                let convertedEmails = currentEmails.map { yahooEmail in
                                    Email(
                                        id: yahooEmail.id,
                                        subject: yahooEmail.subject,
                                        sender: EmailSender(name: yahooEmail.sender, email: yahooEmail.senderEmail),
                                        recipients: [EmailRecipient(name: yahooEmail.recipient, email: yahooEmail.recipient, type: .to)],
                                        body: yahooEmail.snippet,
                                        snippet: yahooEmail.snippet,
                                        timestamp: yahooEmail.date,
                                        isRead: yahooEmail.isRead,
                                        isImportant: yahooEmail.isImportant,
                                        hasAttachments: yahooEmail.hasAttachments,
                                        category: .primary,
                                        threadId: nil,
                                        attachments: []
                                    )
                                }
                                
                                // Update emails progressively
                                self.allEmails = convertedEmails.sorted { $0.timestamp > $1.timestamp }
                                print("📧 [ServiceManager] Updated UI with \(self.allEmails.count) emails after batch \(batchNumber)")
                            }
                        }
                        
                        print("📧 [ServiceManager] Completed progressive fetch for \(account.email): \(yahooEmails.count) emails")
                        
                        // Convert final batch of Yahoo emails to our Email model
                        let convertedEmails = yahooEmails.map { yahooEmail in
                            Email(
                                id: yahooEmail.id,
                                subject: yahooEmail.subject,
                                sender: EmailSender(name: yahooEmail.sender, email: yahooEmail.senderEmail),
                                recipients: [EmailRecipient(name: yahooEmail.recipient, email: yahooEmail.recipient, type: .to)],
                                body: yahooEmail.snippet,
                                snippet: yahooEmail.snippet,
                                timestamp: yahooEmail.date,
                                isRead: yahooEmail.isRead,
                                isImportant: yahooEmail.isImportant,
                                hasAttachments: yahooEmail.hasAttachments,
                                category: .primary,
                                threadId: nil,
                                attachments: []
                            )
                        }
                        
                        allEmails.append(contentsOf: convertedEmails)
                        
                    } catch {
                        print("❌ [ServiceManager] Error fetching emails from \(account.email): \(error)")
                        // Continue with other accounts even if one fails
                    }
                }
                
                allEmails = allEmails.sorted { $0.timestamp > $1.timestamp }
            }
            
            self.allEmails = allEmails
            self.lastRefreshDate = Date()
            self.isLoading = false
            
            print("✅ [ServiceManager] Email refresh completed. Total emails: \(allEmails.count)")
            
        } catch {
            self.isLoading = false
            print("❌ [ServiceManager] Email refresh error: \(error)")
        }
    }
    
    /**
     * Gets email statistics for display across the app
     */
    var emailStatistics: EmailStatistics {
        let totalEmails = allEmails.count
        let unreadEmails = allEmails.filter { !$0.isRead }.count
        let primaryEmails = allEmails.filter { $0.category == .primary }.count
        let spamEmails = allEmails.filter { $0.category == .spam }.count
        let promotionEmails = allEmails.filter { $0.category == .promotions }.count
        
        return EmailStatistics(
            totalEmails: totalEmails,
            unreadEmails: unreadEmails,
            primaryEmails: primaryEmails,
            spamEmails: spamEmails,
            promotionEmails: promotionEmails,
            connectedAccounts: yahooOAuthService.connectedAccounts.count
        )
    }
    
    /**
     * Gets emails filtered by category
     */
    func getEmails(for category: EmailCategory) -> [Email] {
        let categoryFiltered = allEmails.filter { email in
            category == .primary ? 
                email.category == .primary : 
                email.category == category
        }
        
        return categoryFiltered.sorted { $0.timestamp > $1.timestamp }
    }
    
    /**
     * Gets category count for filter buttons
     */
    func getCategoryCount(_ category: EmailCategory) -> Int {
        return allEmails.filter { $0.category == category }.count
    }
}

// MARK: - Supporting Types

/**
 * Email statistics model for dashboard display
 */
struct EmailStatistics {
    let totalEmails: Int
    let unreadEmails: Int
    let primaryEmails: Int
    let spamEmails: Int
    let promotionEmails: Int
    let connectedAccounts: Int
    
    var unreadPercentage: Double {
        guard totalEmails > 0 else { return 0 }
        return Double(unreadEmails) / Double(totalEmails) * 100
    }
    
    var spamPercentage: Double {
        guard totalEmails > 0 else { return 0 }
        return Double(spamEmails) / Double(totalEmails) * 100
    }
}
