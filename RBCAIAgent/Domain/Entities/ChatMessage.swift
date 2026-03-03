import Foundation

// MARK: - Domain Entities
// Following SOLID: Single Responsibility Principle

struct ChatMessage: Identifiable, Codable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let intent: ChatIntent?
    let metadata: MessageMetadata?
    
    init(
        id: String = UUID().uuidString,
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        intent: ChatIntent? = nil,
        metadata: MessageMetadata? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.intent = intent
        self.metadata = metadata
    }
}

struct MessageMetadata: Codable {
    let processingTime: TimeInterval?
    let confidence: Double?
    let source: MessageSource
    
    enum MessageSource: String, Codable {
        case text = "text"
        case voice = "voice"
        case api = "api"
    }
}

enum ChatIntent: String, CaseIterable, Codable {
    case balanceInquiry = "balance_inquiry"
    case spendingAnalysis = "spending_analysis"
    case transactionSearch = "transaction_search"
    case accountInformation = "account_information"
    case insightsRequest = "insights_request"
    case budgetHelp = "budget_help"
    case billPayment = "bill_payment"
    case netWorth = "net_worth"
    case transferMoney = "transfer_money"
    case investmentInfo = "investment_info"
    case helpRequest = "help_request"
    case greeting = "greeting"
    case farewell = "farewell"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .balanceInquiry: return "Balance Inquiry"
        case .spendingAnalysis: return "Spending Analysis"
        case .transactionSearch: return "Transaction Search"
        case .accountInformation: return "Account Information"
        case .insightsRequest: return "Insights Request"
        case .budgetHelp: return "Budget Help"
        case .billPayment: return "Bill Payment"
        case .netWorth: return "Net Worth"
        case .transferMoney: return "Transfer Money"
        case .investmentInfo: return "Investment Info"
        case .helpRequest: return "Help Request"
        case .greeting: return "Greeting"
        case .farewell: return "Farewell"
        case .unknown: return "Unknown"
        }
    }
    
    var category: IntentCategory {
        switch self {
        case .balanceInquiry, .accountInformation, .netWorth:
            return .account
        case .spendingAnalysis, .transactionSearch, .budgetHelp:
            return .financial
        case .insightsRequest, .investmentInfo:
            return .advisory
        case .billPayment, .transferMoney:
            return .transaction
        case .helpRequest, .greeting, .farewell:
            return .general
        case .unknown:
            return .general
        }
    }
    
    enum IntentCategory: String, CaseIterable {
        case account = "account"
        case financial = "financial"
        case advisory = "advisory"
        case transaction = "transaction"
        case general = "general"
    }
}

struct ChatContext: Codable {
    var sessionId: String
    var userId: String?
    var lastIntent: ChatIntent?
    var conversationHistory: [String] = []
    var userPreferences: UserPreferences
    var sessionStartTime: Date
    var lastMessageTime: Date?
    var messageCount: Int = 0
    var isActive: Bool = true
    
    init(
        sessionId: String = UUID().uuidString,
        userId: String? = nil,
        userPreferences: UserPreferences = UserPreferences()
    ) {
        self.sessionId = sessionId
        self.userId = userId
        self.userPreferences = userPreferences
        self.sessionStartTime = Date()
    }
}

struct UserPreferences: Codable {
    var preferredAccountType: String = "checking"
    var notificationEnabled: Bool = true
    var language: String = "en"
    var voiceEnabled: Bool = true
    var theme: AppTheme = .system
    var currency: String = "USD"
    var dateFormat: String = "MM/dd/yyyy"
    var timeFormat: String = "h:mm a"
    
    enum AppTheme: String, CaseIterable, Codable {
        case light = "light"
        case dark = "dark"
        case system = "system"
    }
}

struct Transaction: Identifiable, Codable {
    let id: String
    let description: String
    let amount: Double
    let category: TransactionCategory
    let date: Date
    let type: TransactionType
    let accountId: String
    let metadata: TransactionMetadata?
    
    init(
        id: String = UUID().uuidString,
        description: String,
        amount: Double,
        category: TransactionCategory,
        date: Date,
        type: TransactionType,
        accountId: String,
        metadata: TransactionMetadata? = nil
    ) {
        self.id = id
        self.description = description
        self.amount = amount
        self.category = category
        self.date = date
        self.type = type
        self.accountId = accountId
        self.metadata = metadata
    }
}

struct TransactionMetadata: Codable {
    let location: String?
    let merchant: String?
    let tags: [String]
    let isRecurring: Bool
    let confidence: Double?
}

enum TransactionType: String, CaseIterable, Codable {
    case debit = "debit"
    case credit = "credit"
    case transfer = "transfer"
    case payment = "payment"
    
    var displayName: String {
        switch self {
        case .debit: return "Debit"
        case .credit: return "Credit"
        case .transfer: return "Transfer"
        case .payment: return "Payment"
        }
    }
}

enum TransactionCategory: String, CaseIterable, Codable {
    case food = "food"
    case transport = "transport"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case bills = "bills"
    case healthcare = "healthcare"
    case education = "education"
    case salary = "salary"
    case investment = "investment"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .food: return "Food & Dining"
        case .transport: return "Transportation"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .bills: return "Bills & Utilities"
        case .healthcare: return "Healthcare"
        case .education: return "Education"
        case .salary: return "Salary & Income"
        case .investment: return "Investment"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car"
        case .shopping: return "bag"
        case .entertainment: return "tv"
        case .bills: return "doc.text"
        case .healthcare: return "cross"
        case .education: return "book"
        case .salary: return "dollarsign.circle"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "ellipsis.circle"
        }
    }
    
    var color: String {
        switch self {
        case .food: return "green"
        case .transport: return "blue"
        case .shopping: return "purple"
        case .entertainment: return "orange"
        case .bills: return "red"
        case .healthcare: return "pink"
        case .education: return "indigo"
        case .salary: return "green"
        case .investment: return "teal"
        case .other: return "gray"
        }
    }
}

struct CategorySpending: Identifiable, Codable {
    let id: String = UUID().uuidString
    let category: TransactionCategory
    let amount: Double
    let percentage: Double
    let transactionCount: Int
    let period: SpendingPeriod
    
    enum SpendingPeriod: String, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
    }
}

struct Account: Identifiable, Codable {
    let id: String
    let name: String
    let type: AccountType
    let balance: Double
    let currency: String
    let isActive: Bool
    let lastUpdated: Date
    let metadata: AccountMetadata?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        type: AccountType,
        balance: Double,
        currency: String = "USD",
        isActive: Bool = true,
        lastUpdated: Date = Date(),
        metadata: AccountMetadata? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.currency = currency
        self.isActive = isActive
        self.lastUpdated = lastUpdated
        self.metadata = metadata
    }
}

struct AccountMetadata: Codable {
    let accountNumber: String?
    let routingNumber: String?
    let bankName: String?
    let openDate: Date?
    let interestRate: Double?
    var creditLimit: Double?
    var minimumBalance: Double?
}

enum AccountType: String, CaseIterable, Codable {
    case checking = "checking"
    case savings = "savings"
    case credit = "credit"
    case investment = "investment"
    case loan = "loan"
    case mortgage = "mortgage"
    
    var displayName: String {
        switch self {
        case .checking: return "Checking Account"
        case .savings: return "Savings Account"
        case .credit: return "Credit Card"
        case .investment: return "Investment Account"
        case .loan: return "Loan Account"
        case .mortgage: return "Mortgage"
        }
    }
    
    var icon: String {
        switch self {
        case .checking: return "dollarsign.circle"
        case .savings: return "banknote"
        case .credit: return "creditcard"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .loan: return "dollarsign.square"
        case .mortgage: return "house"
        }
    }
}
