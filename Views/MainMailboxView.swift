import SwiftUI

struct MainMailboxView: View {
    @StateObject private var viewModel = MainViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var selectedEmail: Email?
    @State private var showingAccountSettings = false
    @State private var showingEmailCompose = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter Bar
                categoryFilterBar
                
                // Email List
                emailListSection
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAccountSettings = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            viewModel.refreshEmails()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                        }
                        .disabled(viewModel.isLoading)
                        
                        Button {
                            showingEmailCompose = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.title3)
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
            HStack(spacing: 12) {
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
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
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
                            .tint(.red)
                            
                            Button {
                                viewModel.archiveEmail(email)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.markAsRead(email)
                            } label: {
                                Label(email.isRead ? "Mark Unread" : "Mark Read", 
                                      systemImage: email.isRead ? "envelope.badge" : "envelope.open")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(PlainListStyle())
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
            HStack(spacing: 6) {
                Image(systemName: category.systemImage)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white : Color.accentColor)
                        .foregroundColor(isSelected ? Color.accentColor : Color.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmailRowView: View {
    let email: Email
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Sender Avatar
                Circle()
                    .fill(Color(email.category.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(email.sender.name.prefix(1).uppercased())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(email.category.color))
                    )
                
                // Email Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(email.sender.name)
                            .font(.subheadline)
                            .fontWeight(email.isRead ? .regular : .semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(email.timestamp.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(email.subject)
                        .font(.body)
                        .fontWeight(email.isRead ? .regular : .medium)
                        .foregroundColor(email.isRead ? .secondary : .primary)
                        .lineLimit(1)
                    
                    Text(email.snippet)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Indicators
                VStack(spacing: 4) {
                    if !email.isRead {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                    }
                    
                    if email.isImportant {
                        Image(systemName: "exclamationmark")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    if email.hasAttachments {
                        Image(systemName: "paperclip")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if email.sender.isPotentialSpam {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .background(email.isRead ? Color.clear : Color.accentColor.opacity(0.05))
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading emails...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    let category: EmailCategory?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: category?.systemImage ?? "envelope")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No emails found")
                    .font(.headline)
                
                Text("Your \(category?.rawValue.lowercased() ?? "inbox") is empty or all emails have been processed.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Refresh") {
                // TODO: Implement refresh
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Placeholder views for future implementation
struct AccountSettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Account Settings")
                    .font(.title)
                Text("Coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EmailComposeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Compose Email")
                    .font(.title)
                Text("Coming soon...")
                    .foregroundColor(.secondary)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Email Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(email.subject)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("From: \(email.sender.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(email.timestamp.formatted(.dateTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Email Body
                    Text(email.body)
                        .font(.body)
                        .lineSpacing(4)
                    
                    Spacer()
                }
                .padding()
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