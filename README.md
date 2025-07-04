# EmailClean - AI-Powered iOS Email Client

EmailClean is an iOS email client designed to combat email overload through intelligent, AI-driven auto-deletion and categorization. The app provides users with a significantly cleaner and more manageable inbox while maintaining the familiar and intuitive user experience of a native iOS Mail app.

## 🚀 Features

### Core Email Management
- **Multiple Email Providers**: Connect Gmail, Outlook, iCloud, Yahoo, and other email accounts
- **Unified Inbox**: Manage all your emails in one centralized location
- **Standard Email Operations**: Compose, reply, forward, delete, archive, and organize emails
- **File Attachments**: View and download attachments from emails
- **Search Functionality**: Powerful search across all your emails
- **Push Notifications**: Real-time notifications for new emails

### AI-Powered Intelligence
- **Smart Categorization**: Automatically categorize emails into Primary, Promotions, Social, Newsletters, Transactions, Updates, Spam, and Deals
- **Auto-Deletion**: Intelligently move unwanted emails to a designated folder to keep your inbox clean
- **Spam Detection**: Advanced AI detection of potential scam and spoofing emails
- **Learning System**: AI learns from your preferences and corrections
- **Sender Management**: Whitelist/blacklist senders with intelligent suggestions

### Security & Privacy
- **OAuth 2.0 Authentication**: Secure authentication without storing passwords
- **Keychain Integration**: Secure token storage using iOS Keychain
- **End-to-End Encryption**: All data encrypted in transit and at rest
- **Privacy First**: No email content stored on servers, only metadata for AI processing

## 🏗️ Architecture

### Project Structure
```
EmailClean/
├── EmailCleanApp.swift          # Main app entry point
├── ContentView.swift            # Root navigation view
├── Info.plist                   # App configuration and privacy declarations
├── Views/                       # SwiftUI views
│   ├── LoginView.swift         # OAuth authentication view
│   └── MainMailboxView.swift   # Main email list view
├── ViewModels/                  # MVVM view models
│   ├── LoginViewModel.swift    # Login business logic
│   └── MainViewModel.swift     # Email management logic
├── Models/                      # Data models
│   ├── Email.swift             # Email data structure
│   ├── EmailAccount.swift      # Email account model
│   └── User.swift              # User profile model
├── Services/                    # Business logic services
│   └── EmailAccountService.swift # OAuth token management
├── BackendAPI/                  # API communication
│   └── BackendAPIClient.swift  # Backend server communication
└── Assets.xcassets/            # App icons and colors
```

### Design Patterns
- **MVVM Architecture**: Clear separation of concerns with SwiftUI
- **Protocol-Oriented Programming**: Dependency injection and testability
- **Async/Await**: Modern concurrency for API calls
- **Combine Framework**: Reactive programming for data flow
- **Repository Pattern**: Data access abstraction

### Key Components

#### Authentication Flow
1. **OAuth 2.0 Integration**: Secure authentication with email providers
2. **Token Management**: Secure storage and refresh using iOS Keychain
3. **Provider Support**: Gmail, Outlook, iCloud, Yahoo Mail APIs

#### AI Processing Pipeline
1. **Email Ingestion**: Fetch emails from connected accounts
2. **Content Analysis**: AI categorization and spam detection
3. **User Feedback Loop**: Learn from user corrections
4. **Auto-Actions**: Smart deletion and organization

#### Data Flow
1. **Local Caching**: Core Data for offline access
2. **Real-time Sync**: Background processing for new emails
3. **Conflict Resolution**: Handle concurrent modifications
4. **Privacy Protection**: Metadata-only server communication

## 🔧 Setup Instructions

### Prerequisites
- **Xcode 15.0+**
- **iOS 17.0+** deployment target
- **Swift 5.9+**
- **Apple Developer Account** (for testing on device)

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/email-clean.git
   cd email-clean
   ```

2. **Open in Xcode**
   ```bash
   open EmailClean.xcodeproj
   ```

3. **Configure Signing**
   - Select your development team in Project Settings
   - Update Bundle Identifier if needed
   - Enable required capabilities (Keychain, Background Modes)

4. **Build and Run**
   - Select target device or simulator
   - Press ⌘+R to build and run

### Configuration

#### Backend API Configuration
Update the base URL in `BackendAPIClient.swift`:
```swift
private let baseURL = "https://your-backend-api.com/v1"
```

#### OAuth Client IDs
Add your OAuth client IDs to the email provider configurations in `EmailProvider.swift`.

#### Privacy Permissions
The app includes pre-configured privacy descriptions in `Info.plist`:
- Network access for email synchronization
- Keychain access for secure token storage
- Background processing for email updates

## 🧪 Testing

### Unit Tests
Run comprehensive unit tests covering:
- Data model validation
- Business logic verification
- Service layer testing
- Error handling scenarios

```bash
# Run unit tests
⌘+U in Xcode
# Or via command line
xcodebuild test -scheme EmailClean -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Tests
Automated UI tests for:
- Login flow validation
- Email list interactions
- Navigation testing
- Accessibility compliance

### Performance Testing
- Launch time optimization
- Email filtering performance
- Memory usage monitoring
- Network efficiency testing

## 📱 SwiftUI Best Practices

### Code Organization
- **View Decomposition**: Small, focused view components
- **State Management**: `@StateObject`, `@ObservableObject`, `@Published`
- **Environment Objects**: Shared app state across views
- **Preview Providers**: Comprehensive SwiftUI previews

### UI/UX Design
- **Native iOS Feel**: Follows Apple Human Interface Guidelines
- **Dark Mode Support**: Automatic light/dark theme adaptation
- **Dynamic Type**: Accessibility font sizing support
- **VoiceOver**: Full accessibility implementation

### Performance Optimization
- **Lazy Loading**: Efficient list rendering with `LazyVStack`
- **Image Caching**: Smart attachment preview caching
- **Background Processing**: Non-blocking UI operations
- **Memory Management**: Proper cleanup of resources

## 🔐 Security Implementation

### OAuth 2.0 Flow
```swift
// Secure authentication without password storage
func performOAuthFlow(provider: EmailProvider) async throws {
    let oauthURL = try await backendAPIClient.initiateOAuthFlow(provider: provider)
    // Present web authentication session
    // Exchange authorization code for tokens
    // Store tokens securely in Keychain
}
```

### Keychain Integration
```swift
// Secure token storage
class KeychainManager {
    func save(key: String, data: Data) async throws
    func load(key: String) async throws -> Data?
    func delete(key: String) async throws
}
```

### Data Protection
- **App Transport Security**: TLS 1.2+ for all network communication
- **Certificate Pinning**: Prevent man-in-the-middle attacks
- **Data Classification**: Sensitive data protection levels
- **Biometric Authentication**: Face ID/Touch ID for app access

## 🔄 Future Enhancements

### Phase 1 (Core Functionality)
- [ ] Complete OAuth implementation for all providers
- [ ] Advanced AI categorization improvements
- [ ] Real-time email synchronization
- [ ] Enhanced search capabilities

### Phase 2 (Advanced Features)
- [ ] Smart replies and email composition
- [ ] Calendar integration for event extraction
- [ ] Contact management and suggestions
- [ ] Advanced analytics and insights

### Phase 3 (Platform Expansion)
- [ ] iPad optimization and split view
- [ ] macOS Catalyst support
- [ ] Apple Watch companion app
- [ ] Siri Shortcuts integration

### Phase 4 (Enterprise Features)
- [ ] Team collaboration features
- [ ] Advanced security controls
- [ ] Custom email rules and filters
- [ ] Integration with productivity tools

## 🤝 Contributing

### Development Guidelines
1. **Code Style**: Follow Swift best practices and SwiftLint rules
2. **Testing**: Maintain >80% test coverage for critical paths
3. **Documentation**: Document public APIs and complex logic
4. **Privacy**: Never log or store sensitive user data

### Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit pull request with detailed description

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 📞 Support

- **Documentation**: [Developer Docs](https://docs.emailclean.com)
- **Issues**: [GitHub Issues](https://github.com/your-username/email-clean/issues)
- **Email**: support@emailclean.com
- **Discord**: [EmailClean Community](https://discord.gg/emailclean)

## 🙏 Acknowledgments

- **Apple**: For iOS development tools and frameworks
- **Open Source Community**: For Swift packages and inspiration
- **Beta Testers**: For valuable feedback and testing

---

**Built with ❤️ using SwiftUI and iOS 17** 