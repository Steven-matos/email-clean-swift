import SwiftUI

/**
 * YahooAccountManagerView provides UI for managing multiple Yahoo accounts
 * Allows users to add, remove, and switch between Yahoo accounts
 */
struct YahooAccountManagerView: View {
    
    // MARK: - State Properties
    @EnvironmentObject var serviceManager: ServiceManager
    @State private var showingAddAccount = false
    @State private var selectedAccount: YahooAccount?
    @State private var showingDeleteConfirmation = false
    @State private var accountToDelete: YahooAccount?
    
    // Computed properties for easier access
    private var yahooOAuthService: YahooOAuthService {
        serviceManager.yahooOAuthService
    }
    
    private var emailStatistics: EmailStatistics {
        serviceManager.emailStatistics
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                // Accounts List
                accountsListSection
                
                // Add Account Button
                addAccountSection
                
                Spacer()
            }
            .navigationTitle("Yahoo Accounts")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await yahooOAuthService.loadStoredAccounts()
                }
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let account = accountToDelete {
                        Task {
                            try? await yahooOAuthService.removeAccount(account)
                        }
                    }
                }
            } message: {
                if let account = accountToDelete {
                    Text("Are you sure you want to remove \(account.email) from EmailClean?")
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /**
     * Header section with app branding and account count
     */
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon and Title
            VStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("EmailClean")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Manage your Yahoo accounts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Email Statistics
            if !yahooOAuthService.connectedAccounts.isEmpty {
                HStack(spacing: 20) {
                    StatCard(
                        title: "Total Emails",
                        value: "\(emailStatistics.totalEmails)",
                        icon: "envelope.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Unread",
                        value: "\(emailStatistics.unreadEmails)",
                        icon: "envelope.badge.fill",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Accounts",
                        value: "\(emailStatistics.connectedAccounts)",
                        icon: "person.2.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 24)
        .background(Color(.systemGroupedBackground))
    }
    
    /**
     * List of connected Yahoo accounts
     */
    private var accountsListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if yahooOAuthService.connectedAccounts.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(yahooOAuthService.connectedAccounts) { account in
                            YahooAccountCard(
                                account: account,
                                isSelected: selectedAccount?.id == account.id,
                                onSelect: {
                                    selectedAccount = account
                                },
                                onDelete: {
                                    accountToDelete = account
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    /**
     * Empty state when no accounts are connected
     */
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                
                VStack(spacing: 8) {
                    Text("No Yahoo Accounts Connected")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Add your first Yahoo account to get started with EmailClean")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    /**
     * Add account button section
     */
    private var addAccountSection: some View {
        VStack(spacing: 16) {
            if yahooOAuthService.isAuthenticating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Connecting to Yahoo...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            } else {
                Button(action: {
                    Task {
                        await yahooOAuthService.authenticateWithYahoo()
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Yahoo Account")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
            }
            
            if let error = yahooOAuthService.authenticationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Supporting Views

/**
 * Card view for displaying Yahoo account information
 */
struct YahooAccountCard: View {
    let account: YahooAccount
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Account Avatar
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(account.name.prefix(1)).uppercased())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // Account Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(account.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        StatusBadge(isExpired: account.isExpired)
                        Spacer()
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * Status badge showing account status
 */
struct StatusBadge: View {
    let isExpired: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isExpired ? Color.red : Color.green)
                .frame(width: 6, height: 6)
            
            Text(isExpired ? "Expired" : "Active")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isExpired ? .red : .green)
        }
    }
}

/**
 * Statistics card for displaying account metrics
 */
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
struct YahooAccountManagerView_Previews: PreviewProvider {
    static var previews: some View {
        YahooAccountManagerView()
    }
}
