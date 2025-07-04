import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                headerSection
                
                // Email Provider Selection
                emailProviderSection
                
                // Terms and Privacy
                termsSection
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemBackground))
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
        VStack(spacing: 20) {
            // App Logo/Icon
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("EmailClean")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AI-Powered Email Management")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("Connect your email accounts to get started with intelligent auto-organization and spam filtering.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }
    
    private var emailProviderSection: some View {
        VStack(spacing: 16) {
            Text("Connect Email Account")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
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
    }
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            Text("By connecting an account, you agree to our Terms of Service and Privacy Policy. Your email passwords are never stored.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button("Terms of Service") {
                    // TODO: Show terms of service
                }
                .font(.caption)
                .foregroundColor(.accentColor)
                
                Button("Privacy Policy") {
                    // TODO: Show privacy policy
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
    }
    
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Connecting to \(viewModel.selectedProvider?.displayName ?? "Email Provider")...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
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
            HStack(spacing: 12) {
                Image(systemName: provider.systemImage)
                    .font(.title2)
                    .foregroundColor(Color(provider.color))
                
                Text(provider.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

#Preview {
    LoginView()
        .environmentObject(AppStateManager())
} 