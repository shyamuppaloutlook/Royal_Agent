import Foundation
import SwiftUI

class RBCDataManager: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var userProfile: UserProfile = UserProfile.mock
    @Published var insights: [AccountInsight] = []
    
    // Additional data properties
    @Published var budgets: [Budget] = Budget.mockBudgets
    @Published var financialGoals: [FinancialGoal] = FinancialGoal.mockGoals
    @Published var investmentPortfolio: InvestmentPortfolio = InvestmentPortfolio.mockPortfolio
    @Published var creditReport: CreditReport = CreditReport.mockCreditReport
    @Published var recurringPayments: [RecurringPayment] = RecurringPayment.mockRecurringPayments
    @Published var notificationPreferences: [NotificationPreference] = NotificationPreference.mockPreferences
    @Published var financialReports: [FinancialReport] = FinancialReport.mockReports
    @Published var userPreferences: UserPreferences = UserPreferences.default
    @Published var securitySettings: SecuritySettings = SecuritySettings.default
    
    init() {
        loadMockData()
        generateInsights()
    }
    
    private func loadMockData() {
        accounts = Account.mockAccounts
    }
    
    private func generateInsights() {
        insights = AccountInsight.generateMockInsights(for: accounts)
    }
    
    func getTotalBalance() -> Double {
        return accounts.filter { $0.accountType != .creditCard }.reduce(0) { $0 + $1.balance }
    }
    
    func getTotalDebt() -> Double {
        return accounts.filter { $0.accountType == .creditCard }.reduce(0) { $0 + abs($1.balance) }
    }
    
    func getNetWorth() -> Double {
        return getTotalBalance() - getTotalDebt()
    }
    
    func getTransactionsForAccount(_ accountId: String) -> [Transaction] {
        return accounts.first { $0.id == accountId }?.transactions ?? []
    }
    
    func getSpendingByCategory(for period: DateInterval = DateInterval(start: Date().addingTimeInterval(-30*24*3600), end: Date())) -> [TransactionCategory: Double] {
        var spending: [TransactionCategory: Double] = [:]
        
        for account in accounts {
            for transaction in account.transactions {
                if period.contains(transaction.date) && transaction.amount < 0 {
                    spending[transaction.category, default: 0] += abs(transaction.amount)
                }
            }
        }
        
        return spending
    }
    
    func getMonthlySpendingTrend() -> [(month: String, amount: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var trend: [(month: String, amount: Double)] = []
        
        for i in 0..<6 {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: now),
                  let monthEnd = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: -i+1, to: now) ?? now) else {
                continue
            }
            
            let monthInterval = DateInterval(start: monthStart, end: monthEnd)
            let monthSpending = accounts.flatMap { $0.transactions }
                .filter { monthInterval.contains($0.date) && $0.amount < 0 }
                .reduce(0) { $0 + abs($1.amount) }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            trend.insert((month: formatter.string(from: monthStart), amount: monthSpending), at: 0)
        }
        
        return trend
    }
    
    func getUpcomingBills() -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) ?? now
        
        return accounts.flatMap { $0.transactions }
            .filter { transaction in
                transaction.category == .bills &&
                transaction.amount < 0 &&
                calendar.isDate(transaction.date, inSameDayAs: now) ||
                (transaction.date > now && transaction.date <= nextMonth)
            }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - Budget Methods
    
    func getBudgetStatus(for budgetId: String) -> BudgetStatus {
        guard let budget = budgets.first(where: { $0.id == budgetId }) else {
            return .unknown
        }
        
        if budget.isOverBudget {
            return .overBudget
        } else if budget.percentageUsed >= 0.8 {
            return .warning
        } else {
            return .onTrack
        }
    }
    
    func getTotalBudgetUsage() -> Double {
        let totalAllocated = budgets.reduce(0) { $0 + $1.allocatedAmount }
        let totalSpent = budgets.reduce(0) { $0 + $1.spentAmount }
        guard totalAllocated > 0 else { return 0 }
        return (totalSpent / totalAllocated) * 100
    }
    
    // MARK: - Goals Methods
    
    func getGoalsProgress() -> [String: Double] {
        return Dictionary(uniqueKeysWithValues: financialGoals.map { ($0.id, $0.progressPercentage) })
    }
    
    func getCompletedGoals() -> [FinancialGoal] {
        return financialGoals.filter { $0.isCompleted }
    }
    
    func getUrgentGoals() -> [FinancialGoal] {
        return financialGoals.filter { $0.priority == .urgent && !$0.isCompleted }
    }
    
    // MARK: - Investment Methods
    
    func getTotalInvestmentValue() -> Double {
        return investmentPortfolio.totalValue
    }
    
    func getInvestmentGain() -> Double {
        return investmentPortfolio.totalGain
    }
    
    func getInvestmentGainPercentage() -> Double {
        return investmentPortfolio.totalGainPercentage
    }
    
    func getTopPerformingHoldings(limit: Int = 3) -> [InvestmentHolding] {
        return investmentPortfolio.holdings
            .sorted { $0.gainPercentage > $1.gainPercentage }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Credit Methods
    
    func getCreditScoreRating() -> String {
        return creditReport.scoreRating
    }
    
    func getCreditScoreColor() -> Color {
        return creditReport.scoreRange.color
    }
    
    func getOverduePayments() -> [RecurringPayment] {
        return recurringPayments.filter { $0.isOverdue }
    }
    
    func getUpcomingPayments(days: Int = 7) -> [RecurringPayment] {
        let futureDate = Date().addingTimeInterval(TimeInterval(days * 24 * 3600))
        return recurringPayments.filter { 
            $0.nextDueDate <= futureDate && $0.nextDueDate >= Date() 
        }
    }
    
    // MARK: - Notification Methods
    
    func updateNotificationPreference(type: NotificationType, isEnabled: Bool) {
        if let index = notificationPreferences.firstIndex(where: { $0.type == type }) {
            notificationPreferences[index].isEnabled = isEnabled
        }
    }
    
    func getEnabledNotificationTypes() -> [NotificationType] {
        return notificationPreferences.filter { $0.isEnabled }.map { $0.type }
    }
    
    // MARK: - Report Methods
    
    func generateMonthlyReport() -> FinancialReport {
        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let monthTransactions = accounts.flatMap { $0.transactions }
            .filter { $0.date >= startOfMonth && $0.date <= endOfMonth }
        
        let totalIncome = monthTransactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        let totalExpenses = abs(monthTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount })
        let netIncome = totalIncome - totalExpenses
        let savingsRate = totalIncome > 0 ? (netIncome / totalIncome) * 100 : 0
        
        let spendingByCategory = getSpendingByCategory(for: DateInterval(start: startOfMonth, end: endOfMonth))
        let topSpendingCategories = spendingByCategory.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { ($0.0, $0.1) }
        
        let reportData = ReportData(
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netIncome: netIncome,
            savingsRate: savingsRate,
            topSpendingCategories: topSpendingCategories,
            accountBalances: accounts.map { ($0.id, $0.balance) },
            goalsProgress: getGoalsProgress()
        )
        
        return FinancialReport(
            id: UUID().uuidString,
            title: "Monthly Statement - \(DateFormatter.monthYear.string(from: now))",
            type: .monthlyStatement,
            generatedDate: now,
            period: DateInterval(start: startOfMonth, end: endOfMonth),
            data: reportData,
            insights: generateMonthlyInsights(spendingByCategory: spendingByCategory, savingsRate: savingsRate)
        )
    }
    
    private func generateMonthlyInsights(spendingByCategory: [TransactionCategory: Double], savingsRate: Double) -> [String] {
        var insights: [String] = []
        
        if savingsRate < 10 {
            insights.append("Your savings rate is \(String(format: "%.1f", savingsRate))%. Consider reducing expenses to save more.")
        } else if savingsRate > 20 {
            insights.append("Great job! You saved \(String(format: "%.1f", savingsRate))% of your income this month.")
        }
        
        if let topCategory = spendingByCategory.max(by: { $0.value < $1.value }) {
            insights.append("Your highest expense category was \(topCategory.key.rawValue) at $\(String(format: "%.2f", topCategory.value)).")
        }
        
        let overduePayments = getOverduePayments()
        if !overduePayments.isEmpty {
            insights.append("You have \(overduePayments.count) overdue payments. Please address them promptly.")
        }
        
        return insights
    }
    
    // MARK: - User Preferences Methods
    
    func updateUserPreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
    }
    
    func updateSecuritySettings(_ settings: SecuritySettings) {
        securitySettings = settings
    }
    
    // MARK: - Data Validation
    
    func validateAllData() -> DataValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Validate account balances
        for account in accounts {
            if account.balance < -AccountType.creditLimit(for: account.accountType) {
                errors.append("Account \(account.nickname ?? account.accountNumber) is over limit")
            }
        }
        
        // Validate budgets
        for budget in budgets {
            if budget.isOverBudget {
                warnings.append("Budget '\(budget.name)' is over limit by $\(String(format: "%.2f", budget.spentAmount - budget.allocatedAmount))")
            }
        }
        
        // Validate goals
        for goal in financialGoals {
            if goal.targetDate < Date() && !goal.isCompleted {
                warnings.append("Goal '\(goal.name)' has passed its target date")
            }
        }
        
        return DataValidationResult(errors: errors, warnings: warnings, isValid: errors.isEmpty)
    }
}

// MARK: - Supporting Enums and Extensions

enum BudgetStatus {
    case onTrack
    case warning
    case overBudget
    case unknown
}

extension AccountType {
    func creditLimit(for type: AccountType) -> Double {
        switch type {
        case .creditCard: return 10000.00
        case .chequing: return 0.0
        case .savings: return 0.0
        case .investment: return 0.0
        case .tfSA: return 0.0
        case .rRSP: return 0.0
        }
    }
}

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

struct DataValidationResult {
    let errors: [String]
    let warnings: [String]
    let isValid: Bool
}
}

// MARK: - Mock Data Extensions

extension UserProfile {
    static let mock = UserProfile(
        name: "Alex Johnson",
        email: "alex.johnson@email.com",
        phoneNumber: "+1-416-555-0123",
        memberSince: Date(timeIntervalSince1970: 1470000000),
        preferredName: "Alex",
        privacySettings: PrivacySettings()
    )
}

extension Account {
    static let mockAccounts: [Account] = [
        Account(
            id: "acc1",
            accountNumber: "****1234",
            accountType: .chequing,
            balance: 3456.78,
            currency: "CAD",
            nickname: "Main Chequing",
            isActive: true,
            transactions: Transaction.mockChequingTransactions
        ),
        Account(
            id: "acc2",
            accountNumber: "****5678",
            accountType: .savings,
            balance: 12500.00,
            currency: "CAD",
            nickname: "Emergency Fund",
            isActive: true,
            transactions: Transaction.mockSavingsTransactions
        ),
        Account(
            id: "acc3",
            accountNumber: "****9012",
            accountType: .creditCard,
            balance: -1234.56,
            currency: "CAD",
            nickname: "RBC Rewards Visa",
            isActive: true,
            transactions: Transaction.mockCreditCardTransactions
        ),
        Account(
            id: "acc4",
            accountNumber: "****3456",
            accountType: .tfSA,
            balance: 8900.12,
            currency: "CAD",
            nickname: "Tax-Free Savings",
            isActive: true,
            transactions: Transaction.mockTFSATransactions
        )
    ]
}

extension Transaction {
    static let mockChequingTransactions: [Transaction] = [
        Transaction(id: "t1", date: Date().addingTimeInterval(-1*24*3600), description: "Coffee Shop", amount: -5.67, category: .dining, merchant: "Starbucks", isPending: false, accountId: "acc1"),
        Transaction(id: "t2", date: Date().addingTimeInterval(-2*24*3600), description: "Grocery Store", amount: -123.45, category: .groceries, merchant: "Loblaws", isPending: false, accountId: "acc1"),
        Transaction(id: "t3", date: Date().addingTimeInterval(-3*24*3600), description: "Salary Deposit", amount: 3500.00, category: .deposit, merchant: nil, isPending: false, accountId: "acc1"),
        Transaction(id: "t4", date: Date().addingTimeInterval(-5*24*3600), description: "Gas Station", amount: -65.00, category: .transportation, merchant: "Petro Canada", isPending: false, accountId: "acc1"),
        Transaction(id: "t5", date: Date().addingTimeInterval(-7*24*3600), description: "Netflix Subscription", amount: -15.99, category: .entertainment, merchant: "Netflix", isPending: false, accountId: "acc1"),
        Transaction(id: "t13", date: Date().addingTimeInterval(-10*24*3600), description: "Hydro Bill", amount: -145.00, category: .bills, merchant: "Hydro One", isPending: false, accountId: "acc1"),
        Transaction(id: "t14", date: Date().addingTimeInterval(-15*24*3600), description: "Phone Bill", amount: -75.00, category: .bills, merchant: "Rogers", isPending: false, accountId: "acc1")
    ]
    
    static let mockSavingsTransactions: [Transaction] = [
        Transaction(id: "t6", date: Date().addingTimeInterval(-15*24*3600), description: "Transfer from Chequing", amount: 500.00, category: .transfer, merchant: nil, isPending: false, accountId: "acc2"),
        Transaction(id: "t7", date: Date().addingTimeInterval(-30*24*3600), description: "Interest Payment", amount: 12.34, category: .deposit, merchant: nil, isPending: false, accountId: "acc2")
    ]
    
    static let mockCreditCardTransactions: [Transaction] = [
        Transaction(id: "t8", date: Date().addingTimeInterval(-1*24*3600), description: "Amazon Purchase", amount: -89.99, category: .shopping, merchant: "Amazon", isPending: true, accountId: "acc3"),
        Transaction(id: "t9", date: Date().addingTimeInterval(-3*24*3600), description: "Restaurant", amount: -67.50, category: .dining, merchant: "The Keg", isPending: false, accountId: "acc3"),
        Transaction(id: "t10", date: Date().addingTimeInterval(-10*24*3600), description: "Uber Ride", amount: -23.45, category: .transportation, merchant: "Uber", isPending: false, accountId: "acc3"),
        Transaction(id: "t15", date: Date().addingTimeInterval(-20*24*3600), description: "Walmart", amount: -156.78, category: .shopping, merchant: "Walmart", isPending: false, accountId: "acc3")
    ]
    
    static let mockTFSATransactions: [Transaction] = [
        Transaction(id: "t11", date: Date().addingTimeInterval(-20*24*3600), description: "Investment Contribution", amount: 1000.00, category: .deposit, merchant: nil, isPending: false, accountId: "acc4"),
        Transaction(id: "t12", date: Date().addingTimeInterval(-45*24*3600), description: "Investment Gain", amount: 156.78, category: .deposit, merchant: nil, isPending: false, accountId: "acc4")
    ]
}

extension AccountInsight {
    static func generateMockInsights(for accounts: [Account]) -> [AccountInsight] {
        return [
            AccountInsight(
                id: "insight1",
                type: .spendingPattern,
                title: "Dining expenses increased by 25%",
                description: "Your dining expenses this month are 25% higher than your average. Consider setting a budget for restaurants.",
                severity: .medium,
                date: Date().addingTimeInterval(-2*24*3600),
                relatedAccountIds: ["acc1", "acc3"],
                actionable: true
            ),
            AccountInsight(
                id: "insight2",
                type: .savingsOpportunity,
                title: "Save $50/month on subscriptions",
                description: "You have 3 active subscriptions totaling $45/month. Review if you still use all of them.",
                severity: .low,
                date: Date().addingTimeInterval(-5*24*3600),
                relatedAccountIds: ["acc3"],
                actionable: true
            ),
            AccountInsight(
                id: "insight3",
                type: .billReminder,
                title: "Credit card payment due in 3 days",
                description: "Your RBC Rewards Visa payment of $1,234.56 is due on March 1st.",
                severity: .high,
                date: Date().addingTimeInterval(-1*24*3600),
                relatedAccountIds: ["acc3"],
                actionable: true
            ),
            AccountInsight(
                id: "insight4",
                type: .unusualActivity,
                title: "Large purchase detected",
                description: "A purchase of $89.99 at Amazon is higher than your typical shopping expenses.",
                severity: .info,
                date: Date().addingTimeInterval(-1*24*3600),
                relatedAccountIds: ["acc3"],
                actionable: false
            ),
            AccountInsight(
                id: "insight5",
                type: .budgetAlert,
                title: "Grocery budget nearly exceeded",
                description: "You've spent 85% of your monthly grocery budget with 10 days left in the month.",
                severity: .medium,
                date: Date().addingTimeInterval(-3*24*3600),
                relatedAccountIds: ["acc1"],
                actionable: true
            )
        ]
    }
}
