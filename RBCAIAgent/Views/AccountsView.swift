import SwiftUI

struct AccountsView: View {
    @EnvironmentObject var dataManager: RBCDataManager
    @State private var selectedAccount: Account?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    VStack(spacing: 16) {
                        SummaryCard(
                            title: "Total Balance",
                            value: dataManager.getTotalBalance(),
                            color: .blue,
                            icon: "banknote.fill"
                        )
                        
                        SummaryCard(
                            title: "Total Debt",
                            value: dataManager.getTotalDebt(),
                            color: .red,
                            icon: "creditcard.fill"
                        )
                        
                        SummaryCard(
                            title: "Net Worth",
                            value: dataManager.getNetWorth(),
                            color: dataManager.getNetWorth() >= 0 ? .green : .red,
                            icon: "chart.line.uptrend.xyaxis"
                        )
                    }
                    
                    // Accounts List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("All Accounts")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(dataManager.accounts, id: \.id) { account in
                            AccountCard(account: account) {
                                selectedAccount = account
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedAccount) { account in
            AccountDetailView(account: account)
                .environmentObject(dataManager)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("$\(String(format: "%.2f", abs(value)))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct AccountCard: View {
    let account: Account
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: account.accountType.icon)
                    .font(.title2)
                    .foregroundColor(account.accountType.color)
                    .frame(width: 40, height: 40)
                    .background(account.accountType.color.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.nickname ?? account.accountType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(account.accountNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(account.accountType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(account.accountType.color.opacity(0.1))
                        .foregroundColor(account.accountType.color)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", account.balance))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(account.balance >= 0 ? .primary : .red)
                    
                    Text(account.isActive ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundColor(account.isActive ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((account.isActive ? Color.green : Color.red).opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AccountDetailView: View {
    let account: Account
    @EnvironmentObject var dataManager: RBCDataManager
    @Environment(\.dismiss) private var dismiss
    
    private var transactions: [Transaction] {
        dataManager.getTransactionsForAccount(account.id)
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Account Header
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: account.accountType.icon)
                                .font(.largeTitle)
                                .foregroundColor(account.accountType.color)
                                .frame(width: 60, height: 60)
                                .background(account.accountType.color.opacity(0.1))
                                .cornerRadius(15)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(account.nickname ?? account.accountType.rawValue)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(account.accountNumber)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(account.accountType.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(account.accountType.color.opacity(0.1))
                                    .foregroundColor(account.accountType.color)
                                    .cornerRadius(6)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Current Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.2f", account.balance))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(account.balance >= 0 ? .primary : .red)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Status")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(account.isActive ? "Active" : "Inactive")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(account.isActive ? .green : .red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background((account.isActive ? Color.green : Color.red).opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    
                    // Quick Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Stats")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        let monthlySpending = transactions
                            .filter { $0.date >= Date().addingTimeInterval(-30*24*3600) && $0.amount < 0 }
                            .reduce(0) { $0 + abs($1.amount) }
                        
                        let monthlyIncome = transactions
                            .filter { $0.date >= Date().addingTimeInterval(-30*24*3600) && $0.amount > 0 }
                            .reduce(0) { $0 + $1.amount }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            StatCard(title: "Monthly Spending", value: monthlySpending, color: .red)
                            StatCard(title: "Monthly Income", value: monthlyIncome, color: .green)
                        }
                    }
                    
                    // Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if transactions.isEmpty {
                            Text("No transactions found")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        } else {
                            ForEach(transactions.prefix(20), id: \.id) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Account Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("$\(String(format: "%.2f", value))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    AccountsView()
        .environmentObject(RBCDataManager())
}
