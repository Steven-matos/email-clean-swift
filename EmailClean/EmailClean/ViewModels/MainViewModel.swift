import SwiftUI
import Combine

@MainActor
class MainViewModel: ObservableObject {
    @Published var emails: [Email] = []
    @Published var selectedCategory: EmailCategory = .primary
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var searchText = ""
    @Published var connectedAccounts: [YahooAccount] = []
    
    private let emailAccountService: EmailAccountServiceProtocol
    private let backendAPIClient: BackendAPIClientProtocol
    private let yahooOAuthService: YahooOAuthService
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var filteredEmails: [Email] {
        let categoryFiltered = emails.filter { email in
            selectedCategory == .primary ? 
                email.category == .primary : 
                email.category == selectedCategory
        }
        
        if searchText.isEmpty {
            return categoryFiltered.sorted { $0.timestamp > $1.timestamp }
        } else {
            return categoryFiltered.filter { email in
                email.subject.localizedCaseInsensitiveContains(searchText) ||
                email.sender.name.localizedCaseInsensitiveContains(searchText) ||
                email.body.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    init(
        emailAccountService: EmailAccountServiceProtocol = EmailAccountService(),
        backendAPIClient: BackendAPIClientProtocol = BackendAPIClient(),
        yahooOAuthService: YahooOAuthService = YahooOAuthService()
    ) {
        self.emailAccountService = emailAccountService
        self.backendAPIClient = backendAPIClient
        self.yahooOAuthService = yahooOAuthService
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe search text changes with debounce
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe Yahoo account changes
        yahooOAuthService.$connectedAccounts
            .sink { [weak self] accounts in
                self?.connectedAccounts = accounts
                // Auto-refresh emails when accounts change
                if !accounts.isEmpty {
                    Task {
                        await self?.fetchEmails()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func loadEmails() {
        Task {
            await fetchEmails()
        }
    }
    
    func refreshEmails() {
        Task {
            await fetchEmails()
        }
    }
    
    func refreshEmailsAsync() async {
        await fetchEmails()
    }
    
    private func fetchEmails() async {
        isLoading = true
        
        do {
            print("📧 [MainViewModel] Starting email fetch...")
            print("📧 [MainViewModel] Connected Yahoo accounts: \(connectedAccounts.count)")
            
            var allEmails: [Email] = []
            
            if connectedAccounts.isEmpty {
                print("📧 [MainViewModel] No Yahoo accounts connected")
                // Don't fetch any emails if no accounts are connected
                allEmails = []
            } else {
                // Fetch emails from connected Yahoo accounts using progressive loading
                let yahooMailService = YahooMailService()
                
                for account in connectedAccounts {
                    print("📧 [MainViewModel] Starting progressive email fetch for Yahoo account: \(account.email)")
                    
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
                                self.emails = convertedEmails.sorted { $0.timestamp > $1.timestamp }
                                print("📧 [MainViewModel] Updated UI with \(self.emails.count) emails after batch \(batchNumber)")
                            }
                        }
                        
                        print("📧 [MainViewModel] Completed progressive fetch for \(account.email): \(yahooEmails.count) emails")
                        
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
                        print("❌ [MainViewModel] Error fetching emails from \(account.email): \(error)")
                        // Continue with other accounts even if one fails
                    }
                }
                
                emails = allEmails.sorted { $0.timestamp > $1.timestamp }
            }
            
            emails = allEmails
            isLoading = false
            
            print("✅ [MainViewModel] Email fetch completed. Total emails: \(allEmails.count)")
            
        } catch {
            isLoading = false
            showError(error)
        }
    }
    
    func selectCategory(_ category: EmailCategory) {
        selectedCategory = category
    }
    
    func getCategoryCount(_ category: EmailCategory) -> Int {
        emails.filter { $0.category == category }.count
    }
    
    func markAsRead(_ email: Email) {
        Task {
            do {
                try await backendAPIClient.markEmailAsRead(emailId: email.id)
                
                // Update local state
                if let index = emails.firstIndex(where: { $0.id == email.id }) {
                    emails[index] = Email(
                        id: email.id,
                        subject: email.subject,
                        sender: email.sender,
                        recipients: email.recipients,
                        body: email.body,
                        snippet: email.snippet,
                        timestamp: email.timestamp,
                        isRead: !email.isRead,
                        isImportant: email.isImportant,
                        hasAttachments: email.hasAttachments,
                        category: email.category,
                        threadId: email.threadId,
                        attachments: email.attachments
                    )
                }
                
            } catch {
                showError(error)
            }
        }
    }
    
    func deleteEmail(_ email: Email) {
        Task {
            do {
                try await backendAPIClient.deleteEmail(emailId: email.id)
                
                // Remove from local state
                emails.removeAll { $0.id == email.id }
                
            } catch {
                showError(error)
            }
        }
    }
    
    func archiveEmail(_ email: Email) {
        Task {
            do {
                try await backendAPIClient.archiveEmail(emailId: email.id)
                
                // Remove from local state (archived emails don't show in inbox)
                emails.removeAll { $0.id == email.id }
                
            } catch {
                showError(error)
            }
        }
    }
    
    func recategorizeEmail(_ email: Email, newCategory: EmailCategory) {
        Task {
            do {
                try await backendAPIClient.recategorizeEmail(
                    emailId: email.id,
                    newCategory: newCategory
                )
                
                // Update local state
                if let index = emails.firstIndex(where: { $0.id == email.id }) {
                    emails[index] = Email(
                        id: email.id,
                        subject: email.subject,
                        sender: email.sender,
                        recipients: email.recipients,
                        body: email.body,
                        snippet: email.snippet,
                        timestamp: email.timestamp,
                        isRead: email.isRead,
                        isImportant: email.isImportant,
                        hasAttachments: email.hasAttachments,
                        category: newCategory,
                        threadId: email.threadId,
                        attachments: email.attachments
                    )
                }
                
            } catch {
                showError(error)
            }
        }
    }
    
    func reportSpam(_ email: Email) {
        Task {
            do {
                try await backendAPIClient.reportSpam(emailId: email.id)
                
                // Update local state - move to spam category
                if let index = emails.firstIndex(where: { $0.id == email.id }) {
                    emails[index] = Email(
                        id: email.id,
                        subject: email.subject,
                        sender: email.sender,
                        recipients: email.recipients,
                        body: email.body,
                        snippet: email.snippet,
                        timestamp: email.timestamp,
                        isRead: email.isRead,
                        isImportant: email.isImportant,
                        hasAttachments: email.hasAttachments,
                        category: .spam,
                        threadId: email.threadId,
                        attachments: email.attachments
                    )
                }
                
            } catch {
                showError(error)
            }
        }
    }
    
    func moveFromAutoDeleted(_ email: Email) {
        Task {
            do {
                // Ask backend to keep future emails from this sender
                try await backendAPIClient.whitelistSender(
                    senderEmail: email.sender.email
                )
                
                // Move email back to primary category
                try await backendAPIClient.recategorizeEmail(
                    emailId: email.id,
                    newCategory: .primary
                )
                
                // Update local state
                if let index = emails.firstIndex(where: { $0.id == email.id }) {
                    emails[index] = Email(
                        id: email.id,
                        subject: email.subject,
                        sender: email.sender,
                        recipients: email.recipients,
                        body: email.body,
                        snippet: email.snippet,
                        timestamp: email.timestamp,
                        isRead: email.isRead,
                        isImportant: email.isImportant,
                        hasAttachments: email.hasAttachments,
                        category: .primary,
                        threadId: email.threadId,
                        attachments: email.attachments
                    )
                }
                
            } catch {
                showError(error)
            }
        }
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

// MARK: - Email Statistics
extension MainViewModel {
    var totalEmailCount: Int {
        emails.count
    }
    
    var unreadEmailCount: Int {
        emails.filter { !$0.isRead }.count
    }
    
    var spamEmailCount: Int {
        emails.filter { $0.category == .spam }.count
    }
    
    var autoDeletedEmailCount: Int {
        emails.filter { $0.category == .autoDeleted }.count
    }
    
    var categoryDistribution: [EmailCategory: Int] {
        Dictionary(grouping: emails, by: { $0.category })
            .mapValues { $0.count }
    }
}

// MARK: - Demo Data Loading
extension MainViewModel {
    func loadSampleData() {
        emails = Email.sampleEmails
    }
} 