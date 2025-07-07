import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.primaryBackground, Color.lightBlue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Email Provider Selection
                    emailProviderSection
                    
                    // Terms and Privacy
                    termsSection
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.large)
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
            // App Logo/Icon
            ZStack {
                Circle()
                    .fill(Color.primaryBlue.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 56))
                    .foregroundColor(.primaryBlue)
            }
            
            VStack(spacing: 12) {
                Text("EmailClean")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("AI-Powered Email Management")
                    .font(.title3)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Text("Connect your email accounts to get started with intelligent auto-organization and spam filtering.")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 32)
    }
    
    private var emailProviderSection: some View {
        VStack(spacing: 20) {
            Text("Connect Email Account")
                .font(.headline)
                .fontWeight(.semibold)
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
        .padding(.horizontal, 8)
    }
    
    private var termsSection: some View {
        VStack(spacing: 16) {
            Text("By connecting an account, you agree to our Terms of Service and Privacy Policy. Your email passwords are never stored.")
                .font(.caption)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            HStack(spacing: 24) {
                Button("Terms of Service") {
                    // TODO: Show terms of service
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.accentText)
                
                Button("Privacy Policy") {
                    // TODO: Show privacy policy
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.accentText)
            }
        }
    }
    
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 24) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Color.primaryBlue)
                            
                            Text("Connecting to \(viewModel.selectedProvider?.displayName ?? "Email Provider")...")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryText)
                        }
                        .padding(40)
                        .background(Color.cardBackground)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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
                // Provider Icon
                ZStack {
                    Circle()
                        .fill(Color(provider.color).opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Group {
                        if let customIcon = provider.customIcon,
                           UIImage(named: customIcon) != nil {
                            Image(customIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                                .foregroundColor(Color(provider.color))
                        } else {
                            Image(systemName: provider.systemImage)
                                .font(.system(size: 18))
                                .foregroundColor(Color(provider.color))
                        }
                    }
                }
                
                // Provider Name
                Text(provider.displayName)
                    .font(.body)
                    .fontWeight(.semibold)
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
                        .foregroundColor(.secondaryText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
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