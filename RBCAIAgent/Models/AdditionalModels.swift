import Foundation
import SwiftUI

// MARK: - Additional Data Models for RBC AI Agent

// MARK: - Budget Management
struct Budget: Identifiable, Codable {
    let id: String
    let name: String
    let category: TransactionCategory
    let allocatedAmount: Double
    let spentAmount: Double
    let period: BudgetPeriod
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    
    var remainingAmount: Double {
        allocatedAmount - spentAmount
    }
    
    var percentageUsed: Double {
        guard allocatedAmount > 0 else { return 0 }
        return (spentAmount / allocatedAmount) * 100
    }
    
    var isOverBudget: Bool {
        spentAmount > allocatedAmount
    }
}

enum BudgetPeriod: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    
    var days: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        }
    }
}

// MARK: - Financial Goals
struct FinancialGoal: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let targetAmount: Double
    let currentAmount: Double
    let targetDate: Date
    let category: GoalCategory
    let priority: GoalPriority
    let isActive: Bool
    let createdAt: Date
    
    var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return (currentAmount / targetAmount) * 100
    }
    
    var remainingAmount: Double {
        targetAmount - currentAmount
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }
    
    var isCompleted: Bool {
        currentAmount >= targetAmount
    }
}

enum GoalCategory: String, CaseIterable, Codable {
    case emergencyFund = "Emergency Fund"
    case retirement = "Retirement"
    case vacation = "Vacation"
    case homePurchase = "Home Purchase"
    case education = "Education"
    case debtPayoff = "Debt Payoff"
    case investment = "Investment"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .emergencyFund: return "shield.checkered"
        case .retirement: return "figure.and.child.holdinghands"
        case .vacation: return "airplane"
        case .homePurchase: return "house"
        case .education: return "graduationcap"
        case .debtPayoff: return "creditcard.trianglebadge.exclamationmark"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "star"
        }
    }
    
    var color: Color {
        switch self {
        case .emergencyFund: return .green
        case .retirement: return .blue
        case .vacation: return .orange
        case .homePurchase: return .purple
        case .education: return .indigo
        case .debtPayoff: return .red
        case .investment: return .mint
        case .other: return .gray
        }
    }
}

enum GoalPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

// MARK: - Investment Portfolio
struct InvestmentPortfolio: Identifiable, Codable {
    let id: String
    let name: String
    let totalValue: Double
    let totalGain: Double
    let totalGainPercentage: Double
    let holdings: [InvestmentHolding]
    let lastUpdated: Date
    
    var isProfitable: Bool {
        totalGain > 0
    }
}

struct InvestmentHolding: Identifiable, Codable {
    let id: String
    let symbol: String
    let companyName: String
    let quantity: Int
    let averageCost: Double
    let currentPrice: Double
    let current_value: Double
    let gain: Double
    let gainPercentage: Double
    let sector: String
    let lastUpdated: Date
    
    var isProfitable: Bool {
        gain > 0
    }
}

// MARK: - Credit Score & Reports
struct CreditReport: Identifiable, Codable {
    let id: String
    let creditScore: Int
    let scoreRange: CreditScoreRange
    let lastUpdated: Date
    let factors: [CreditFactor]
    let accounts: [CreditAccount]
    let inquiries: [CreditInquiry]
    
    var scoreRating: String {
        switch creditScore {
        case 800...850: return "Excellent"
        case 740...799: return "Very Good"
        case 670...739: return "Good"
        case 580...669: return "Fair"
        case 300...579: return "Poor"
        default: return "Unknown"
        }
    }
}

enum CreditScoreRange: String, CaseIterable {
    case excellent = "800-850"
    case veryGood = "740-799"
    case good = "670-739"
    case fair = "580-669"
    case poor = "300-579"
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .veryGood: return .mint
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

struct CreditFactor: Codable {
    let name: String
    let impact: CreditImpact
    let description: String
}

enum CreditImpact: String, Codable {
    case positive = "Positive"
    case negative = "Negative"
    case neutral = "Neutral"
}

struct CreditAccount: Identifiable, Codable {
    let id: String
    let name: String
    let type: String
    let balance: Double
    let limit: Double
    let paymentStatus: PaymentStatus
    let lastPaymentDate: Date?
    let openedDate: Date
}

enum PaymentStatus: String, Codable {
    case current = "Current"
    case late = "Late"
    case delinquent = "Delinquent"
    case closed = "Closed"
}

struct CreditInquiry: Identifiable, Codable {
    let id: String
    let type: InquiryType
    let date: Date
    let company: String
}

enum InquiryType: String, Codable {
    case hard = "Hard"
    case soft = "Soft"
}

// MARK: - Bills & Recurring Payments
struct RecurringPayment: Identifiable, Codable {
    let id: String
    let name: String
    let amount: Double
    let frequency: PaymentFrequency
    let nextDueDate: Date
    let category: TransactionCategory
    let merchant: String?
    let isActive: Bool
    let autoPayEnabled: Bool
    let paymentMethod: String?
    
    var isOverdue: Bool {
        nextDueDate < Date()
    }
    
    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
    }
}

enum PaymentFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    
    var interval: TimeInterval {
        switch self {
        case .daily: return 24 * 3600
        case .weekly: return 7 * 24 * 3600
        case .biweekly: return 14 * 24 * 3600
        case .monthly: return 30 * 24 * 3600
        case .quarterly: return 90 * 24 * 3600
        case .yearly: return 365 * 24 * 3600
        }
    }
}

// MARK: - Notifications & Alerts
struct NotificationPreference: Codable {
    let id: String
    let type: NotificationType
    let isEnabled: Bool
    let channels: [NotificationChannel]
    let thresholds: [String: Double]?
}

enum NotificationType: String, CaseIterable, Codable {
    case lowBalance = "Low Balance"
    case largeTransaction = "Large Transaction"
    case billReminder = "Bill Reminder"
    case budgetAlert = "Budget Alert"
    case goalMilestone = "Goal Milestone"
    case investmentUpdate = "Investment Update"
    case creditScoreChange = "Credit Score Change"
    case unusualActivity = "Unusual Activity"
    
    var icon: String {
        switch self {
        case .lowBalance: return "exclamationmark.triangle"
        case .largeTransaction: return "dollarsign.circle"
        case .billReminder: return "bell"
        case .budgetAlert: return "chart.bar"
        case .goalMilestone: return "flag"
        case .investmentUpdate: return "chart.line.uptrend.xyaxis"
        case .creditScoreChange: return "creditcard"
        case .unusualActivity: return "eye.slash"
        }
    }
}

enum NotificationChannel: String, CaseIterable, Codable {
    case push = "Push"
    case email = "Email"
    case sms = "SMS"
    case inApp = "In-App"
}

// MARK: - User Preferences & Settings
struct UserPreferences: Codable {
    var theme: AppTheme
    var language: String
    var currency: String
    var dateFormat: String
    var biometricEnabled: Bool
    var faceIDEnabled: Bool
    var notificationsEnabled: Bool
    var locationServicesEnabled: Bool
    var dataSharingEnabled: Bool
    var marketingConsent: Bool
    
    static let `default` = UserPreferences(
        theme: .system,
        language: "en",
        currency: "CAD",
        dateFormat: "MM/dd/yyyy",
        biometricEnabled: false,
        faceIDEnabled: false,
        notificationsEnabled: true,
        locationServicesEnabled: false,
        dataSharingEnabled: false,
        marketingConsent: false
    )
}

enum AppTheme: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Security & Authentication
struct SecuritySettings: Codable {
    var requireBiometricLogin: Bool
    var sessionTimeout: TimeInterval
    var maxFailedAttempts: Int
    var lockoutDuration: TimeInterval
    var twoFactorEnabled: Bool
    var trustedDevices: [TrustedDevice]
    
    static let `default` = SecuritySettings(
        requireBiometricLogin: false,
        sessionTimeout: 300, // 5 minutes
        maxFailedAttempts: 3,
        lockoutDuration: 900, // 15 minutes
        twoFactorEnabled: false,
        trustedDevices: []
    )
}

struct TrustedDevice: Identifiable, Codable {
    let id: String
    let name: String
    let deviceType: String
    let lastUsed: Date
    let isTrusted: Bool
}

// MARK: - Analytics & Reporting
struct FinancialReport: Identifiable, Codable {
    let id: String
    let title: String
    let type: ReportType
    let generatedDate: Date
    let period: DateInterval
    let data: ReportData
    let insights: [String]
}

enum ReportType: String, CaseIterable, Codable {
    case monthlyStatement = "Monthly Statement"
    case yearlySummary = "Yearly Summary"
    case taxSummary = "Tax Summary"
    case investmentPerformance = "Investment Performance"
    case spendingAnalysis = "Spending Analysis"
    case netWorthReport = "Net Worth Report"
    
    var icon: String {
        switch self {
        case .monthlyStatement: return "doc.text"
        case .yearlySummary: return "calendar"
        case .taxSummary: return "receipt"
        case .investmentPerformance: return "chart.line.uptrend.xyaxis"
        case .spendingAnalysis: return "chart.bar"
        case .netWorthReport: return "banknote"
        }
    }
}

struct ReportData: Codable {
    let totalIncome: Double
    let totalExpenses: Double
    let netIncome: Double
    let savingsRate: Double
    let topSpendingCategories: [(category: TransactionCategory, amount: Double)]
    let accountBalances: [(accountId: String, balance: Double)]
    let goalsProgress: [(goalId: String, progress: Double)]
}
