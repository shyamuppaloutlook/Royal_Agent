import Foundation
import Combine

// MARK: - SOLID Chat Service
// This class follows SOLID principles by delegating responsibilities

class SOLIDChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var lastError: Error?
    
    private let messageProcessor: MessageProcessor
    private let chatRepository: ChatRepository
    private var cancellables = Set<AnyCancellable>()
    
    // Dependency Inversion Principle (DIP)
    // Inject dependencies rather than creating them
    init(
        messageProcessor: MessageProcessor,
        chatRepository: ChatRepository
    ) {
        self.messageProcessor = messageProcessor
        self.chatRepository = chatRepository
        
        setupBindings()
        addWelcomeMessage()
    }
    
    private func setupBindings() {
        // Interface Segregation Principle (ISP)
        // Subscribe only to what we need
        if let observableRepository = chatRepository as? ObservableObject {
            objectWillChange
                .sink { [weak observableRepository] _ in
                    observableRepository?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
        
        if let observableProcessor = messageProcessor as? ObservableObject {
            observableProcessor.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            content: generateWelcomeMessage(),
            isFromUser: false
        )
        chatRepository.saveMessage(welcomeMessage)
        updateMessages()
    }
    
    private func generateWelcomeMessage() -> String {
        return """
        Hello! I'm your RBC AI assistant. I can help you:
        
        • Track your spending and account balances
        • Find transactions and analyze patterns
        • Provide personalized insights
        • Answer questions about your finances
        • Help with budget recommendations
        
        How can I assist you today?
        """
    }
    
    func sendMessage(_ userInput: String) {
        Task {
            await processMessageAsync(userInput)
        }
    }
    
    @MainActor
    private func processMessageAsync(_ userInput: String) async {
        isTyping = true
        lastError = nil
        
        defer { isTyping = false }
        
        do {
            let response = await messageProcessor.processMessage(userInput)
            updateMessages()
        } catch {
            lastError = error
            handleProcessingError(error)
        }
    }
    
    private func updateMessages() {
        messages = chatRepository.getMessages()
    }
    
    private func handleProcessingError(_ error: Error) {
        let errorMessage = ChatMessage(
            content: "I apologize, but I encountered an error. Please try again.",
            isFromUser: false
        )
        chatRepository.saveMessage(errorMessage)
        updateMessages()
    }
    
    func clearChat() {
        chatRepository.clearMessages()
        messages = []
        addWelcomeMessage()
    }
}

// MARK: - Factory Pattern for Dependency Injection

class ChatServiceFactory {
    // Factory method to create properly configured chat service
    static func createChatService() -> SOLIDChatService {
        // Create dependencies
        let dataManager = MockRBCDataManager()
        let intentRecognizer = BankingIntentRecognizer()
        let contextManager = ChatContextManager()
        let chatRepository = InMemoryChatRepository()
        let responseTemplates = ResponseTemplates()
        let responseGenerator = BankingResponseGenerator(
            dataManager: dataManager,
            responseTemplates: responseTemplates
        )
        
        // Create message processor
        let messageProcessor = MessageProcessingService(
            intentRecognizer: intentRecognizer,
            responseGenerator: responseGenerator,
            contextManager: contextManager,
            chatRepository: chatRepository
        )
        
        // Create chat service
        return SOLIDChatService(
            messageProcessor: messageProcessor,
            chatRepository: chatRepository
        )
    }
}

// MARK: - Mock Data Manager (for testing)

class MockRBCDataManager: DataManager {
    private var mockTransactions: [Transaction] = [
        Transaction(id: "1", description: "Coffee Shop", amount: 4.50, category: "Food & Dining", date: Date(), type: .debit),
        Transaction(id: "2", description: "Grocery Store", amount: 125.30, category: "Groceries", date: Date().addingTimeInterval(-86400), type: .debit),
        Transaction(id: "3", description: "Salary Deposit", amount: 2500.00, category: "Income", date: Date().addingTimeInterval(-172800), type: .credit)
    ]
    
    func getTotalBalance() -> Double {
        let credits = mockTransactions.filter { $0.type == .credit }.reduce(0) { $0 + $1.amount }
        let debits = mockTransactions.filter { $0.type == .debit }.reduce(0) { $0 + $1.amount }
        return credits - debits
    }
    
    func getTotalDebt() -> Double {
        return 1500.00 // Mock debt
    }
    
    func getRecentTransactions(count: Int) -> [Transaction] {
        return Array(mockTransactions.sorted { $0.date > $1.date }.prefix(count))
    }
    
    func getSpendingByCategory() -> [CategorySpending] {
        let groupedSpending = Dictionary(grouping: mockTransactions.filter { $0.type == .debit }) { $0.category }
        let totalSpending = mockTransactions.filter { $0.type == .debit }.reduce(0) { $0 + $1.amount }
        
        return groupedSpending.map { (category, transactions) in
            let amount = transactions.reduce(0) { $0 + $1.amount }
            let percentage = totalSpending > 0 ? (amount / totalSpending) * 100 : 0
            return CategorySpending(category: category, amount: amount, percentage: percentage)
        }.sorted { $0.amount > $1.amount }
    }
}

// MARK: - Extension for Better Error Handling

extension MessageProcessingService {
    enum ProcessingError: LocalizedError {
        case intentRecognitionFailed
        case responseGenerationFailed
        case contextUpdateFailed
        case messageSaveFailed
        
        var errorDescription: String? {
            switch self {
            case .intentRecognitionFailed:
                return "Failed to recognize the intent of your message"
            case .responseGenerationFailed:
                return "Failed to generate a response"
            case .contextUpdateFailed:
                return "Failed to update conversation context"
            case .messageSaveFailed:
                return "Failed to save message to chat history"
            }
        }
    }
}

// MARK: - Protocol Extensions for Default Implementations

extension ChatRepository {
    func getMessageCount() -> Int {
        return getMessages().count
    }
    
    func getLastMessage() -> ChatMessage? {
        return getMessages().last
    }
}

extension IntentRecognizer {
    func isBankingRelated(_ message: String) -> Bool {
        return recognizeIntent(from: message) != .unknown
    }
}
