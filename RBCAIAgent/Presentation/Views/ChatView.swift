import SwiftUI

// MARK: - Presentation Views
// Following SOLID: View Layer with Single Responsibility

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var showingClearAlert = false
    
    // Dependency Injection through Factory
    init(viewModel: ChatViewModel = ChatViewModelFactory.create()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            messagesView
            inputView
        }
        .navigationTitle("RBC Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("Clear Chat", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearChat()
            }
        } message: {
            Text("This will remove all messages from the chat history. This action cannot be undone.")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("RBC AI Assistant")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Your personal banking assistant")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                showingClearAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Messages View
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.messages) { message in
                    MessageBubbleView(message: message)
                }
                
                if viewModel.isTyping {
                    TypingIndicatorView()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Input View
    
    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isTyping)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    if viewModel.isTyping {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        viewModel.sendMessage(trimmedMessage)
        messageText = ""
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userMessageView
            } else {
                assistantMessageView
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private var userMessageView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            
            HStack {
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if let intent = message.intent {
                    Text(intent.displayName)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
    }
    
    private var assistantMessageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.content)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(16)
            
            HStack {
                if let intent = message.intent {
                    Text(intent.displayName)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator View

struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            animationPhase = 0
            withAnimation {
                animationPhase = 2
            }
        }
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    
    init(viewModel: DashboardViewModel = DashboardViewModelFactory.create()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading dashboard...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    summaryCardsView
                    recentTransactionsView
                    spendingChartView
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            viewModel.refreshData()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Summary Cards
    
    private var summaryCardsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            SummaryCard(
                title: "Total Balance",
                value: String(format: "$%.2f", viewModel.totalBalance),
                icon: "dollarsign.circle",
                color: .green
            )
            
            SummaryCard(
                title: "Total Debt",
                value: String(format: "$%.2f", viewModel.totalDebt),
                icon: "creditcard",
                color: .red
            )
            
            SummaryCard(
                title: "Net Worth",
                value: String(format: "$%.2f", viewModel.netWorth),
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )
            
            SummaryCard(
                title: "Accounts",
                value: "\(viewModel.accounts.count)",
                icon: "banknote",
                color: .orange
            )
        }
    }
    
    // MARK: - Recent Transactions
    
    private var recentTransactionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to transactions view
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.recentTransactions.prefix(5)) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Spending Chart
    
    private var spendingChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.spendingByCategory.prefix(5)) { spending in
                    SpendingRowView(spending: spending)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.category.icon)
                .font(.title2)
                .foregroundColor(Color(transaction.category.color))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(transaction.category.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", abs(transaction.amount)))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type == .credit ? .green : .red)
                
                Text(formatDate(transaction.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct SpendingRowView: View {
    let spending: CategorySpending
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: spending.category.icon)
                    .font(.caption)
                    .foregroundColor(Color(spending.category.color))
                
                Text(spending.category.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "$%.2f", spending.amount))
                    .font(.body)
                    .fontWeight(.semibold)
            }
            
            ProgressView(value: spending.percentage / 100)
                .tint(Color(spending.category.color))
            
            Text(String(format: "%.1f%% of total spending", spending.percentage))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Factory Classes

class ChatViewModelFactory {
    static func create() -> ChatViewModel {
        // Create repositories
        let messageRepository = InMemoryMessageRepository()
        let intentRepository = PatternBasedIntentRepository()
        let responseRepository = TemplateResponseRepository()
        let contextRepository = InMemoryContextRepository()
        let dataRepository = MockDataRepository()
        
        // Create services
        let nlpService = AppleNLPService()
        let templateService = MustacheTemplateService()
        
        // Create use cases
        let intentRecognitionUseCase = BankingIntentRecognitionUseCase(
            intentRepository: intentRepository,
            nlpService: nlpService
        )
        
        let responseGenerationUseCase = BankingResponseGenerationUseCase(
            responseRepository: responseRepository,
            dataRepository: dataRepository,
            templateService: templateService
        )
        
        let contextManagementUseCase = ChatContextManagementUseCase(
            contextRepository: contextRepository,
            messageRepository: messageRepository
        )
        
        let chatUseCase = ChatUseCase(
            messageRepository: messageRepository,
            intentRecognitionUseCase: intentRecognitionUseCase,
            responseGenerationUseCase: responseGenerationUseCase,
            contextManagementUseCase: contextManagementUseCase
        )
        
        return ChatViewModel(chatUseCase: chatUseCase)
    }
}

class DashboardViewModelFactory {
    static func create() -> DashboardViewModel {
        // This would be implemented with proper dependency injection
        let dataRepository = MockDataRepository()
        let dashboardUseCase = MockDashboardUseCase(dataRepository: dataRepository)
        return DashboardViewModel(dashboardUseCase: dashboardUseCase)
    }
}

// MARK: - Mock Use Cases

class MockDashboardUseCase: DashboardUseCaseProtocol {
    private let dataRepository: DataRepositoryProtocol
    
    init(dataRepository: DataRepositoryProtocol) {
        self.dataRepository = dataRepository
    }
    
    func getDashboardData() async -> Result<DashboardData, ChatError> {
        do {
            let accounts = try dataRepository.getAccounts()
            let recentTransactions = try dataRepository.getRecentTransactions(limit: 10)
            let spendingByCategory = try dataRepository.getSpendingByCategory()
            let totalBalance = try dataRepository.getTotalBalance()
            let totalDebt = try dataRepository.getTotalDebt()
            let netWorth = totalBalance - totalDebt
            
            let data = DashboardData(
                accounts: accounts,
                recentTransactions: recentTransactions,
                spendingByCategory: spendingByCategory,
                totalBalance: totalBalance,
                totalDebt: totalDebt,
                netWorth: netWorth
            )
            
            return .success(data)
        } catch {
            return .failure(.dataRetrievalFailed(error))
        }
    }
}
