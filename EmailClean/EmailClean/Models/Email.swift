import Foundation
import UIKit

struct Email: Identifiable, Codable {
    let id: String
    let subject: String
    let sender: EmailSender
    let recipients: [EmailRecipient]
    let body: String
    let snippet: String
    let timestamp: Date
    let isRead: Bool
    let isImportant: Bool
    let hasAttachments: Bool
    let category: EmailCategory
    let threadId: String?
    let attachments: [EmailAttachment]
    
    init(
        id: String,
        subject: String,
        sender: EmailSender,
        recipients: [EmailRecipient] = [],
        body: String,
        snippet: String,
        timestamp: Date,
        isRead: Bool = false,
        isImportant: Bool = false,
        hasAttachments: Bool = false,
        category: EmailCategory = .primary,
        threadId: String? = nil,
        attachments: [EmailAttachment] = []
    ) {
        self.id = id
        self.subject = subject
        self.sender = sender
        self.recipients = recipients
        self.body = body
        self.snippet = snippet
        self.timestamp = timestamp
        self.isRead = isRead
        self.isImportant = isImportant
        self.hasAttachments = hasAttachments
        self.category = category
        self.threadId = threadId
        self.attachments = attachments
    }
}

struct EmailSender: Codable {
    let name: String
    let email: String
    let isVerified: Bool
    let isPotentialSpam: Bool
    
    init(name: String, email: String, isVerified: Bool = false, isPotentialSpam: Bool = false) {
        self.name = name
        self.email = email
        self.isVerified = isVerified
        self.isPotentialSpam = isPotentialSpam
    }
}

struct EmailRecipient: Codable {
    let name: String
    let email: String
    let type: RecipientType
    
    enum RecipientType: String, Codable {
        case to, cc, bcc
    }
}

struct EmailAttachment: Identifiable, Codable {
    let id: String
    let name: String
    let mimeType: String
    let size: Int64
    let downloadURL: String?
    
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum EmailCategory: String, Codable, CaseIterable {
    case primary = "Primary"
    case promotions = "Promotions"
    case social = "Social"
    case newsletters = "Newsletters"
    case transactions = "Transactions"
    case updates = "Updates"
    case spam = "Spam"
    case deals = "Deals"
    case autoDeleted = "Auto-Deleted"
    
    var color: UIColor {
        switch self {
        case .primary: return UIColor.systemBlue
        case .promotions: return UIColor.systemPurple
        case .social: return UIColor.systemGreen
        case .newsletters: return UIColor.systemOrange
        case .transactions: return UIColor.systemRed
        case .updates: return UIColor.systemCyan
        case .spam: return UIColor.systemGray
        case .deals: return UIColor.systemPink
        case .autoDeleted: return UIColor.systemBrown
        }
    }
    
    var systemImage: String {
        switch self {
        case .primary: return "envelope"
        case .promotions: return "megaphone"
        case .social: return "person.3"
        case .newsletters: return "newspaper"
        case .transactions: return "creditcard"
        case .updates: return "bell"
        case .spam: return "exclamationmark.triangle"
        case .deals: return "tag"
        case .autoDeleted: return "trash"
        }
    }
}

// MARK: - Sample Data for Development
extension Email {
    static let sampleEmails: [Email] = [
        Email(
            id: "1",
            subject: "Welcome to EmailClean!",
            sender: EmailSender(name: "EmailClean Team", email: "welcome@emailclean.com"),
            body: "Thank you for joining EmailClean. We're excited to help you manage your inbox with AI-powered organization.",
            snippet: "Thank you for joining EmailClean. We're excited to help you manage your inbox...",
            timestamp: Date().addingTimeInterval(-3600),
            isRead: false,
            isImportant: true,
            category: .primary
        ),
        Email(
            id: "2",
            subject: "50% Off Everything - Limited Time!",
            sender: EmailSender(name: "Retail Store", email: "deals@retailstore.com"),
            body: "Don't miss out on our biggest sale of the year! Get 50% off everything in our store.",
            snippet: "Don't miss out on our biggest sale of the year! Get 50% off everything...",
            timestamp: Date().addingTimeInterval(-7200),
            isRead: true,
            category: .promotions
        ),
        Email(
            id: "3",
            subject: "Your friend tagged you in a photo",
            sender: EmailSender(name: "Social Network", email: "notifications@socialnetwork.com"),
            body: "John Smith tagged you in a photo from last weekend's event.",
            snippet: "John Smith tagged you in a photo from last weekend's event.",
            timestamp: Date().addingTimeInterval(-10800),
            isRead: false,
            category: .social
        ),
        Email(
            id: "4",
            subject: "Weekly Newsletter - Tech Updates",
            sender: EmailSender(name: "Tech Newsletter", email: "editor@technews.com"),
            body: "This week in tech: AI advances, new iOS features, and startup funding news.",
            snippet: "This week in tech: AI advances, new iOS features, and startup funding news.",
            timestamp: Date().addingTimeInterval(-14400),
            isRead: true,
            category: .newsletters
        ),
        Email(
            id: "5",
            subject: "URGENT: Verify Your Account",
            sender: EmailSender(name: "Security Team", email: "security@suspicious.com", isPotentialSpam: true),
            body: "Your account has been compromised. Click here to verify immediately.",
            snippet: "Your account has been compromised. Click here to verify immediately.",
            timestamp: Date().addingTimeInterval(-18000),
            isRead: false,
            category: .spam
        )
    ]
} 