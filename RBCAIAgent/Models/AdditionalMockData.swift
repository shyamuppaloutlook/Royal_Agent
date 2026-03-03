import Foundation
import SwiftUI

// MARK: - Additional Mock Data Extensions

extension Budget {
    static let mockBudgets: [Budget] = [
        Budget(
            id: "budget-1",
            name: "Groceries",
            category: .groceries,
            allocatedAmount: 600.00,
            spentAmount: 423.45,
            period: .monthly,
            startDate: Date().addingTimeInterval(-15*24*3600),
            endDate: Date().addingTimeInterval(15*24*3600),
            isActive: true
        ),
        Budget(
            id: "budget-2",
            name: "Dining Out",
            category: .dining,
            allocatedAmount: 200.00,
            spentAmount: 187.50,
            period: .monthly,
            startDate: Date().addingTimeInterval(-15*24*3600),
            endDate: Date().addingTimeInterval(15*24*3600),
            isActive: true
        ),
        Budget(
            id: "budget-3",
            name: "Entertainment",
            category: .entertainment,
            allocatedAmount: 150.00,
            spentAmount: 45.99,
            period: .monthly,
            startDate: Date().addingTimeInterval(-15*24*3600),
            endDate: Date().addingTimeInterval(15*24*3600),
            isActive: true
        ),
        Budget(
            id: "budget-4",
            name: "Transportation",
            category: .transportation,
            allocatedAmount: 250.00,
            spentAmount: 267.80,
            period: .monthly,
            startDate: Date().addingTimeInterval(-15*24*3600),
            endDate: Date().addingTimeInterval(15*24*3600),
            isActive: true
        )
    ]
}

extension FinancialGoal {
    static let mockGoals: [FinancialGoal] = [
        FinancialGoal(
            id: "goal-1",
            name: "Emergency Fund",
            description: "Build 6 months of expenses in emergency savings",
            targetAmount: 15000.00,
            currentAmount: 8900.12,
            targetDate: Date().addingTimeInterval(180*24*3600), // 6 months
            category: .emergencyFund,
            priority: .high,
            isActive: true,
            createdAt: Date().addingTimeInterval(-90*24*3600)
        ),
        FinancialGoal(
            id: "goal-2",
            name: "Vacation Fund",
            description: "Save for summer vacation to Hawaii",
            targetAmount: 5000.00,
            currentAmount: 1250.00,
            targetDate: Date().addingTimeInterval(120*24*3600), // 4 months
            category: .vacation,
            priority: .medium,
            isActive: true,
            createdAt: Date().addingTimeInterval(-60*24*3600)
        ),
        FinancialGoal(
            id: "goal-3",
            name: "New Laptop",
            description: "Save for a new MacBook Pro",
            targetAmount: 2500.00,
            currentAmount: 1875.00,
            targetDate: Date().addingTimeInterval(30*24*3600), // 1 month
            category: .other,
            priority: .medium,
            isActive: true,
            createdAt: Date().addingTimeInterval(-45*24*3600)
        ),
        FinancialGoal(
            id: "goal-4",
            name: "House Down Payment",
            description: "Save for first home down payment",
            targetAmount: 50000.00,
            currentAmount: 12500.00,
            targetDate: Date().addingTimeInterval(730*24*3600), // 2 years
            category: .homePurchase,
            priority: .high,
            isActive: true,
            createdAt: Date().addingTimeInterval(-365*24*3600)
        )
    ]
}

extension InvestmentPortfolio {
    static let mockPortfolio = InvestmentPortfolio(
        id: "portfolio-1",
        name: "RBC Investment Portfolio",
        totalValue: 45678.90,
        totalGain: 3456.78,
        totalGainPercentage: 8.2,
        holdings: [
            InvestmentHolding(
                id: "holding-1",
                symbol: "AAPL",
                companyName: "Apple Inc.",
                quantity: 50,
                averageCost: 145.50,
                currentPrice: 178.25,
                current_value: 8912.50,
                gain: 1637.50,
                gainPercentage: 22.5,
                sector: "Technology",
                lastUpdated: Date()
            ),
            InvestmentHolding(
                id: "holding-2",
                symbol: "GOOGL",
                companyName: "Alphabet Inc.",
                quantity: 20,
                averageCost: 2450.00,
                currentPrice: 2680.50,
                current_value: 53610.00,
                gain: 4610.00,
                gainPercentage: 9.4,
                sector: "Technology",
                lastUpdated: Date()
            ),
            InvestmentHolding(
                id: "holding-3",
                symbol: "TD",
                companyName: "Toronto Dominion Bank",
                quantity: 100,
                averageCost: 78.25,
                currentPrice: 82.40,
                current_value: 8240.00,
                gain: 415.00,
                gainPercentage: 5.3,
                sector: "Financial",
                lastUpdated: Date()
            ),
            InvestmentHolding(
                id: "holding-4",
                symbol: "ENB",
                companyName: "Enbridge Inc.",
                quantity: 75,
                averageCost: 45.60,
                currentPrice: 48.20,
                current_value: 3615.00,
                gain: 195.00,
                gainPercentage: 5.7,
                sector: "Energy",
                lastUpdated: Date()
            )
        ],
        lastUpdated: Date()
    )
}

extension CreditReport {
    static let mockCreditReport = CreditReport(
        id: "credit-1",
        creditScore: 742,
        scoreRange: .veryGood,
        lastUpdated: Date().addingTimeInterval(-7*24*3600),
        factors: [
            CreditFactor(name: "Payment History", impact: .positive, description: "You have a strong history of on-time payments"),
            CreditFactor(name: "Credit Utilization", impact: .positive, description: "Low credit utilization ratio of 23%"),
            CreditFactor(name: "Credit Age", impact: .neutral, description: "Average age of credit accounts is 6 years"),
            CreditFactor(name: "Credit Mix", impact: .positive, description: "Good mix of credit types"),
            CreditFactor(name: "Recent Inquiries", impact: .neutral, description: "1 hard inquiry in the last 6 months")
        ],
        accounts: [
            CreditAccount(
                id: "credit-acc-1",
                name: "RBC Rewards Visa",
                type: "Credit Card",
                balance: 1234.56,
                limit: 10000.00,
                paymentStatus: .current,
                lastPaymentDate: Date().addingTimeInterval(-15*24*3600),
                openedDate: Date().addingTimeInterval(-1825*24*3600) // 5 years ago
            ),
            CreditAccount(
                id: "credit-acc-2",
                name: "RBC Line of Credit",
                type: "Line of Credit",
                balance: 5000.00,
                limit: 25000.00,
                paymentStatus: .current,
                lastPaymentDate: Date().addingTimeInterval(-30*24*3600),
                openedDate: Date().addingTimeInterval(-1095*24*3600) // 3 years ago
            ),
            CreditAccount(
                id: "credit-acc-3",
                name: "Auto Loan",
                type: "Installment Loan",
                balance: 12500.00,
                limit: 30000.00,
                paymentStatus: .current,
                lastPaymentDate: Date().addingTimeInterval(-7*24*3600),
                openedDate: Date().addingTimeInterval(-730*24*3600) // 2 years ago
            )
        ],
        inquiries: [
            CreditInquiry(
                id: "inquiry-1",
                type: .hard,
                date: Date().addingTimeInterval(-45*24*3600),
                company: "RBC Royal Bank"
            ),
            CreditInquiry(
                id: "inquiry-2",
                type: .soft,
                date: Date().addingTimeInterval(-7*24*3600),
                company: "Credit Bureau"
            )
        ]
    )
}

extension RecurringPayment {
    static let mockRecurringPayments: [RecurringPayment] = [
        RecurringPayment(
            id: "payment-1",
            name: "Netflix Subscription",
            amount: 15.99,
            frequency: .monthly,
            nextDueDate: Date().addingTimeInterval(5*24*3600),
            category: .entertainment,
            merchant: "Netflix",
            isActive: true,
            autoPayEnabled: true,
            paymentMethod: "RBC Rewards Visa ****1234"
        ),
        RecurringPayment(
            id: "payment-2",
            name: "Hydro Bill",
            amount: 145.00,
            frequency: .monthly,
            nextDueDate: Date().addingTimeInterval(12*24*3600),
            category: .bills,
            merchant: "Hydro One",
            isActive: true,
            autoPayEnabled: true,
            paymentMethod: "RBC Chequing ****1234"
        ),
        RecurringPayment(
            id: "payment-3",
            name: "Internet",
            amount: 75.00,
            frequency: .monthly,
            nextDueDate: Date().addingTimeInterval(18*24*3600),
            category: .bills,
            merchant: "Rogers",
            isActive: true,
            autoPayEnabled: true,
            paymentMethod: "RBC Rewards Visa ****1234"
        ),
        RecurringPayment(
            id: "payment-4",
            name: "Phone Bill",
            amount: 65.00,
            frequency: .monthly,
            nextDueDate: Date().addingTimeInterval(22*24*3600),
            category: .bills,
            merchant: "Rogers",
            isActive: true,
            autoPayEnabled: true,
            paymentMethod: "RBC Rewards Visa ****1234"
        ),
        RecurringPayment(
            id: "payment-5",
            name: "Gym Membership",
            amount: 49.99,
            frequency: .monthly,
            nextDueDate: Date().addingTimeInterval(25*24*3600),
            category: .other,
            merchant: "GoodLife Fitness",
            isActive: true,
            autoPayEnabled: false,
            paymentMethod: nil
        )
    ]
}

extension NotificationPreference {
    static let mockPreferences: [NotificationPreference] = [
        NotificationPreference(
            id: "notif-1",
            type: .lowBalance,
            isEnabled: true,
            channels: [.push, .email],
            thresholds: ["minimumBalance": 500.00]
        ),
        NotificationPreference(
            id: "notif-2",
            type: .largeTransaction,
            isEnabled: true,
            channels: [.push, .sms],
            thresholds: ["amount": 1000.00]
        ),
        NotificationPreference(
            id: "notif-3",
            type: .billReminder,
            isEnabled: true,
            channels: [.push, .email],
            thresholds: ["daysBefore": 3]
        ),
        NotificationPreference(
            id: "notif-4",
            type: .budgetAlert,
            isEnabled: true,
            channels: [.push, .inApp],
            thresholds: ["percentage": 80]
        ),
        NotificationPreference(
            id: "notif-5",
            type: .goalMilestone,
            isEnabled: true,
            channels: [.push, .email],
            thresholds: ["milestonePercentage": 25]
        ),
        NotificationPreference(
            id: "notif-6",
            type: .investmentUpdate,
            isEnabled: false,
            channels: [.email],
            thresholds: ["changePercentage": 5.0]
        ),
        NotificationPreference(
            id: "notif-7",
            type: .creditScoreChange,
            isEnabled: true,
            channels: [.push, .email],
            thresholds: ["points": 10]
        ),
        NotificationPreference(
            id: "notif-8",
            type: .unusualActivity,
            isEnabled: true,
            channels: [.push, .sms, .email],
            thresholds: ["amount": 500.00]
        )
    ]
}

extension FinancialReport {
    static let mockReports: [FinancialReport] = [
        FinancialReport(
            id: "report-1",
            title: "Monthly Statement - February 2024",
            type: .monthlyStatement,
            generatedDate: Date().addingTimeInterval(-2*24*3600),
            period: DateInterval(
                start: Date().addingTimeInterval(-32*24*3600),
                end: Date().addingTimeInterval(-2*24*3600)
            ),
            data: ReportData(
                totalIncome: 3500.00,
                totalExpenses: 2847.65,
                netIncome: 652.35,
                savingsRate: 18.6,
                topSpendingCategories: [
                    (.groceries, 678.90),
                    (.dining, 234.50),
                    (.transportation, 198.75),
                    (.bills, 145.00),
                    (.entertainment, 89.99)
                ],
                accountBalances: [
                    ("acc1", 3456.78),
                    ("acc2", 12500.00),
                    ("acc3", -1234.56),
                    ("acc4", 8900.12)
                ],
                goalsProgress: [
                    ("goal-1", 59.3),
                    ("goal-2", 25.0),
                    ("goal-3", 75.0),
                    ("goal-4", 25.0)
                ]
            ),
            insights: [
                "Your grocery spending increased by 15% this month",
                "You saved 18.6% of your income, above your 15% target",
                "Consider reducing dining expenses to meet your savings goals"
            ]
        ),
        FinancialReport(
            id: "report-2",
            title: "Investment Performance - Q1 2024",
            type: .investmentPerformance,
            generatedDate: Date().addingTimeInterval(-15*24*3600),
            period: DateInterval(
                start: Date().addingTimeInterval(-90*24*3600),
                end: Date().addingTimeInterval(-1*24*3600)
            ),
            data: ReportData(
                totalIncome: 3456.78,
                totalExpenses: 234.50,
                netIncome: 3222.28,
                savingsRate: 93.2,
                topSpendingCategories: [],
                accountBalances: [],
                goalsProgress: []
            ),
            insights: [
                "Your portfolio returned 8.2% this quarter",
                "Technology stocks performed best with 22.5% gains",
                "Consider rebalancing your portfolio to reduce risk"
            ]
        )
    ]
}

// MARK: - Mock Data Generator
class MockDataGenerator {
    
    static func generateAllMockData() {
        print("📊 Generating comprehensive mock data...")
        
        // Test all mock data
        print("✅ Budgets: \(Budget.mockBudgets.count) items")
        print("✅ Goals: \(FinancialGoal.mockGoals.count) items")
        print("✅ Portfolio: \(InvestmentPortfolio.mockPortfolio.holdings.count) holdings")
        print("✅ Credit Report: Score \(CreditReport.mockCreditReport.creditScore)")
        print("✅ Recurring Payments: \(RecurringPayment.mockRecurringPayments.count) items")
        print("✅ Notification Preferences: \(NotificationPreference.mockPreferences.count) preferences")
        print("✅ Financial Reports: \(FinancialReport.mockReports.count) reports")
        
        print("🎉 All additional mock data generated successfully!")
    }
    
    static func validateDataIntegrity() -> Bool {
        print("🔍 Validating data integrity...")
        
        var isValid = true
        
        // Validate budgets
        for budget in Budget.mockBudgets {
            if budget.spentAmount > budget.allocatedAmount && !budget.isOverBudget {
                print("❌ Budget validation failed: \(budget.name)")
                isValid = false
            }
        }
        
        // Validate goals
        for goal in FinancialGoal.mockGoals {
            if goal.currentAmount > goal.targetAmount && !goal.isCompleted {
                print("❌ Goal validation failed: \(goal.name)")
                isValid = false
            }
        }
        
        // Validate portfolio
        let portfolioValue = InvestmentPortfolio.mockPortfolio.holdings.reduce(0) { $0 + $1.current_value }
        if abs(portfolioValue - InvestmentPortfolio.mockPortfolio.totalValue) > 0.01 {
            print("❌ Portfolio validation failed: Value mismatch")
            isValid = false
        }
        
        // Validate credit score range
        let creditScore = CreditReport.mockCreditReport.creditScore
        if creditScore < 300 || creditScore > 850 {
            print("❌ Credit score validation failed: Invalid score")
            isValid = false
        }
        
        if isValid {
            print("✅ All data integrity checks passed!")
        }
        
        return isValid
    }
}
