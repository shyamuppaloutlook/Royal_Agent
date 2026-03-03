import Foundation
import Combine

// MARK: - Single Responsibility Principle (SRP)
// This service only handles message processing logic

class MessageProcessingService: MessageProcessor, ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var lastError: Error?
    
    private let intentRecognizer: IntentRecognizer
    private let responseGenerator: ResponseGenerator
    private let contextManager: ContextManager
    private let chatRepository: ChatRepository
    
    // Dependency Inversion Principle (DIP)
    // Depend on abstractions, not concretions
    init(
        intentRecognizer: IntentRecognizer,
        responseGenerator: ResponseGenerator,
        contextManager: ContextManager,
        chatRepository: ChatRepository
    ) {
        self.intentRecognizer = intentRecognizer
        self.responseGenerator = responseGenerator
        self.contextManager = contextManager
        self.chatRepository = chatRepository
    }
    
    func processMessage(_ message: String) async -> String {
        isProcessing = true
        lastError = nil
        
        defer { isProcessing = false }
        
        do {
            // Create user message
            let userMessage = ChatMessage(
                content: message,
                isFromUser: true,
                intent: intentRecognizer.recognizeIntent(from: message)
            )
            
            // Save user message
            chatRepository.saveMessage(userMessage)
            
            // Update context
            contextManager.updateContext(with: userMessage)
            
            // Generate response
            let context = contextManager.getCurrentContext()
            let response = responseGenerator.generateResponse(for: message, context: context)
            
            // Create AI message
            let aiMessage = ChatMessage(
                content: response,
                isFromUser: false,
                intent: .unknown
            )
            
            // Save AI message
            chatRepository.saveMessage(aiMessage)
            
            return response
            
        } catch {
            lastError = error
            return "I apologize, but I encountered an error while processing your message. Please try again."
        }
    }
}

// MARK: - Intent Recognition Service

class BankingIntentRecognizer: IntentRecognizer {
    private let intentPatterns: [ChatIntent: [String]]
    
    init() {
        // Open/Closed Principle (OCP)
        // Can add new intents without modifying existing code
        self.intentPatterns = [
            .balanceInquiry: ["balance", "how much", "account balance", "current balance"],
            .spendingAnalysis: ["spend", "spent", "expenses", "spending", "cost"],
            .transactionSearch: ["transaction", "purchase", "payment", "bought"],
            .accountInformation: ["account", "accounts", "account info"],
            .insightsRequest: ["insight", "recommend", "advice", "suggestion"],
            .budgetHelp: ["budget", "budgeting", "save money"],
            .billPayment: ["bill", "payment", "pay", "due"],
            .netWorth: ["net worth", "total", "overall", "combined"]
        ]
    }
    
    func recognizeIntent(from message: String) -> ChatIntent {
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
}

// MARK: - Context Management Service

class ChatContextManager: ContextManager, ObservableObject {
    @Published private(set) var currentContext: ChatContext = ChatContext()
    
    private let maxHistoryCount: Int = 10
    
    func updateContext(with message: ChatMessage) {
        currentContext.lastIntent = message.intent
        currentContext.messageCount += 1
        
        // Maintain conversation history
        currentContext.conversationHistory.append(message.content)
        if currentContext.conversationHistory.count > maxHistoryCount {
            currentContext.conversationHistory.removeFirst()
        }
    }
    
    func getCurrentContext() -> ChatContext {
        return currentContext
    }
    
    func clearContext() {
        currentContext = ChatContext()
    }
}

// MARK: - Chat Repository

class InMemoryChatRepository: ChatRepository, ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    
    func saveMessage(_ message: ChatMessage) {
        messages.append(message)
    }
    
    func getMessages() -> [ChatMessage] {
        return messages
    }
    
    func clearMessages() {
        messages.removeAll()
    }
}

// MARK: - Response Generator

class BankingResponseGenerator: ResponseGenerator {
    private let dataManager: DataManager
    private let responseTemplates: ResponseTemplates
    
    init(dataManager: DataManager, responseTemplates: ResponseTemplates = ResponseTemplates()) {
        self.dataManager = dataManager
        self.responseTemplates = responseTemplates
    }
    
    func generateResponse(for input: String, context: ChatContext) -> String {
        let intent = context.lastIntent ?? .unknown
        
        switch intent {
        case .balanceInquiry:
            return generateBalanceResponse()
        case .spendingAnalysis:
            return generateSpendingResponse()
        case .transactionSearch:
            return generateTransactionResponse(for: input)
        case .accountInformation:
            return generateAccountResponse()
        case .insightsRequest:
            return generateInsightsResponse()
        case .budgetHelp:
            return generateBudgetResponse()
        case .billPayment:
            return generateBillResponse()
        case .netWorth:
            return generateNetWorthResponse()
        case .unknown:
            return generateGeneralResponse()
        }
    }
    
    private func generateBalanceResponse() -> String {
        let totalBalance = dataManager.getTotalBalance()
        let totalDebt = dataManager.getTotalDebt()
        
        return responseTemplates.balanceResponse
            .replacingOccurrences(of: "{total_balance}", with: String(format: "$%.2f", totalBalance))
            .replacingOccurrences(of: "{total_debt}", with: String(format: "$%.2f", totalDebt))
            .replacingOccurrences(of: "{net_worth}", with: String(format: "$%.2f", totalBalance - totalDebt))
    }
    
    private func generateSpendingResponse() -> String {
        let spending = dataManager.getSpendingByCategory()
        let topCategory = spending.max { $0.amount < $1.amount }
        
        var response = responseTemplates.spendingResponse
        response = response.replacingOccurrences(of: "{top_category}", with: topCategory?.category ?? "N/A")
        response = response.replacingOccurrences(of: "{top_amount}", with: String(format: "$%.2f", topCategory?.amount ?? 0))
        
        return response
    }
    
    private func generateTransactionResponse(for input: String) -> String {
        let transactions = dataManager.getRecentTransactions(count: 5)
        
        if transactions.isEmpty {
            return "I don't see any recent transactions in your account."
        }
        
        var response = "Here are your recent transactions:\n\n"
        for transaction in transactions.prefix(3) {
            response += "• \(transaction.description): \(String(format: "$%.2f", transaction.amount))\n"
        }
        
        return response
    }
    
    private func generateAccountResponse() -> String {
        return responseTemplates.accountResponse
    }
    
    private func generateInsightsResponse() -> String {
        return responseTemplates.insightsResponse
    }
    
    private func generateBudgetResponse() -> String {
        return responseTemplates.budgetResponse
    }
    
    private func generateBillResponse() -> String {
        return responseTemplates.billResponse
    }
    
    private func generateNetWorthResponse() -> String {
        let balance = dataManager.getTotalBalance()
        let debt = dataManager.getTotalDebt()
        let netWorth = balance - debt
        
        return responseTemplates.netWorthResponse
            .replacingOccurrences(of: "{net_worth}", with: String(format: "$%.2f", netWorth))
    }
    
    private func generateGeneralResponse() -> String {
        return responseTemplates.generalResponse
    }
}

// MARK: - Response Templates

struct ResponseTemplates {
    let balanceResponse = """
    Here's your current balance information:
    
    Total Balance: {total_balance}
    Total Debt: {total_debt}
    Net Worth: {net_worth}
    
    Would you like more details about any specific account?
    """
    
    let spendingResponse = """
    Your spending analysis shows:
    
    Top spending category: {top_category}
    Amount spent: {top_amount}
    
    Would you like to see a detailed breakdown of your spending?
    """
    
    let accountResponse = """
    I can help you with account information. You can ask about:
    • Account balances
    • Transaction history
    • Account details
    • Account types
    
    What specific account information would you like?
    """
    
    let insightsResponse = """
    Based on your recent activity, I can provide insights on:
    • Spending patterns
    • Savings opportunities
    • Investment recommendations
    • Budget optimization
    
    What type of insights are you interested in?
    """
    
    let budgetResponse = """
    I can help you with budget management by:
    • Analyzing current spending
    • Setting budget goals
    • Tracking progress
    • Providing recommendations
    
    What aspect of budgeting would you like help with?
    """
    
    let billResponse = """
    I can assist with bill payments by:
    • Checking upcoming bills
    • Scheduling payments
    • Setting up reminders
    • Analyzing payment history
    
    What would you like to do with your bills?
    """
    
    let netWorthResponse = """
    Your current net worth is: {net_worth}
    
    This includes all your assets minus any debts. Would you like a detailed breakdown?
    """
    
    let generalResponse = """
    I'm your RBC AI assistant. I can help you with:
    • Account balances and transactions
    • Spending analysis and budgeting
    • Investment insights
    • Bill payments and transfers
    • Financial planning advice
    
    How can I assist you today?
    """
}
