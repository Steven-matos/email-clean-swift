import Foundation

struct User: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let profileImageURL: String?
    let createdAt: Date
    let lastActiveAt: Date
    let subscription: Subscription
    let preferences: UserPreferences
    let statistics: UserStatistics
    
    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        profileImageURL: String? = nil,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        subscription: Subscription = .free,
        preferences: UserPreferences = UserPreferences(),
        statistics: UserStatistics = UserStatistics()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.subscription = subscription
        self.preferences = preferences
        self.statistics = statistics
    }
}

enum Subscription: String, Codable, CaseIterable {
    case free = "Free"
    case pro = "Pro"
    case enterprise = "Enterprise"
    
    var maxEmailAccounts: Int {
        switch self {
        case .free: return 2
        case .pro: return 10
        case .enterprise: return -1 // Unlimited
        }
    }
    
    var maxHistoryMonths: Int {
        switch self {
        case .free: return 3
        case .pro: return 12
        case .enterprise: return -1 // Unlimited
        }
    }
    
    var hasAdvancedAI: Bool {
        switch self {
        case .free: return false
        case .pro: return true
        case .enterprise: return true
        }
    }
    
    var hasPrioritySupport: Bool {
        switch self {
        case .free: return false
        case .pro: return true
        case .enterprise: return true
        }
    }
    
    var monthlyPrice: Double {
        switch self {
        case .free: return 0.0
        case .pro: return 9.99
        case .enterprise: return 29.99
        }
    }
}

struct UserPreferences: Codable {
    var theme: AppTheme
    var language: String
    var timeZone: String
    var emailSignature: String
    var enableAnalytics: Bool
    var enableCrashReporting: Bool
    var enableBetaFeatures: Bool
    var defaultEmailAccount: String?
    var autoArchiveOldEmails: Bool
    var showCategoryBadges: Bool
    var showUnreadCount: Bool
    var enableQuickActions: Bool
    
    init(
        theme: AppTheme = .system,
        language: String = "en",
        timeZone: String = TimeZone.current.identifier,
        emailSignature: String = "",
        enableAnalytics: Bool = true,
        enableCrashReporting: Bool = true,
        enableBetaFeatures: Bool = false,
        defaultEmailAccount: String? = nil,
        autoArchiveOldEmails: Bool = true,
        showCategoryBadges: Bool = true,
        showUnreadCount: Bool = true,
        enableQuickActions: Bool = true
    ) {
        self.theme = theme
        self.language = language
        self.timeZone = timeZone
        self.emailSignature = emailSignature
        self.enableAnalytics = enableAnalytics
        self.enableCrashReporting = enableCrashReporting
        self.enableBetaFeatures = enableBetaFeatures
        self.defaultEmailAccount = defaultEmailAccount
        self.autoArchiveOldEmails = autoArchiveOldEmails
        self.showCategoryBadges = showCategoryBadges
        self.showUnreadCount = showUnreadCount
        self.enableQuickActions = enableQuickActions
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var systemImage: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "gearshape"
        }
    }
}

struct UserStatistics: Codable {
    var totalEmailsProcessed: Int
    var emailsAutoDeleted: Int
    var emailsCategorized: Int
    var timeSavedMinutes: Int
    var spamEmailsBlocked: Int
    var averageEmailsPerDay: Double
    var mostActiveEmailAccount: String?
    var topEmailCategory: EmailCategory?
    var lastCalculatedAt: Date
    
    init(
        totalEmailsProcessed: Int = 0,
        emailsAutoDeleted: Int = 0,
        emailsCategorized: Int = 0,
        timeSavedMinutes: Int = 0,
        spamEmailsBlocked: Int = 0,
        averageEmailsPerDay: Double = 0.0,
        mostActiveEmailAccount: String? = nil,
        topEmailCategory: EmailCategory? = nil,
        lastCalculatedAt: Date = Date()
    ) {
        self.totalEmailsProcessed = totalEmailsProcessed
        self.emailsAutoDeleted = emailsAutoDeleted
        self.emailsCategorized = emailsCategorized
        self.timeSavedMinutes = timeSavedMinutes
        self.spamEmailsBlocked = spamEmailsBlocked
        self.averageEmailsPerDay = averageEmailsPerDay
        self.mostActiveEmailAccount = mostActiveEmailAccount
        self.topEmailCategory = topEmailCategory
        self.lastCalculatedAt = lastCalculatedAt
    }
    
    var timeSavedFormatted: String {
        let hours = timeSavedMinutes / 60
        let minutes = timeSavedMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var efficiencyScore: Double {
        guard totalEmailsProcessed > 0 else { return 0.0 }
        let deleteRate = Double(emailsAutoDeleted) / Double(totalEmailsProcessed)
        let spamBlockRate = Double(spamEmailsBlocked) / Double(totalEmailsProcessed)
        return (deleteRate + spamBlockRate) * 100
    }
}

// MARK: - Sample Data for Development
extension User {
    static let sampleUser = User(
        name: "John Doe",
        email: "john.doe@example.com",
        subscription: .pro,
        preferences: UserPreferences(
            theme: .system,
            emailSignature: "Sent from EmailClean\n\nBest regards,\nJohn Doe"
        ),
        statistics: UserStatistics(
            totalEmailsProcessed: 2347,
            emailsAutoDeleted: 1456,
            emailsCategorized: 2347,
            timeSavedMinutes: 182,
            spamEmailsBlocked: 89,
            averageEmailsPerDay: 47.3,
            mostActiveEmailAccount: "john.doe@gmail.com",
            topEmailCategory: .promotions
        )
    )
} 