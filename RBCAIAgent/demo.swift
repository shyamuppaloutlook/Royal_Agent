#!/usr/bin/env swift

import Foundation

// MARK: - Simple RBC AI Agent Demo
// This is a working sample that demonstrates the core functionality

print("🏦 RBC AI Agent - Demo Version")
print("=" * 40)

// MARK: - Data Models

struct ChatMessage {
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(content: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

enum ChatIntent {
    case balanceInquiry
    case transactionSearch
    case helpRequest
    case greeting
    case unknown
    
    static func recognize(from text: String) -> ChatIntent {
        let lowercase = text.lowercased(
        
        if lowercase.contains("balance") || lowercase.contains("how much") {
            return .balanceInquiry
        } else if lowercase.contains("transaction") || lowercase.contains("spent") {
            return .transactionSearch
        } else if lowercase.contains("help") || lowercase.contains("what can") {
            return .helpRequest
        } else if lowercase.contains("hello") || lowercase.contains("hi") {
            return .greeting
        } else {
            return .unknown
        }
    }
}

// MARK: - Mock Data

class MockDataService {
    private let accounts = [
        ("Checking Account", 2500.00),
        ("Savings Account", 15000.00),
        ("Credit Card", -500.00)
    ]
    
    private let transactions = [
        ("Coffee Shop", 4.50, "Food & Dining"),
        ("Grocery Store", 125.30, "Groceries"),
        ("Gas Station", 45.00, "Transportation"),
        ("Netflix", 15.99, "Entertainment"),
        ("Salary Deposit", 2500.00, "Income")
    ]
    
    func getTotalBalance() -> Double {
        return accounts.reduce(0) { $0 + $1.1 }
    }
    
    func getRecentTransactions(count: Int = 5) -> [(String, Double, String)] {
        return Array(transactions.prefix(count))
    }
    
    func getSpendingByCategory() -> [String: Double] {
        var spending: [String: Double] = [:]
        
        for (_, amount, category) in transactions {
            if amount < 0 { // Debits only
                spending[category, default: 0] += abs(amount)
            }
        }
        
        return spending
    }
}

// MARK: - Response Generator

class ResponseGenerator {
    private let dataService = MockDataService()
    
    func generateResponse(for input: String, intent: ChatIntent) -> String {
        switch intent {
        case .balanceInquiry:
            return generateBalanceResponse()
            
        case .transactionSearch:
            return generateTransactionResponse()
            
        case .helpRequest:
            return generateHelpResponse()
            
        case .greeting:
            return generateGreetingResponse()
            
        case .unknown:
            return generateGeneralResponse()
        }
    }
    
    private func generateBalanceResponse() -> String {
        let balance = dataService.getTotalBalance()
        return """
        💰 Your Account Balance:
        
        Total Balance: $\(String(format: "%.2f", balance))
        
        Account Summary:
        • Checking Account: $2,500.00
        • Savings Account: $15,000.00
        • Credit Card: -$500.00
        
        Would you like details about any specific account?
        """
    }
    
    private func generateTransactionResponse() -> String {
        let transactions = dataService.getRecentTransactions()
        
        var response = "📊 Recent Transactions:\n\n"
        
        for (description, amount, category) in transactions.prefix(3) {
            let emoji = amount < 0 ? "💸" : "💰"
            response += "\(emoji) \(description): $\(String(format: "%.2f", abs(amount))) (\(category))\n"
        }
        
        response += "\nTotal transactions shown: \(transactions.count)"
        
        return response
    }
    
    private func generateHelpResponse() -> String {
        return """
        🤖 RBC AI Assistant - Available Commands:
        
        💰 Account Information:
        • "What's my balance?" - Check account balances
        • "Show me my accounts" - List all accounts
        
        📊 Transactions:
        • "Show transactions" - View recent transactions
        • "How much did I spend?" - Spending analysis
        
        🏦 Banking Services:
        • "Transfer money" - Money transfers
        • "Pay bills" - Bill payments
        • "Investment info" - Investment details
        
        ❓ Help:
        • "Help" - Show this menu
        • "What can you do?" - List capabilities
        
        Just type your question naturally!
        """
    }
    
    private func generateGreetingResponse() -> String {
        let greetings = [
            "Hello! 👋 I'm your RBC AI assistant. How can I help you today?",
            "Hi there! 😊 Ready to assist with your banking needs. What can I do for you?",
            "Good day! 🏦 Welcome to RBC AI Assistant. How may I help you?"
        ]
        
        return greetings.randomElement() ?? "Hello! How can I assist you?"
    }
    
    private func generateGeneralResponse() -> String {
        return """
        I'm here to help with your banking needs! 🏦
        
        You can ask me about:
        • Account balances 💰
        • Recent transactions 📊
        • Money transfers 💸
        • Investment information 📈
        
        Type "help" for more options, or just ask me a question!
        """
    }
}

// MARK: - Chat Service

class ChatService {
    private let responseGenerator = ResponseGenerator()
    private var messages: [ChatMessage] = []
    
    func processMessage(_ input: String) -> String {
        // Add user message
        let userMessage = ChatMessage(content: input, isFromUser: true)
        messages.append(userMessage)
        
        // Recognize intent
        let intent = ChatIntent.recognize(from: input)
        
        // Generate response
        let response = responseGenerator.generateResponse(for: input, intent: intent)
        
        // Add assistant message
        let assistantMessage = ChatMessage(content: response, isFromUser: false)
        messages.append(assistantMessage)
        
        return response
    }
    
    func getConversationHistory() -> [ChatMessage] {
        return messages
    }
}

// MARK: - Demo Runner

class ChatDemo {
    private let chatService = ChatService()
    
    func start() {
        print("\n🚀 Starting RBC AI Agent Demo...")
        print("Type 'quit' to exit, 'history' to see conversation history\n")
        
        // Send welcome message
        let welcomeResponse = chatService.processMessage("hello")
        print("🤖 Assistant: \(welcomeResponse)\n")
        
        // Main chat loop
        while true {
            print("💬 You: ", terminator: "")
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                continue
            }
            
            if input.lowercased() == "quit" {
                print("\n👋 Goodbye! Thanks for using RBC AI Agent!")
                break
            }
            
            if input.lowercased() == "history" {
                showHistory()
                continue
            }
            
            if input.isEmpty {
                continue
            }
            
            print("⏳ Processing...")
            
            let response = chatService.processMessage(input)
            print("🤖 Assistant: \(response)\n")
        }
    }
    
    private func showHistory() {
        let history = chatService.getConversationHistory()
        
        print("\n📜 Conversation History:")
        print("-" * 40)
        
        for message in history {
            let prefix = message.isFromUser ? "💬 You" : "🤖 Assistant"
            print("\(prefix): \(message.content)")
        }
        
        print("-" * 40)
        print("Total messages: \(history.count)\n")
    }
}

// MARK: - String Extension for Repetition

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Run Demo

let demo = ChatDemo()
demo.start()
