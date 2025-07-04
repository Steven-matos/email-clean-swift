// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EmailClean",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "EmailClean",
            targets: ["EmailClean"]
        )
    ],
    dependencies: [
        // SwiftUI and Combine are built-in, but we can add third-party dependencies here
        
        // Example: For advanced networking (if needed in future)
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        
        // Example: For JSON parsing enhancements (if needed in future)
        // .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.0"),
        
        // Example: For Keychain management (already implemented natively)
        // .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "20.0.0"),
        
        // Example: For advanced logging (if needed in future)
        // .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        
        // Example: For testing utilities (if needed in future)
        // .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.15.0")
    ],
    targets: [
        .target(
            name: "EmailClean",
            dependencies: [
                // Add dependencies here when needed
                // "Alamofire",
                // "AnyCodable",
                // .product(name: "Logging", package: "swift-log"),
            ],
            path: "EmailClean",
            sources: [
                "EmailCleanApp.swift",
                "ContentView.swift",
                "Views/",
                "ViewModels/",
                "Models/",
                "Services/",
                "BackendAPI/"
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Content")
            ]
        ),
        .testTarget(
            name: "EmailCleanTests",
            dependencies: ["EmailClean"],
            path: "EmailCleanTests"
        )
    ]
)

/*
 Future Dependencies to Consider:
 
 1. Networking & API:
    - Alamofire: Advanced networking capabilities
    - URLSessionWebSocketTask: For real-time updates
 
 2. Data & Persistence:
    - Core Data: For local email caching
    - SQLite.swift: Alternative database solution
    - Realm: Object database for complex data models
 
 3. Security & Authentication:
    - CryptoKit: Advanced encryption (iOS 13+)
    - AuthenticationServices: For Sign in with Apple
 
 4. UI & User Experience:
    - Lottie: For animated onboarding
    - Charts: For email analytics visualization
 
 5. Utilities:
    - SwiftDate: Advanced date manipulation
    - PhoneNumberKit: For contact parsing
    - MessageKit: For rich email display
 
 6. Testing & Quality:
    - Quick/Nimble: BDD testing framework
    - SwiftLint: Code style enforcement
    - Snapshot Testing: UI regression testing
 
 7. Analytics & Monitoring:
    - Firebase Analytics: User behavior tracking
    - Crashlytics: Crash reporting
    - Sentry: Error monitoring
 
 8. AI & ML:
    - CreateML: On-device machine learning
    - NaturalLanguage: Text analysis and sentiment
    - Vision: For attachment content analysis
 */ 