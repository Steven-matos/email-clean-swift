import SwiftUI

struct MainMailboxView: View {
    @StateObject private var viewModel = MainViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var selectedEmail: Email?
    @State private var showingAccountSettings = false
    @State private var showingEmailCompose = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category Filter Bar
                    categoryFilterBar
                    
                    // Email List
                    emailListSection
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAccountSettings = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.lightBlue)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "person.circle")
                                .font(.title3)
                                .foregroundColor(.primaryBlue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            viewModel.refreshEmails()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.lightBlue)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                                    .foregroundColor(.primaryBlue)
                            }
                        }
                        .disabled(viewModel.isLoading)
                        
                        Button {
                            showingEmailCompose = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.primaryBlue)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "square.and.pencil")
                                    .font(.title3)
                                    .foregroundColor(.pureWhite)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshEmailsAsync()
            }
            .sheet(isPresented: $showingAccountSettings) {
                AccountSettingsView()
            }
            .sheet(isPresented: $showingEmailCompose) {
                EmailComposeView()
            }
            .sheet(item: $selectedEmail) { email in
                EmailDetailView(email: email)
            }
        }
        .onAppear {
            viewModel.loadEmails()
        }
    }
    
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(EmailCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        category: category,
                        isSelected: viewModel.selectedCategory == category,
                        count: viewModel.getCategoryCount(category)
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var emailListSection: some View {
        Group {
            if viewModel.isLoading && viewModel.emails.isEmpty {
                LoadingView()
            } else if viewModel.filteredEmails.isEmpty {
                EmptyStateView(category: viewModel.selectedCategory)
            } else {
                List {
                    ForEach(viewModel.filteredEmails) { email in
                        EmailRowView(email: email) {
                            selectedEmail = email
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                viewModel.deleteEmail(email)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.error)
                            
                            Button {
                                viewModel.archiveEmail(email)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.warning)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.markAsRead(email)
                            } label: {
                                Label(email.isRead ? "Mark Unread" : "Mark Read", 
                                      systemImage: email.isRead ? "envelope.badge" : "envelope.open")
                            }
                            .tint(.primaryBlue)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.primaryBackground)
            }
        }
    }
}

struct CategoryFilterButton: View {
    let category: EmailCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.caption)
                    .foregroundColor(isSelected ? .pureWhite : .primaryBlue)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .pureWhite : .primaryText)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.pureWhite : Color.primaryBlue)
                        .foregroundColor(isSelected ? Color.primaryBlue : Color.pureWhite)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.primaryBlue : Color.lightBlue)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct EmailRowView: View {
    let email: Email
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Sender Avatar
                ZStack {
                    Circle()
                        .fill(Color(email.category.color).opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(Color(email.category.color).opacity(0.3), lineWidth: 1)
                        )
                    
                    Text(email.sender.name.prefix(1).uppercased())
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(email.category.color))
                }
                
                // Email Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(email.sender.name)
                            .font(.subheadline)
                            .fontWeight(email.isRead ? .medium : .semibold)
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        Text(email.timestamp.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Text(email.subject)
                        .font(.body)
                        .fontWeight(email.isRead ? .regular : .medium)
                        .foregroundColor(email.isRead ? .secondaryText : .primaryText)
                        .lineLimit(1)
                    
                    Text(email.snippet)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .lineLimit(2)
                }
                
                // Indicators
                VStack(spacing: 6) {
                    if !email.isRead {
                        Circle()
                            .fill(Color.primaryBlue)
                            .frame(width: 10, height: 10)
                    }
                    
                    if email.isImportant {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.warning)
                    }
                    
                    if email.hasAttachments {
                        Image(systemName: "paperclip.circle.fill")
                            .font(.caption)
                            .foregroundColor(.mediumGrey)
                    }
                    
                    if email.sender.isPotentialSpam {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.error)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(email.isRead ? Color.cardBackground : Color.lightBlue.opacity(0.3))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.primaryBlue)
            
            Text("Loading emails...")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}

struct EmptyStateView: View {
    let category: EmailCategory?
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.lightBlue)
                    .frame(width: 120, height: 120)
                
                Image(systemName: category?.systemImage ?? "envelope")
                    .font(.system(size: 48))
                    .foregroundColor(.primaryBlue)
            }
            
            VStack(spacing: 12) {
                Text("No emails found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Your \(category?.rawValue.lowercased() ?? "inbox") is empty or all emails have been processed.")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("Refresh") {
                // TODO: Implement refresh
            }
            .modernButton(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}

// Placeholder views for future implementation
struct AccountSettingsView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.lightBlue)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.primaryBlue)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Account Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryText)
                        
                        Text("Coming soon...")
                            .font(.body)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EmailComposeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.lightBlue)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 40))
                            .foregroundColor(.primaryBlue)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Compose Email")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryText)
                        
                        Text("Coming soon...")
                            .font(.body)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .navigationTitle("New Email")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EmailDetailView: View {
    let email: Email
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Email Header Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text(email.subject)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(email.category.color).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(email.sender.name.prefix(1).uppercased())
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(email.category.color))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("From: \(email.sender.name)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primaryText)
                                    
                                    Text(email.timestamp.formatted(.dateTime))
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .modernCard()
                        
                        // Email Body Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text(email.body)
                                .font(.body)
                                .lineSpacing(6)
                                .foregroundColor(.primaryText)
                        }
                        .padding(20)
                        .modernCard()
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Email")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MainMailboxView()
        .environmentObject(AppStateManager())
} 