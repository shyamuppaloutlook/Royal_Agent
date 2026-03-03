import SwiftUI

@main
struct RBCAIAgentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct SimpleChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @State private var isTyping = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                        
                        if isTyping {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI is thinking...")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                
                // Input
                HStack {
                    TextField("Type your message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isTyping)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.isEmpty || isTyping)
                }
                .padding()
            }
            .navigationTitle("RBC Assistant")
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(id: UUID().uuidString, content: messageText, isFromUser: true, timestamp: Date())
        messages.append(userMessage)
        
        let input = messageText
        messageText = ""
        isTyping = true
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = generateResponse(for: input)
            let aiMessage = ChatMessage(id: UUID().uuidString, content: response, isFromUser: false, timestamp: Date())
            messages.append(aiMessage)
            isTyping = false
        }
    }
    
    private func generateResponse(for input: String) -> String {
        let lowercase = input.lowercased()
        
        if lowercase.contains("balance") {
            return "Your current balance is $2,500.00 across all accounts."
        } else if lowercase.contains("transaction") {
            return "You have 5 recent transactions totaling $342.50. Would you like to see details?"
        } else if lowercase.contains("help") {
            return "I can help with balances, transactions, transfers, and account information."
        } else if lowercase.contains("hello") || lowercase.contains("hi") {
            return "Hello! I'm your RBC AI assistant. How can I help you today?"
        } else {
            return "I'm here to help with your banking needs. You can ask about balances, transactions, or transfers."
        }
    }
}

struct SimpleDashboardView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        SummaryCard(title: "Total Balance", value: "$2,500", color: .green)
                        SummaryCard(title: "Recent Transactions", value: "5", color: .blue)
                        SummaryCard(title: "Accounts", value: "3", color: .orange)
                        SummaryCard(title: "Credit Score", value: "750", color: .purple)
                    }
                    
                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            TransactionRow(description: "Coffee Shop", amount: "-$4.50", category: "Food")
                            TransactionRow(description: "Grocery Store", amount: "-$125.30", category: "Groceries")
                            TransactionRow(description: "Salary", amount: "+$2,500.00", category: "Income")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                Spacer()
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TransactionRow: View {
    let description: String
    let amount: String
    let category: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(description)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(category)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(amount)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(amount.hasPrefix("-") ? .red : .green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
