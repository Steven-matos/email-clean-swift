import Foundation

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
    case outlook = "Outlook"
    case icloud = "iCloud"
    case yahoo = "Yahoo"
    case other = "Other"
    
    var displayName: String {
        return rawValue
    }
    
    var systemImage: String {
        switch self {
        case .gmail: return "envelope.circle"
        case .outlook: return "envelope.circle.fill"
        case .icloud: return "icloud"
        case .yahoo: return "envelope.open"
        case .other: return "envelope.badge"
        }
    }
    
    var color: String {
        switch self {
        case .gmail: return "red"
        case .outlook: return "blue"
        case .icloud: return "cyan"
        case .yahoo: return "purple"
        case .other: return "gray"
        }
    }
    
    var oauthScopes: [String] {
        switch self {
        case .gmail:
            return ["https://www.googleapis.com/auth/gmail.readonly",
                    "https://www.googleapis.com/auth/gmail.send",
                    "https://www.googleapis.com/auth/gmail.modify"]
        case .outlook:
            return ["https://graph.microsoft.com/Mail.ReadWrite",
                    "https://graph.microsoft.com/Mail.Send",
                    "https://graph.microsoft.com/User.Read"]
        case .icloud:
            return ["mail"] // iCloud Mail API scopes
        case .yahoo:
            return ["mail-r", "mail-w"] // Yahoo Mail API scopes
        case .other:
            return []
        }
    }
    
    var baseURL: String {
        switch self {
        case .gmail: return "https://gmail.googleapis.com/gmail/v1"
        case .outlook: return "https://graph.microsoft.com/v1.0/me"
        case .icloud: return "https://p03-mailws.icloud.com"
        case .yahoo: return "https://api.mail.yahoo.com/ws/v3"
        case .other: return ""
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
            name: "Work Outlook",
            email: "j.doe@company.com",
            provider: .outlook,
            isConnected: true,
            lastSyncDate: Date().addingTimeInterval(-180),
            syncStatus: .completed,
            totalEmailCount: 892,
            unreadEmailCount: 7,
            autoDeletedCount: 234
        ),
        EmailAccount(
            name: "iCloud Mail",
            email: "john.doe@icloud.com",
            provider: .icloud,
            isConnected: false,
            syncStatus: .idle,
            totalEmailCount: 0,
            unreadEmailCount: 0,
            autoDeletedCount: 0
        )
    ]
} 