import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var serviceManager: ServiceManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var loginViewModel = LoginViewModel()
    @State private var showingAddAccount = false
    
    // Computed properties for easier access
    private var yahooOAuthService: YahooOAuthService {
        serviceManager.yahooOAuthService
    }
    
    private var emailStatistics: EmailStatistics {
        serviceManager.emailStatistics
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Email Statistics Section
                        emailStatisticsSection
                        
                        // Connected Accounts Section
                        connectedAccountsSection
                        
                        // Add Account Section
                        addAccountSection
                        
                        // Sign Out Section
                        signOutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryBlue)
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
            .alert("Authentication Error", isPresented: $loginViewModel.showError) {
                Button("OK") { }
            } message: {
                Text(loginViewModel.errorMessage)
            }
        }
    }
    
    private var connectedAccountsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Connected Accounts")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(yahooOAuthService.connectedAccounts.count)")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryBlue)
                    .foregroundColor(.pureWhite)
                    .cornerRadius(8)
            }
            
            if yahooOAuthService.connectedAccounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.tertiaryText)
                    
                    Text("No accounts connected")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    Text("Connect your first email account to get started")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .background(Color.cardBackground)
                .flatCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(yahooOAuthService.connectedAccounts) { account in
                        YahooAccountRow(account: account)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .flatCard()
    }
    
    private var addAccountSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Add Email Account")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
            }
            
            Button {
                showingAddAccount = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primaryBlue)
                    
                    Text("Add Account")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryBlue)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.tertiaryText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.pureWhite)
                .flatCard()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .flatCard()
    }
    
    private var signOutSection: some View {
        VStack(spacing: 16) {
            Button {
                appStateManager.signOut()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.square")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.error)
                    
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.error)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.pureWhite)
                .flatCard()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .flatCard()
    }
    
    /**
     * Email statistics section showing live data
     */
    private var emailStatisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Email Statistics")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if let lastRefresh = serviceManager.lastRefreshDate {
                    Text("Updated \(lastRefresh.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondaryText)
                }
            }
            
            if yahooOAuthService.connectedAccounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.tertiaryText)
                    
                    Text("No email data available")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondaryText)
                    
                    Text("Connect a Yahoo account to see email statistics")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Total",
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
                            title: "Spam",
                            value: "\(emailStatistics.spamEmails)",
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        )
                    }
                    
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Primary",
                            value: "\(emailStatistics.primaryEmails)",
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        StatCard(
                            title: "Promotions",
                            value: "\(emailStatistics.promotionEmails)",
                            icon: "tag.fill",
                            color: .purple
                        )
                        
                        StatCard(
                            title: "Accounts",
                            value: "\(emailStatistics.connectedAccounts)",
                            icon: "person.2.fill",
                            color: .green
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .flatCard()
    }
}

// MARK: - Add Account View
struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var loginViewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Add Email Account")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primaryText)
                    
                    Text("Connect your email accounts to get started")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    ProviderButton(
                        provider: .yahoo,
                        isLoading: loginViewModel.isLoading,
                        action: {
                            Task {
                                await loginViewModel.connectEmailAccount(provider: .yahoo)
                            }
                        }
                    )
                    
                    ProviderButton(
                        provider: .gmail,
                        isLoading: loginViewModel.isLoading,
                        action: {
                            Task {
                                await loginViewModel.connectEmailAccount(provider: .gmail)
                            }
                        }
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.primaryBackground)
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Authentication Error", isPresented: $loginViewModel.showError) {
                Button("OK") { }
            } message: {
                Text(loginViewModel.errorMessage)
            }
        }
    }
}


/**
 * Yahoo account row for settings view
 */
struct YahooAccountRow: View {
    let account: YahooAccount
    
    var body: some View {
        HStack(spacing: 16) {
            // Yahoo Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.purple)
            }
            
            // Account Info
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Text(account.email)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Status Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(account.isExpired ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                
                Text(account.isExpired ? "Expired" : "Active")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(account.isExpired ? .red : .green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.pureWhite)
        .flatCard()
    }
}

#Preview {
    AccountSettingsView()
        .environmentObject(AppStateManager())
        .environmentObject(ServiceManager.shared)
}