import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var loginViewModel = LoginViewModel()
    @State private var showingAddAccount = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
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
                
                Text("\(appStateManager.emailAccounts.count)")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryBlue)
                    .foregroundColor(.pureWhite)
                    .cornerRadius(8)
            }
            
            if appStateManager.emailAccounts.isEmpty {
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
                    ForEach(appStateManager.emailAccounts) { account in
                        ConnectedAccountRow(account: account)
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
            Text("Add Account")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                showingAddAccount = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.primaryBlue.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primaryBlue)
                    }
                    
                    Text("Connect Another Email Account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.mediumGray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.pureWhite)
                .flatCard()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .flatCard()
    }
    
    private var signOutSection: some View {
        VStack(spacing: 16) {
            Text("Account Actions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                appStateManager.signOut()
                dismiss()
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.error.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.error)
                    }
                    
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.error)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.pureWhite)
                .flatCard()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .flatCard()
    }
}

struct ConnectedAccountRow: View {
    let account: EmailAccount
    
    var body: some View {
        HStack(spacing: 16) {
            // Provider Icon
            ZStack {
                Circle()
                    .fill(Color(account.provider.color).opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Group {
                    if let customIcon = account.provider.customIcon,
                       UIImage(named: customIcon) != nil {
                        Image(customIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(account.provider.color))
                    } else {
                        Image(systemName: account.provider.systemImage)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(account.provider.color))
                    }
                }
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
                    .fill(account.isConnected ? Color.success : Color.error)
                    .frame(width: 8, height: 8)
                
                Text(account.isConnected ? "Connected" : "Disconnected")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(account.isConnected ? .success : .error)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.pureWhite)
        .flatCard()
    }
}

struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var loginViewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Email Provider Selection
                        emailProviderSection
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryBlue)
                }
            }
            .overlay(
                loadingOverlay
            )
            .alert("Authentication Error", isPresented: $loginViewModel.showError) {
                Button("OK") { }
            } message: {
                Text(loginViewModel.errorMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Connect Email Account")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primaryText)
            
            Text("Choose an email provider to connect your account")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    private var emailProviderSection: some View {
        VStack(spacing: 20) {
            Text("Select Provider")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(EmailProvider.allCases, id: \.self) { provider in
                    ProviderButton(
                        provider: provider,
                        isLoading: loginViewModel.isLoading && loginViewModel.selectedProvider == provider
                    ) {
                        loginViewModel.connectEmailAccount(provider: provider)
                        dismiss()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .flatCard()
    }
    
    private var loadingOverlay: some View {
        Group {
            if loginViewModel.isLoading {
                Color.pureBlack.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 24) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color.primaryBlue)
                            
                            Text("Connecting to \(loginViewModel.selectedProvider?.displayName ?? "Email Provider")...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                        .background(Color.cardBackground)
                        .flatCard()
                    )
            }
        }
    }
}

#Preview {
    AccountSettingsView()
        .environmentObject(AppStateManager())
} 