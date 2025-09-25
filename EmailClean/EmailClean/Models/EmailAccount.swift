import Foundation
import UIKit

struct EmailAccount: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let provider: EmailProvider
    let isConnected: Bool
    let lastSyncDate: Date?
    let syncStatus: SyncStatus
    let totalEmailCount: Int
    let unreadEmailCount: Int
    let autoDeletedCount: Int
    let preferences: AccountPreferences
    
    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        provider: EmailProvider,
        isConnected: Bool = false,
        lastSyncDate: Date? = nil,
        syncStatus: SyncStatus = .idle,
        totalEmailCount: Int = 0,
        unreadEmailCount: Int = 0,
        autoDeletedCount: Int = 0,
        preferences: AccountPreferences = AccountPreferences()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.provider = provider
        self.isConnected = isConnected
        self.lastSyncDate = lastSyncDate
        self.syncStatus = syncStatus
        self.totalEmailCount = totalEmailCount
        self.unreadEmailCount = unreadEmailCount
        self.autoDeletedCount = autoDeletedCount
        self.preferences = preferences
    }
}

enum EmailProvider: String, Codable, CaseIterable {
    case gmail = "Gmail"
    case yahoo = "Yahoo"
    
    // Future providers can be added here when needed
    // case outlook = "Outlook"
    // case applemail = "Apple Mail"
    // case other = "Other"
    
    var displayName: String {
        return self.rawValue
    }
    
    var systemImage: String {
        switch self {
        case .gmail:
            return "envelope.circle.fill"
        case .yahoo:
            return "envelope.badge.fill"
        }
    }
    
    var customIcon: String? {
        switch self {
        case .gmail:
            return "gmail-icon"
        case .yahoo:
            return "yahoo-icon"
        }
    }
    
    // Enhanced icon with fallback handling
    var iconImage: String {
        return customIcon ?? systemImage
    }
    
    var color: UIColor {
        switch self {
        case .gmail:
            return UIColor.systemRed
        case .yahoo:
            return UIColor.systemPurple
        }
    }
    
    var oauthScopes: [String] {
        switch self {
        case .gmail:
            return ["https://www.googleapis.com/auth/gmail.readonly",
                    "https://www.googleapis.com/auth/gmail.send",
                    "https://www.googleapis.com/auth/gmail.modify"]
        case .yahoo:
            return ["openid", "email", "profile"] // Use Yahoo's standard scopes
        }
    }
    
    var baseURL: String {
        switch self {
        case .gmail: 
            return "https://gmail.googleapis.com/gmail/v1"
        case .yahoo: 
            return "https://api.mail.yahoo.com/ws/v3"
        }
    }
    
    /// Gmail-specific category mapping
    var gmailCategories: [String] {
        switch self {
        case .gmail:
            return ["primary", "promotions", "social", "updates", "forums"]
        case .yahoo:
            return [] // Yahoo doesn't have built-in categories like Gmail
        }
    }
    
    /// Yahoo-specific folder structure
    var yahooFolders: [String] {
        switch self {
        case .yahoo:
            return ["Inbox", "Sent", "Draft", "Trash", "Spam"]
        case .gmail:
            return [] // Gmail uses labels instead of folders
        }
    }
}

enum SyncStatus: String, Codable {
    case idle = "Idle"
    case syncing = "Syncing"
    case processing = "Processing"
    case error = "Error"
    case completed = "Completed"
    
    var systemImage: String {
        switch self {
        case .idle: return "circle"
        case .syncing: return "arrow.clockwise"
        case .processing: return "gearshape"
        case .error: return "exclamationmark.triangle"
        case .completed: return "checkmark.circle"
        }
    }
}

struct AccountPreferences: Codable {
    var enableAutoDelete: Bool
    var autoDeleteCategories: [EmailCategory]
    var enableNotifications: Bool
    var notificationCategories: [EmailCategory]
    var syncFrequency: SyncFrequency
    var retentionPeriod: RetentionPeriod
    var whitelistedSenders: [String]
    var blacklistedSenders: [String]
    
    init(
        enableAutoDelete: Bool = true,
        autoDeleteCategories: [EmailCategory] = [.promotions, .spam, .deals],
        enableNotifications: Bool = true,
        notificationCategories: [EmailCategory] = [.primary, .transactions],
        syncFrequency: SyncFrequency = .fifteenMinutes,
        retentionPeriod: RetentionPeriod = .thirtyDays,
        whitelistedSenders: [String] = [],
        blacklistedSenders: [String] = []
    ) {
        self.enableAutoDelete = enableAutoDelete
        self.autoDeleteCategories = autoDeleteCategories
        self.enableNotifications = enableNotifications
        self.notificationCategories = notificationCategories
        self.syncFrequency = syncFrequency
        self.retentionPeriod = retentionPeriod
        self.whitelistedSenders = whitelistedSenders
        self.blacklistedSenders = blacklistedSenders
    }
}

enum SyncFrequency: String, Codable, CaseIterable {
    case realTime = "Real-time"
    case fiveMinutes = "5 minutes"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case oneHour = "1 hour"
    case manual = "Manual"
    
    var intervalSeconds: TimeInterval {
        switch self {
        case .realTime: return 30 // 30 seconds for real-time
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        case .thirtyMinutes: return 1800
        case .oneHour: return 3600
        case .manual: return 0
        }
    }
}

enum RetentionPeriod: String, Codable, CaseIterable {
    case sevenDays = "7 days"
    case fourteenDays = "14 days"
    case thirtyDays = "30 days"
    case ninetyDays = "90 days"
    case oneYear = "1 year"
    case forever = "Forever"
    
    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .fourteenDays: return 14
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .oneYear: return 365
        case .forever: return 0
        }
    }
}

// MARK: - Sample Data for Development
extension EmailAccount {
    static let sampleAccounts: [EmailAccount] = [
        EmailAccount(
            name: "Personal Gmail",
            email: "john.doe@gmail.com",
            provider: .gmail,
            isConnected: true,
            lastSyncDate: Date().addingTimeInterval(-300),
            syncStatus: .completed,
            totalEmailCount: 1247,
            unreadEmailCount: 23,
            autoDeletedCount: 156
        ),
        EmailAccount(
            name: "Yahoo Mail",
            email: "john.doe@yahoo.com",
            provider: .yahoo,
            isConnected: true,
            lastSyncDate: Date().addingTimeInterval(-180),
            syncStatus: .completed,
            totalEmailCount: 892,
            unreadEmailCount: 7,
            autoDeletedCount: 234
        )
    ]
}