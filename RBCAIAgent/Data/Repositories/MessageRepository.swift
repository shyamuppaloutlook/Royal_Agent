import Foundation
import Combine

// MARK: - Data Repositories
// Following SOLID: Repository Pattern and Dependency Inversion

protocol MessageRepositoryProtocol {
    func saveMessage(_ message: ChatMessage) async throws
    func getMessages() -> [ChatMessage]
    func getMessage(by id: String) -> ChatMessage?
    func deleteMessage(by id: String) async throws
    func clearMessages() throws
    func getMessageCount() -> Int
    func getMessages(from startDate: Date, to endDate: Date) -> [ChatMessage]
}

class InMemoryMessageRepository: MessageRepositoryProtocol, ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    private var cancellables = Set<AnyCancellable>()
    
    func saveMessage(_ message: ChatMessage) async throws {
        DispatchQueue.main.async {
            self.messages.append(message)
        }
    }
    
    func getMessages() -> [ChatMessage] {
        return messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    func getMessage(by id: String) -> ChatMessage? {
        return messages.first { $0.id == id }
    }
    
    func deleteMessage(by id: String) async throws {
        DispatchQueue.main.async {
            self.messages.removeAll { $0.id == id }
        }
    }
    
    func clearMessages() throws {
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
    }
    
    func getMessageCount() -> Int {
        return messages.count
    }
    
    func getMessages(from startDate: Date, to endDate: Date) -> [ChatMessage] {
        return messages.filter { message in
            message.timestamp >= startDate && message.timestamp <= endDate
        }.sorted { $0.timestamp < $1.timestamp }
    }
}

class CoreDataMessageRepository: MessageRepositoryProtocol {
    private let coreDataManager: CoreDataManagerProtocol
    
    init(coreDataManager: CoreDataManagerProtocol) {
        self.coreDataManager = coreDataManager
    }
    
    func saveMessage(_ message: ChatMessage) async throws {
        try await coreDataManager.save(message)
    }
    
    func getMessages() -> [ChatMessage] {
        return (try? coreDataManager.fetchAll(ChatMessage.self)) ?? []
    }
    
    func getMessage(by id: String) -> ChatMessage? {
        let request = NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? coreDataManager.fetch(request).first
    }
    
    func deleteMessage(by id: String) async throws {
        guard let message = getMessage(by: id) else { return }
        try await coreDataManager.delete(message)
    }
    
    func clearMessages() throws {
        let messages = getMessages()
        try messages.forEach { try coreDataManager.delete($0) }
    }
    
    func getMessageCount() -> Int {
        return getMessages().count
    }
    
    func getMessages(from startDate: Date, to endDate: Date) -> [ChatMessage] {
        let request = NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return (try? coreDataManager.fetch(request)) ?? []
    }
}

// MARK: - Intent Repository

protocol IntentRepositoryProtocol {
    func getIntentFromPatterns(_ message: String) async -> ChatIntent
    func getIntentPatterns(for intent: ChatIntent) -> [String]
    func addPattern(_ pattern: String, for intent: ChatIntent)
    func removePattern(_ pattern: String, for intent: ChatIntent)
}

class PatternBasedIntentRepository: IntentRepositoryProtocol {
    private var intentPatterns: [ChatIntent: [String]] = [:]
    
    init() {
        setupDefaultPatterns()
    }
    
    private func setupDefaultPatterns() {
        intentPatterns = [
            .balanceInquiry: [
                "balance", "how much", "account balance", "current balance",
                "what's my balance", "check balance", "account total"
            ],
            .spendingAnalysis: [
                "spend", "spent", "expenses", "spending", "cost",
                "how much did i spend", "my spending", "analyze spending"
            ],
            .transactionSearch: [
                "transaction", "purchase", "payment", "bought",
                "recent transactions", "show transactions", "find transaction"
            ],
            .accountInformation: [
                "account", "accounts", "account info", "account details",
                "my accounts", "account summary"
            ],
            .insightsRequest: [
                "insight", "recommend", "advice", "suggestion",
                "financial insights", "recommendations", "help me understand"
            ],
            .budgetHelp: [
                "budget", "budgeting", "save money", "budget help",
                "create budget", "budget analysis"
            ],
            .billPayment: [
                "bill", "payment", "pay", "due", "bill payment",
                "pay bills", "upcoming bills"
            ],
            .netWorth: [
                "net worth", "total", "overall", "combined",
                "my net worth", "total worth", "financial summary"
            ],
            .transferMoney: [
                "transfer", "send money", "move money", "transfer funds",
                "money transfer", "send payment"
            ],
            .investmentInfo: [
                "investment", "portfolio", "stocks", "invest",
                "investment info", "my investments"
            ],
            .helpRequest: [
                "help", "assist", "support", "how to",
                "what can you do", "capabilities"
            ],
            .greeting: [
                "hello", "hi", "hey", "good morning", "good afternoon",
                "good evening", "greetings"
            ],
            .farewell: [
                "bye", "goodbye", "see you", "farewell", "later",
                "talk to you later"
            ]
        ]
    }
    
    func getIntentFromPatterns(_ message: String) async -> ChatIntent {
        let lowercaseMessage = message.lowercased()
        
        for (intent, patterns) in intentPatterns {
            for pattern in patterns {
                if lowercaseMessage.contains(pattern) {
                    return intent
                }
            }
        }
        
        return .unknown
    }
    
    func getIntentPatterns(for intent: ChatIntent) -> [String] {
        return intentPatterns[intent] ?? []
    }
    
    func addPattern(_ pattern: String, for intent: ChatIntent) {
        if intentPatterns[intent] == nil {
            intentPatterns[intent] = []
        }
        intentPatterns[intent]?.append(pattern.lowercased())
    }
    
    func removePattern(_ pattern: String, for intent: ChatIntent) {
        intentPatterns[intent]?.removeAll { $0.lowercased() == pattern.lowercased() }
    }
}

// MARK: - Response Repository

protocol ResponseRepositoryProtocol {
    func getTemplate(for intent: ChatIntent) throws -> String
    func getAllTemplates() -> [ChatIntent: String]
    func saveTemplate(_ template: String, for intent: ChatIntent)
    func removeTemplate(for intent: ChatIntent)
}

class TemplateResponseRepository: ResponseRepositoryProtocol {
    private var responseTemplates: [ChatIntent: String] = [:]
    
    init() {
        setupDefaultTemplates()
    }
    
    private func setupDefaultTemplates() {
        responseTemplates = [
            .balanceInquiry: """
            Here's your current balance information:
            
            Total Balance: {total_balance}
            Number of Accounts: {account_count}
            
            Would you like more details about any specific account?
            """,
            
            .spendingAnalysis: """
            Your spending analysis shows:
            
            Top spending category: {top_category}
            Amount spent: {top_amount}
            Total categories: {total_categories}
            
            Would you like to see a detailed breakdown of your spending?
            """,
            
            .transactionSearch: """
            Here are your recent transactions:
            
            {transaction_list}
            
            Total transactions: {transaction_count}
            Would you like to see more details or search for specific transactions?
            """,
            
            .accountInformation: """
            Your account information:
            
            {account_list}
            
            Total accounts: {total_accounts}
            What would you like to know about your accounts?
            """,
            
            .insightsRequest: """
            Based on your financial data, I can provide insights on:
            • Spending patterns and trends
            • Savings opportunities
            • Investment recommendations
            • Budget optimization
            • Financial health score
            
            What type of insights are you interested in?
            """,
            
            .budgetHelp: """
            I can help you with budget management by:
            • Analyzing your current spending patterns
            • Setting realistic budget goals
            • Tracking your progress
            • Providing personalized recommendations
            • Identifying areas for savings
            
            What aspect of budgeting would you like help with?
            """,
            
            .billPayment: """
            I can assist with bill payments by:
            • Checking upcoming bills and due dates
            • Scheduling automatic payments
            • Setting payment reminders
            • Analyzing your payment history
            • Finding ways to optimize bill payments
            
            What would you like to do with your bills?
            """,
            
            .netWorth: """
            Your net worth calculation:
            
            Total Assets: {total_assets}
            Total Debts: {total_debts}
            Net Worth: {net_worth}
            
            This represents your overall financial position. Would you like a detailed breakdown?
            """,
            
            .transferMoney: """
            I can help you transfer money by:
            • Transferring between your accounts
            • Sending money to others
            • Setting up recurring transfers
            • Scheduling future transfers
            • Tracking transfer history
            
            Please specify the amount and destination for your transfer.
            """,
            
            .investmentInfo: """
            I can provide investment information on:
            • Your current portfolio performance
            • Market trends and analysis
            • Investment recommendations
            • Risk assessment
            • Diversification strategies
            
            What investment information would you like?
            """,
            
            .helpRequest: """
            I'm your RBC AI assistant. I can help you with:
            
            💰 Account Management
            • Check balances and account details
            • View transaction history
            • Manage account settings
            
            📊 Financial Analysis
            • Spending analysis and insights
            • Budget recommendations
            • Net worth calculation
            
            💸 Transactions & Payments
            • Money transfers
            • Bill payments
            • Transaction search
            
            📈 Investments
            • Portfolio information
            • Investment insights
            • Market data
            
            How can I assist you today?
            """,
            
            .unknown: """
            I'm here to help with your banking needs. I can assist with:
            • Account balances and transactions
            • Spending analysis and budgeting
            • Money transfers and bill payments
            • Investment information
            • Financial insights and recommendations
            
            Could you please rephrase your question or tell me more about what you need help with?
            """
        ]
    }
    
    func getTemplate(for intent: ChatIntent) throws -> String {
        guard let template = responseTemplates[intent] else {
            throw ChatError.invalidInput
        }
        return template
    }
    
    func getAllTemplates() -> [ChatIntent: String] {
        return responseTemplates
    }
    
    func saveTemplate(_ template: String, for intent: ChatIntent) {
        responseTemplates[intent] = template
    }
    
    func removeTemplate(for intent: ChatIntent) {
        responseTemplates.removeValue(forKey: intent)
    }
}

// MARK: - Context Repository

protocol ContextRepositoryProtocol {
    func saveContext(_ context: ChatContext) throws
    func getCurrentContext() throws -> ChatContext
    func clearContext() throws
    func getContext(by sessionId: String) -> ChatContext?
}

class InMemoryContextRepository: ContextRepositoryProtocol {
    private var contexts: [String: ChatContext] = [:]
    
    func saveContext(_ context: ChatContext) throws {
        contexts[context.sessionId] = context
    }
    
    func getCurrentContext() throws -> ChatContext {
        // Return the most recent context or create a new one
        let recentContext = contexts.values.max { $0.sessionStartTime < $1.sessionStartTime }
        return recentContext ?? ChatContext()
    }
    
    func clearContext() throws {
        contexts.removeAll()
    }
    
    func getContext(by sessionId: String) -> ChatContext? {
        return contexts[sessionId]
    }
}

// MARK: - Data Repository

protocol DataRepositoryProtocol {
    func getAccounts() throws -> [Account]
    func getAccount(by id: String) -> Account?
    func getRecentTransactions(limit: Int) throws -> [Transaction]
    func getSpendingByCategory() throws -> [CategorySpending]
    func getTotalBalance() throws -> Double
    func getTotalDebt() throws -> Double
}

class MockDataRepository: DataRepositoryProtocol {
    private let mockAccounts: [Account] = [
        Account(name: "Checking Account", type: .checking, balance: 2500.00),
        Account(name: "Savings Account", type: .savings, balance: 15000.00),
        Account(name: "Credit Card", type: .credit, balance: -500.00),
        Account(name: "Investment Account", type: .investment, balance: 35000.00)
    ]
    
    private let mockTransactions: [Transaction] = [
        Transaction(description: "Coffee Shop", amount: 4.50, category: .food, date: Date(), type: .debit, accountId: "1"),
        Transaction(description: "Grocery Store", amount: 125.30, category: .food, date: Date().addingTimeInterval(-86400), type: .debit, accountId: "1"),
        Transaction(description: "Gas Station", amount: 45.00, category: .transport, date: Date().addingTimeInterval(-172800), type: .debit, accountId: "1"),
        Transaction(description: "Salary Deposit", amount: 2500.00, category: .salary, date: Date().addingTimeInterval(-259200), type: .credit, accountId: "1"),
        Transaction(description: "Netflix Subscription", amount: 15.99, category: .entertainment, date: Date().addingTimeInterval(-345600), type: .debit, accountId: "1")
    ]
    
    func getAccounts() throws -> [Account] {
        return mockAccounts
    }
    
    func getAccount(by id: String) -> Account? {
        return mockAccounts.first { $0.id == id }
    }
    
    func getRecentTransactions(limit: Int) throws -> [Transaction] {
        return Array(mockTransactions.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    func getSpendingByCategory() throws -> [CategorySpending] {
        let groupedSpending = Dictionary(grouping: mockTransactions.filter { $0.type == .debit }) { $0.category }
        let totalSpending = mockTransactions.filter { $0.type == .debit }.reduce(0) { $0 + $1.amount }
        
        return groupedSpending.map { (category, transactions) in
            let amount = transactions.reduce(0) { $0 + $1.amount }
            let percentage = totalSpending > 0 ? (amount / totalSpending) * 100 : 0
            return CategorySpending(
                category: category,
                amount: amount,
                percentage: percentage,
                transactionCount: transactions.count,
                period: .monthly
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    func getTotalBalance() throws -> Double {
        let credits = mockAccounts.filter { $0.type == .checking || $0.type == .savings || $0.type == .investment }
            .reduce(0) { $0 + $1.balance }
        let debts = mockAccounts.filter { $0.type == .credit || $0.type == .loan || $0.type == .mortgage }
            .reduce(0) { $0 + $1.balance }
        return credits + debts
    }
    
    func getTotalDebt() throws -> Double {
        return mockAccounts.filter { $0.type == .credit || $0.type == .loan || $0.type == .mortgage }
            .reduce(0) { abs($0 + $1.balance) }
    }
}
