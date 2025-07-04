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
    
    private let emailAccountService: EmailAccountServiceProtocol
    private let backendAPIClient: BackendAPIClientProtocol
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
        backendAPIClient: BackendAPIClientProtocol = BackendAPIClient()
    ) {
        self.emailAccountService = emailAccountService
        self.backendAPIClient = backendAPIClient
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
            // In a real implementation, this would fetch from the backend
            // For now, we'll use sample data with some delay to simulate network
            try await Task.sleep(for: .seconds(1))
            
            // Simulate fetching emails from backend
            let fetchedEmails = try await backendAPIClient.fetchEmails()
            
            emails = fetchedEmails
            isLoading = false
            
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