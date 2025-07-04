import XCTest

final class EmailCleanUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testLoginViewAppears() throws {
        // Test that the login view appears when app launches
        let welcomeTitle = app.navigationBars["Welcome"]
        XCTAssertTrue(welcomeTitle.exists)
        
        let emailCleanTitle = app.staticTexts["EmailClean"]
        XCTAssertTrue(emailCleanTitle.exists)
        
        let aiPoweredSubtitle = app.staticTexts["AI-Powered Email Management"]
        XCTAssertTrue(aiPoweredSubtitle.exists)
    }
    
    func testEmailProviderButtonsExist() throws {
        // Test that email provider buttons are displayed
        let connectEmailText = app.staticTexts["Connect Email Account"]
        XCTAssertTrue(connectEmailText.exists)
        
        // Check for email provider buttons
        let gmailButton = app.buttons.containing(.staticText, identifier: "Gmail").element
        let outlookButton = app.buttons.containing(.staticText, identifier: "Outlook").element
        let icloudButton = app.buttons.containing(.staticText, identifier: "iCloud").element
        let yahooButton = app.buttons.containing(.staticText, identifier: "Yahoo").element
        
        XCTAssertTrue(gmailButton.exists)
        XCTAssertTrue(outlookButton.exists)
        XCTAssertTrue(icloudButton.exists)
        XCTAssertTrue(yahooButton.exists)
    }
    
    func testPrivacyLinksExist() throws {
        // Test that privacy policy and terms of service links exist
        let termsButton = app.buttons["Terms of Service"]
        let privacyButton = app.buttons["Privacy Policy"]
        
        XCTAssertTrue(termsButton.exists)
        XCTAssertTrue(privacyButton.exists)
    }
    
    func testEmailProviderButtonTap() throws {
        // Test tapping on Gmail provider button
        let gmailButton = app.buttons.containing(.staticText, identifier: "Gmail").element
        XCTAssertTrue(gmailButton.exists)
        
        gmailButton.tap()
        
        // Check for loading state or next screen
        // Note: In a real app, this would show OAuth flow or loading state
        // For demo purposes, we'll just verify the button was tappable
        XCTAssertTrue(gmailButton.exists)
    }
    
    func testAppIconAndBranding() throws {
        // Test that app branding elements are visible
        let appIcon = app.images.matching(identifier: "envelope.badge.shield.half.filled").element
        XCTAssertTrue(appIcon.exists)
        
        let descriptionText = app.staticTexts.containing(.staticText, identifier: "Connect your email accounts").element
        XCTAssertTrue(descriptionText.exists)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityElements() throws {
        // Test that key UI elements are accessible
        let emailCleanTitle = app.staticTexts["EmailClean"]
        XCTAssertTrue(emailCleanTitle.isHittable)
        
        let gmailButton = app.buttons.containing(.staticText, identifier: "Gmail").element
        XCTAssertTrue(gmailButton.isHittable)
        
        let termsButton = app.buttons["Terms of Service"]
        XCTAssertTrue(termsButton.isHittable)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationBarElements() throws {
        // Test navigation bar elements
        let navigationBar = app.navigationBars["Welcome"]
        XCTAssertTrue(navigationBar.exists)
        
        // In a real app, there might be additional navigation elements
        // like back buttons, menu buttons, etc.
    }
    
    // MARK: - Demo Mode Tests
    
    func testDemoModeFlow() throws {
        // This test simulates a successful authentication flow
        // In a real implementation, this would test the OAuth flow
        
        let gmailButton = app.buttons.containing(.staticText, identifier: "Gmail").element
        gmailButton.tap()
        
        // Wait for potential loading state
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            // Wait for loading to complete (with timeout)
            let loadingDisappeared = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: loadingIndicator
            )
            wait(for: [loadingDisappeared], timeout: 5.0)
        }
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testScrollPerformance() throws {
        // This test would be more relevant when we have the main email list
        // For now, it's a placeholder for future scroll performance testing
        
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            // Simulate scrolling actions
            // In the main email view, this would test list scrolling performance
            app.swipeUp()
            app.swipeDown()
        }
    }
}

// MARK: - UI Test Extensions

extension EmailCleanUITests {
    
    /// Helper method to wait for an element to appear
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0) {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        wait(for: [expectation], timeout: timeout)
    }
    
    /// Helper method to wait for an element to disappear
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5.0) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        wait(for: [expectation], timeout: timeout)
    }
    
    /// Helper method to check if running on iPad
    var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Helper method to check if running in landscape
    var isLandscape: Bool {
        return app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height
    }
} 