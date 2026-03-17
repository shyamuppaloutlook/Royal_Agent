import Foundation
import SwiftUI

struct Account {
    let id: String
    let accountNumber: String
    let accountType: AccountType
    let balance: Double
    let currency: String
    let nickname: String?
    let isActive: Bool
    let transactions: [Transaction]
}

enum AccountType: String, CaseIterable {
    case chequing = "Chequing"
    case savings = "Savings"
    case creditCard = "Credit Card"
    case investment = "Investment"
    case tfSA = "TFSA"
    case rRSP = "RRSP"
    
    var icon: String {
        switch self {
        case .chequing: return "creditcard"
        case .savings: return "banknote"
        case .creditCard: return "creditcard.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .tfSA: return "leaf.fill"
        case .rRSP: return "piggybank.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .chequing: return .blue
        case .savings: return .green
        case .creditCard: return .red
        case .investment: return .purple
        case .tfSA: return .mint
        case .rRSP: return .orange
        }
    }
}

struct Transaction {
    let id: String
    let date: Date
    let description: String
    let amount: Double
    let category: TransactionCategory
    let merchant: String?
    let isPending: Bool
    let accountId: String
}

enum TransactionCategory: String, CaseIterable {
    case groceries = "Groceries"
    case dining = "Dining"
    case shopping = "Shopping"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case bills = "Bills"
    case healthcare = "Healthcare"
    case education = "Education"
    case transfer = "Transfer"
    case deposit = "Deposit"
    case withdrawal = "Withdrawal"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .groceries: return "cart"
        case .dining: return "fork.knife"
        case .shopping: return "bag"
        case .transportation: return "car"
        case .entertainment: return "tv"
        case .bills: return "doc.text"
        case .healthcare: return "cross.case"
        case .education: return "book"
        case .transfer: return "arrow.left.arrow.right"
        case .deposit: return "plus.circle"
        case .withdrawal: return "minus.circle"
        case .other: return "ellipsis"
        }
    }
    
    var color: Color {
        switch self {
        case .groceries: return .green
        case .dining: return .orange
        case .shopping: return .blue
        case .transportation: return .red
        case .entertainment: return .purple
        case .bills: return .gray
        case .healthcare: return .pink
        case .education: return .indigo
        case .transfer: return .cyan
        case .deposit: return .green
        case .withdrawal: return .red
        case .other: return .gray
        }
    }
}

struct UserProfile {
    let name: String
    let email: String
    let phoneNumber: String
    let memberSince: Date
    let preferredName: String?
    let privacySettings: PrivacySettings
}

struct PrivacySettings {
    var shareTransactionData: Bool = false
    var shareAccountBalances: Bool = false
    var sharePersonalInfo: Bool = false
    var allowAnalytics: Bool = true
    var dataRetentionDays: Int = 90
}

struct AccountInsight {
    let id: String
    // let type: InsightType
    let title: String
    let description: String
    let severity: InsightSeverity
    let date: Date
    let relatedAccountIds: [String]
    let actionable: Bool
}

enum InsightType: String, CaseIterable {
    case spendingPattern = "Spending Pattern"
    case unusualActivity = "Unusual Activity"
    case savingsOpportunity = "Savings Opportunity"
    case billReminder = "Bill Reminder"
    case budgetAlert = "Budget Alert"
    case investmentTip = "Investment Tip"
    case netWorthProjection = "Net Worth Projection"
    case savingsRateWarning = "Savings Rate Warning"
    case incomeVolatility = "Income Volatility"
    case spendingAnomaly = "Spending Anomaly"
    case investmentOpportunity = "Investment Opportunity"
    case cashFlowPattern = "Cash Flow Pattern"
    case accountOptimization = "Account Optimization"
    case costOptimization = "Cost Optimization"
    case interestOptimization = "Interest Optimization"
    case goalAlert = "Goal Alert"
    case goalOpportunity = "Goal Opportunity"
    case taxOptimization = "Tax Optimization"
    case riskAlert = "Risk Alert"
    case concentrationRisk = "Concentration Risk"
    case incomeRisk = "Income Risk"
    case seasonalAlert = "Seasonal Alert"
    case seasonalPreparation = "Seasonal Preparation"
    case behavioralPattern = "Behavioral Pattern"
    case personalizationOpportunity = "Personalization Opportunity"
    
    var icon: String {
        switch self {
        case .spendingPattern: return "chart.bar"
        case .unusualActivity: return "exclamationmark.triangle"
        case .savingsOpportunity: return "banknote"
        case .billReminder: return "bell"
        case .budgetAlert: return "exclamationmark.circle"
        case .investmentTip: return "chart.line.uptrend.xyaxis"
        }
    }
}

enum InsightSeverity: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case info = "Info"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .info: return .blue
        }
    }
}
