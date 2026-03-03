import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var dataManager: RBCDataManager
    @State private var selectedCategory: TransactionCategory? = nil
    @State private var searchText = ""
    
    private var filteredTransactions: [Transaction] {
        let allTransactions = dataManager.accounts.flatMap { $0.transactions }
            .sorted { $0.date > $1.date }
        
        var filtered = allTransactions
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(searchText) ||
                transaction.merchant?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search transactions...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryFilterChip(
                                category: nil,
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(TransactionCategory.allCases, id: \.self) { category in
                                CategoryFilterChip(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Transactions List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTransactions, id: \.id) { transaction in
                            TransactionRow(transaction: transaction)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            
                            if transaction.id != filteredTransactions.last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CategoryFilterChip: View {
    let category: TransactionCategory?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                }
                
                Text(category?.rawValue ?? "All")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TransactionsView()
        .environmentObject(RBCDataManager())
}
