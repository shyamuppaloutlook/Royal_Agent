import SwiftUI
// import Charts  // Commented out - Charts framework not available

struct DashboardView: View {
    @EnvironmentObject var dataManager: RBCDataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Welcome back,")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(dataManager.userProfile.preferredName ?? dataManager.userProfile.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(dataManager.userProfile.preferredName?.prefix(1).uppercased() ?? dataManager.userProfile.name.prefix(1).uppercased()))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                )
                        }
                        
                        Divider()
                        
                        HStack(spacing: 30) {
                            VStack(alignment: .leading) {
                                Text("Net Worth")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.2f", dataManager.getNetWorth()))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(dataManager.getNetWorth() >= 0 ? .green : .red)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Total Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.2f", dataManager.getTotalBalance()))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Total Debt")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.2f", dataManager.getTotalDebt()))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            QuickActionButton(icon: "chart.bar.fill", title: "Spending", color: .orange)
                            QuickActionButton(icon: "banknote.fill", title: "Transfer", color: .green)
                            QuickActionButton(icon: "doc.text.fill", title: "Bills", color: .blue)
                            QuickActionButton(icon: "creditcard.fill", title: "Cards", color: .purple)
                        }
                    }
                    
                    // Accounts Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accounts Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(dataManager.accounts, id: \.id) { account in
                            AccountRow(account: account)
                        }
                    }
                    
                    // Spending Summary (Simple View)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Spending Summary")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        let spendingTrend = dataManager.getMonthlySpendingTrend()
                        
                        if !spendingTrend.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(spendingTrend.prefix(6), id: \.month) { data in
                                    HStack {
                                        Text(data.month)
                                            .font(.caption)
                                            .frame(width: 60, alignment: .leading)
                                        
                                        Rectangle()
                                            .fill(Color.blue.gradient)
                                            .frame(width: CGFloat(data.amount / spendingTrend.prefix(6).map { $0.amount }.max()! * 100), height: 20)
                                        
                                        Text("$\(String(format: "%.0f", data.amount))")
                                            .font(.caption)
                                            .frame(width: 60, alignment: .trailing)
                                    }
                                }
                            }
                            .frame(height: 150)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 150)
                                .overlay(
                                    Text("No spending data available")
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                    
                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Transactions")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            NavigationLink("See All") {
                                TransactionsView()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        let recentTransactions = dataManager.accounts.flatMap { $0.transactions }
                            .sorted { $0.date > $1.date }
                            .prefix(5)
                        
                        ForEach(recentTransactions, id: \.id) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("RBC AI Agent")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct AccountRow: View {
    let account: Account
    
    var body: some View {
        HStack {
            Image(systemName: account.accountType.icon)
                .font(.title2)
                .foregroundColor(account.accountType.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.nickname ?? account.accountType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(account.accountNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", account.balance))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(account.balance >= 0 ? .primary : .red)
                
                Text(account.accountType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundColor(transaction.category.color)
                .frame(width: 35)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.merchant ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if transaction.isPending {
                        Text("• Pending")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", abs(transaction.amount)))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
                
                Text(DateFormatter.shortDate.string(from: transaction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DashboardView()
        .environmentObject(RBCDataManager())
}
