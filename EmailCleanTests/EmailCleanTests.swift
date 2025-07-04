import XCTest
@testable import EmailClean

final class EmailCleanTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Model Tests
    
    func testEmailInitialization() throws {
        let sender = EmailSender(name: "Test Sender", email: "test@example.com")
        let email = Email(
            id: "test-1",
            subject: "Test Subject",
            sender: sender,
            body: "Test body content",
            snippet: "Test snippet",
            timestamp: Date(),
            category: .primary
        )
        
        XCTAssertEqual(email.id, "test-1")
        XCTAssertEqual(email.subject, "Test Subject")
        XCTAssertEqual(email.sender.name, "Test Sender")
        XCTAssertEqual(email.category, .primary)
        XCTAssertFalse(email.isRead)
    }
    
    func testEmailCategoryProperties() throws {
        XCTAssertEqual(EmailCategory.primary.systemImage, "envelope")
        XCTAssertEqual(EmailCategory.spam.systemImage, "exclamationmark.triangle")
        XCTAssertEqual(EmailCategory.promotions.systemImage, "megaphone")
    }
    
    func testEmailProviderOAuthScopes() throws {
        let gmailScopes = EmailProvider.gmail.oauthScopes
        XCTAssertTrue(gmailScopes.contains("https://www.googleapis.com/auth/gmail.readonly"))
        XCTAssertTrue(gmailScopes.contains("https://www.googleapis.com/auth/gmail.send"))
        
        let outlookScopes = EmailProvider.outlook.oauthScopes
        XCTAssertTrue(outlookScopes.contains("https://graph.microsoft.com/Mail.ReadWrite"))
    }
    
    // MARK: - ViewModel Tests
    
    func testMainViewModelInitialization() throws {
        let viewModel = MainViewModel()
        XCTAssertEqual(viewModel.selectedCategory, .primary)
        XCTAssertTrue(viewModel.emails.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testMainViewModelCategoryFiltering() throws {
        let viewModel = MainViewModel()
        viewModel.emails = Email.sampleEmails
        
        viewModel.selectCategory(.spam)
        let spamEmails = viewModel.filteredEmails
        XCTAssertTrue(spamEmails.allSatisfy { $0.category == .spam })
        
        viewModel.selectCategory(.primary)
        let primaryEmails = viewModel.filteredEmails
        XCTAssertTrue(primaryEmails.allSatisfy { $0.category == .primary })
    }
    
    func testMainViewModelCategoryCount() throws {
        let viewModel = MainViewModel()
        viewModel.emails = Email.sampleEmails
        
        let primaryCount = viewModel.getCategoryCount(.primary)
        let spamCount = viewModel.getCategoryCount(.spam)
        
        XCTAssertGreaterThanOrEqual(primaryCount, 0)
        XCTAssertGreaterThanOrEqual(spamCount, 0)
        
        let totalCounted = EmailCategory.allCases.reduce(0) { total, category in
            total + viewModel.getCategoryCount(category)
        }
        XCTAssertEqual(totalCounted, Email.sampleEmails.count)
    }
    
    // MARK: - Service Tests
    
    func testEmailAccountServiceInitialization() throws {
        let service = EmailAccountService()
        XCTAssertNotNil(service)
    }
    
    func testBackendAPIClientInitialization() throws {
        let apiClient = BackendAPIClient()
        XCTAssertNotNil(apiClient)
    }
    
    // MARK: - User Statistics Tests
    
    func testUserStatisticsCalculations() throws {
        let stats = UserStatistics(
            totalEmailsProcessed: 100,
            emailsAutoDeleted: 60,
            spamEmailsBlocked: 20,
            timeSavedMinutes: 120
        )
        
        XCTAssertEqual(stats.timeSavedFormatted, "2h 0m")
        XCTAssertEqual(stats.efficiencyScore, 80.0) // (60 + 20) / 100 * 100
    }
    
    func testUserStatisticsFormattedTime() throws {
        let shortStats = UserStatistics(timeSavedMinutes: 45)
        XCTAssertEqual(shortStats.timeSavedFormatted, "45m")
        
        let longStats = UserStatistics(timeSavedMinutes: 185) // 3h 5m
        XCTAssertEqual(longStats.timeSavedFormatted, "3h 5m")
    }
    
    // MARK: - Error Handling Tests
    
    func testAPIErrorDescriptions() throws {
        XCTAssertEqual(APIError.authenticationFailed.localizedDescription, "Authentication failed. Please try again.")
        XCTAssertEqual(APIError.networkError("Test").localizedDescription, "Network error: Test")
        XCTAssertEqual(APIError.serverError(500).localizedDescription, "Server error (500). Please try again later.")
    }
    
    func testKeychainErrorDescriptions() throws {
        XCTAssertEqual(KeychainError.unableToStore.localizedDescription, "Unable to store item in keychain")
        XCTAssertEqual(KeychainError.unableToLoad.localizedDescription, "Unable to load item from keychain")
        XCTAssertEqual(KeychainError.unableToDelete.localizedDescription, "Unable to delete item from keychain")
    }
    
    // MARK: - Performance Tests
    
    func testEmailFilteringPerformance() throws {
        let viewModel = MainViewModel()
        
        // Create a large dataset for performance testing
        var largeEmailSet: [Email] = []
        for i in 0..<1000 {
            let sender = EmailSender(name: "Sender \(i)", email: "sender\(i)@example.com")
            let email = Email(
                id: "email-\(i)",
                subject: "Subject \(i)",
                sender: sender,
                body: "Body content for email \(i)",
                snippet: "Snippet \(i)",
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 60)),
                category: EmailCategory.allCases.randomElement() ?? .primary
            )
            largeEmailSet.append(email)
        }
        
        viewModel.emails = largeEmailSet
        
        measure {
            // Test filtering performance
            for category in EmailCategory.allCases {
                viewModel.selectCategory(category)
                _ = viewModel.filteredEmails.count
            }
        }
    }
} 