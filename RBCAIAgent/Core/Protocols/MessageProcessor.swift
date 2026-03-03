import Foundation

// MARK: - SOLID Principles Implementation

// Single Responsibility Principle (SRP)
// Each class has only one reason to change

// Open/Closed Principle (OCP)
// Open for extension, closed for modification

// Liskov Substitution Principle (LSP)
// Subtypes must be substitutable for their base types

// Interface Segregation Principle (ISP)
// Clients should not depend on interfaces they don't use

// Dependency Inversion Principle (DIP)
// Depend on abstractions, not concretions

// MARK: - Core Protocols

protocol MessageProcessor {
    func processMessage(_ message: String) async -> String
}

protocol ResponseGenerator {
    func generateResponse(for input: String, context: ChatContext) -> String
}

protocol ChatRepository {
    func saveMessage(_ message: ChatMessage)
    func getMessages() -> [ChatMessage]
    func clearMessages()
}

protocol DataManager {
    func getTotalBalance() -> Double
    func getTotalDebt() -> Double
    func getRecentTransactions(count: Int) -> [Transaction]
    func getSpendingByCategory() -> [CategorySpending]
}

protocol IntentRecognizer {
    func recognizeIntent(from message: String) -> ChatIntent
}

protocol ContextManager {
    func updateContext(with message: ChatMessage)
    func getCurrentContext() -> ChatContext
    func clearContext()
}

// MARK: - Data Models

struct ChatMessage: Identifiable, Codable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let intent: ChatIntent?
    
    init(id: String = UUID().uuidString, content: String, isFromUser: Bool, timestamp: Date = Date(), intent: ChatIntent? = nil) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.intent = intent
    }
}

struct ChatContext {
    var lastIntent: ChatIntent?
    var conversationHistory: [String] = []
    var userPreferences: UserPreferences = UserPreferences()
    var sessionStartTime: Date = Date()
    var messageCount: Int = 0
}

struct UserPreferences {
    var preferredAccountType: String = "checking"
    var notificationEnabled: Bool = true
    var language: String = "en"
    var voiceEnabled: Bool = true
}

enum ChatIntent {
    case balanceInquiry
    case spendingAnalysis
    case transactionSearch
    case accountInformation
    case insightsRequest
    case budgetHelp
    case billPayment
    case netWorth
    case unknown
}

struct Transaction: Identifiable, Codable {
    let id: String
    let description: String
    let amount: Double
    let category: String
    let date: Date
    let type: TransactionType
}

enum TransactionType {
    case debit
    case credit
}

struct CategorySpending {
    let category: String
    let amount: Double
    let percentage: Double
}
