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
                // Clean flat background
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
                                .fill(Color.ultraLightGray)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "person.circle")
                                .font(.system(size: 18, weight: .medium))
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
                                    .fill(Color.ultraLightGray)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
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
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 16, weight: .medium))
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
        .overlay(
            Rectangle()
                .fill(Color.lightGray)
                .frame(height: 0.5)
                .padding(.horizontal, 20),
            alignment: .bottom
        )
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .pureWhite : .primaryBlue)
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .pureWhite : .primaryText)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.pureWhite : Color.primaryBlue)
                        .foregroundColor(isSelected ? Color.primaryBlue : Color.pureWhite)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.primaryBlue : Color.ultraLightGray)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.primaryBlue : Color.lightGray, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
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
                        .fill(Color(email.category.color).opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Text(email.sender.name.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(email.category.color))
                }
                
                // Email Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(email.sender.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(email.timestamp.formatted(.relative(presentation: .named)))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.tertiaryText)
                    }
                    
                    Text(email.subject)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primaryText)
                        .lineLimit(2)
                    
                    Text(email.snippet)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondaryText)
                        .lineLimit(2)
                }
                
                // Read/Unread indicator
                if !email.isRead {
                    Circle()
                        .fill(Color.primaryBlue)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .flatCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.primaryBlue)
            
            Text("Loading emails...")
                .font(.system(size: 16, weight: .medium))
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
                    .fill(Color.ultraLightGray)
                    .frame(width: 80, height: 80)
                
                Image(systemName: category?.systemImage ?? "envelope")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primaryBlue)
            }
            
            VStack(spacing: 16) {
                Text("No emails found")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Text("Your \(category?.rawValue.lowercased() ?? "inbox") is empty or all emails have been processed.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("Refresh") {
                // TODO: Implement refresh
            }
            .flatButton(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}



struct EmailComposeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(Color.ultraLightGray)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.primaryBlue)
                    }
                    
                    VStack(spacing: 16) {
                        Text("Compose Email")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primaryText)
                        
                        Text("Coming soon...")
                            .font(.system(size: 16, weight: .regular))
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
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primaryText)
                            
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(email.category.color).opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(email.sender.name.prefix(1).uppercased())
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(email.category.color))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("From: \(email.sender.name)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primaryText)
                                    
                                    Text(email.timestamp.formatted(.dateTime))
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondaryText)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .flatCard()
                        
                        // Email Body Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text(email.body)
                                .font(.system(size: 16, weight: .regular))
                                .lineSpacing(6)
                                .foregroundColor(.primaryText)
                        }
                        .padding(20)
                        .flatCard()
                        
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