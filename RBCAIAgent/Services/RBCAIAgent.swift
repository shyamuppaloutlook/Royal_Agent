import Foundation
import SwiftUI

class RBCAIAgent: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    
    private let dataManager: RBCDataManager
    
    init(dataManager: RBCDataManager) {
        self.dataManager = dataManager
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            id: UUID().uuidString,
            content: "Hello! I'm your RBC AI assistant. I can help you:\n\n• Track your spending and account balances\n• Find transactions and analyze patterns\n• Provide personalized insights\n• Answer questions about your finances\n• Help with budget recommendations\n\nHow can I assist you today?",
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    func sendMessage(_ userInput: String) {
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: userInput,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        isTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let response = self.generateResponse(for: userInput)
            let aiMessage = ChatMessage(
                id: UUID().uuidString,
                content: response,
                isFromUser: false,
                timestamp: Date()
            )
            self.messages.append(aiMessage)
            self.isTyping = false
        }
    }
    
    private func generateResponse(for input: String) -> String {
        let lowercasedInput = input.lowercased()
        
        // Balance inquiries
        if lowercasedInput.contains("balance") || lowercasedInput.contains("how much") {
            return generateBalanceResponse(input: lowercasedInput)
        }
        
        // Spending analysis
        if lowercasedInput.contains("spend") || lowercasedInput.contains("spent") || lowercasedInput.contains("expenses") {
            return generateSpendingResponse(input: lowercasedInput)
        }
        
        // Transaction search
        if lowercasedInput.contains("transaction") || lowercasedInput.contains("purchase") || lowercasedInput.contains("payment") {
            return generateTransactionResponse(input: lowercasedInput)
        }
        
        // Account information
        if lowercasedInput.contains("account") {
            return generateAccountResponse(input: lowercasedInput)
        }
        
        // Insights and recommendations
        if lowercasedInput.contains("insight") || lowercasedInput.contains("recommend") || lowercasedInput.contains("advice") {
            return generateInsightResponse()
        }
        
        // Budget help
        if lowercasedInput.contains("budget") {
            return generateBudgetResponse()
        }
        
        // Bills and payments
        if lowercasedInput.contains("bill") || lowercasedInput.contains("payment") {
            return generateBillsResponse()
        }
        
        // Net worth
        if lowercasedInput.contains("net worth") || lowercasedInput.contains("total") {
            return generateNetWorthResponse()
        }
        
        // Default response
        return generateGeneralResponse()
    }
    
    private func generateBalanceResponse(input: String) -> String {
        let totalBalance = dataManager.getTotalBalance()
        let totalDebt = dataManager.getTotalDebt()
        
        var response = "Here's your current balance information:\n\n"
        
        if input.contains("total") || input.contains("all") {
            response += "💰 Total Balance: $\(String(format: "%.2f", totalBalance))\n"
            response += "💳 Total Debt: $\(String(format: "%.2f", totalDebt))\n"
            response += "📊 Net Worth: $\(String(format: "%.2f", totalBalance - totalDebt))\n\n"
        }
        
        response += "Account Breakdown:\n"
        for account in dataManager.accounts {
            let emoji = account.accountType == .creditCard && account.balance < 0 ? "💳" : "💰"
            response += "\(emoji) \(account.nickname ?? account.accountType.rawValue): $\(String(format: "%.2f", account.balance))\n"
        }
        
        return response
    }
    
    private func generateSpendingResponse(input: String) -> String {
        let spending = dataManager.getSpendingByCategory()
        let totalSpending = spending.values.reduce(0, +)
        
        var response = "📊 Your spending analysis:\n\n"
        response += "Total spending this month: $\(String(format: "%.2f", totalSpending))\n\n"
        
        let sortedSpending = spending.sorted { $0.value > $1.value }
        for (category, amount) in sortedSpending.prefix(5) {
            let percentage = totalSpending > 0 ? (amount / totalSpending * 100) : 0
            response += "\(category.icon) \(category.rawValue): $\(String(format: "%.2f", amount)) (\(String(format: "%.1f", percentage))%)\n"
        }
        
        if input.contains("trend") || input.contains("pattern") {
            let trend = dataManager.getMonthlySpendingTrend()
            response += "\n📈 Monthly Trend:\n"
            for monthData in trend.suffix(3) {
                response += "\(monthData.month): $\(String(format: "%.2f", monthData.amount))\n"
            }
        }
        
        return response
    }
    
    private func generateTransactionResponse(input: String) -> String {
        var response = "🔍 Recent transactions:\n\n"
        
        let allTransactions = dataManager.accounts.flatMap { $0.transactions }
            .sorted { $0.date > $1.date }
            .prefix(10)
        
        for transaction in allTransactions {
            let date = DateFormatter.shortDate.string(from: transaction.date)
            let status = transaction.isPending ? "⏳" : "✅"
            response += "\(status) \(date) - \(transaction.description): $\(String(format: "%.2f", transaction.amount))\n"
        }
        
        return response
    }
    
    private func generateAccountResponse(input: String) -> String {
        var response = "🏦 Your accounts:\n\n"
        
        for account in dataManager.accounts {
            response += "\(account.accountType.icon) \(account.nickname ?? account.accountType.rawValue)\n"
            response += "   Account: \(account.accountNumber)\n"
            response += "   Balance: $\(String(format: "%.2f", account.balance))\n"
            response += "   Status: \(account.isActive ? "✅ Active" : "❌ Inactive")\n\n"
        }
        
        return response
    }
    
    private func generateInsightResponse() -> String {
        var response = "💡 Personalized insights:\n\n"
        
        let actionableInsights = dataManager.insights.filter { $0.actionable }
        
        for insight in actionableInsights.prefix(3) {
            let emoji = insight.severity == .high ? "🚨" : insight.severity == .medium ? "⚠️" : "ℹ️"
            response += "\(emoji) \(insight.title)\n"
            response += "\(insight.description)\n\n"
        }
        
        return response
    }
    
    private func generateBudgetResponse() -> String {
        let spending = dataManager.getSpendingByCategory()
        
        var response = "📋 Budget recommendations:\n\n"
        response += "Based on your spending patterns:\n\n"
        
        let budgetRecommendations: [TransactionCategory: Double] = [
            .groceries: 400.0,
            .dining: 200.0,
            .entertainment: 100.0,
            .transportation: 150.0,
            .shopping: 250.0
        ]
        
        for (category, currentSpending) in spending {
            if let recommended = budgetRecommendations[category] {
                let status = currentSpending > recommended ? "⚠️ Over" : currentSpending > recommended * 0.8 ? "⚠️ Close" : "✅ Good"
                response += "\(category.icon) \(category.rawValue): $\(String(format: "%.2f", currentSpending)) / $\(String(format: "%.2f", recommended)) \(status)\n"
            }
        }
        
        return response
    }
    
    private func generateBillsResponse() -> String {
        let upcomingBills = dataManager.getUpcomingBills()
        
        var response = "📅 Bills and payments:\n\n"
        
        if upcomingBills.isEmpty {
            response += "No upcoming bills in the next month."
        } else {
            for bill in upcomingBills {
                let date = DateFormatter.shortDate.string(from: bill.date)
                response += "📋 \(date) - \(bill.description): $\(String(format: "%.2f", abs(bill.amount)))\n"
            }
        }
        
        return response
    }
    
    private func generateNetWorthResponse() -> String {
        let netWorth = dataManager.getNetWorth()
        let totalAssets = dataManager.getTotalBalance()
        let totalDebt = dataManager.getTotalDebt()
        
        return """
        📊 Your Net Worth Summary:
        
        💰 Total Assets: $\(String(format: "%.2f", totalAssets))
        💳 Total Debt: $\(String(format: "%.2f", totalDebt))
        📈 Net Worth: $\(String(format: "%.2f", netWorth))
        
        Your net worth is \(netWorth >= 0 ? "positive" : "negative"). Keep up the good work on building your financial health!
        """
    }
    
    private func generateGeneralResponse() -> String {
        return """
        I can help you with various banking questions! Try asking me about:
        
        • Account balances and net worth
        • Recent transactions and spending
        • Budget recommendations
        • Upcoming bills and payments
        • Personalized insights
        • Account information
        
        What would you like to know?
        """
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
