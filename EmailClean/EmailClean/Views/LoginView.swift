import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean flat background
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Email Provider Selection
                        emailProviderSection
                        
                        // Test Mode Section (for development)
                        #if DEBUG
                        testModeSection
                        #endif
                        
                        // Terms and Privacy
                        termsSection
                        
                        // Bottom spacing
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .overlay(
                loadingOverlay
            )
        }
        .alert("Authentication Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            // App Logo/Icon with flat design
            ZStack {
                Circle()
                    .fill(Color.primaryBlue)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.pureWhite)
            }
            
            VStack(spacing: 12) {
                Text("EmailClean")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Text("AI-Powered Email Management")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Text("Connect your email accounts to get started with intelligent auto-organization and spam filtering.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }
    
    private var emailProviderSection: some View {
        VStack(spacing: 20) {
            Text("Connect Email Account")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(EmailProvider.allCases, id: \.self) { provider in
                    ProviderButton(
                        provider: provider,
                        isLoading: viewModel.isLoading && viewModel.selectedProvider == provider
                    ) {
                        viewModel.connectEmailAccount(provider: provider)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.cardBackground)
        .flatCard()
    }
    
    private var termsSection: some View {
        VStack(spacing: 16) {
            Text("By connecting an account, you agree to our Terms of Service and Privacy Policy. Your email passwords are never stored.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
                .lineLimit(4)
            
            HStack(spacing: 32) {
                Button("Terms of Service") {
                    // TODO: Show terms of service
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primaryBlue)
                
                Button("Privacy Policy") {
                    // TODO: Show privacy policy
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primaryBlue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.secondaryBackground)
        .flatCard()
    }
    
    #if DEBUG
    private var testModeSection: some View {
        VStack(spacing: 16) {
            Text("Test Mode")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Quick test buttons for development")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.tertiaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ForEach(EmailProvider.allCases.prefix(2), id: \.self) { provider in
                    Button {
                        viewModel.connectEmailAccount(provider: provider)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: provider.systemImage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryBlue)
                            
                            Text("Test \(provider.displayName)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryBlue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primaryBlue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.secondaryBackground)
        .flatCard()
    }
    #endif
    
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                Color.pureBlack.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 24) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color.primaryBlue)
                            
                            Text("Connecting to \(viewModel.selectedProvider?.displayName ?? "Email Provider")...")
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

struct ProviderButton: View {
    let provider: EmailProvider
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Provider Icon with flat design
                ZStack {
                    Circle()
                        .fill(Color(provider.color).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Group {
                        if let customIcon = provider.customIcon,
                           UIImage(named: customIcon) != nil {
                            Image(customIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color(provider.color))
                        } else {
                            Image(systemName: provider.systemImage)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(provider.color))
                        }
                    }
                }
                
                // Provider Name
                Text(provider.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                // Action Indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color.primaryBlue)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.mediumGray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.pureWhite)
            .flatCard()
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
}

#Preview {
    LoginView()
        .environmentObject(AppStateManager())
} 