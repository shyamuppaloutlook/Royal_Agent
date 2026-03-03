import SwiftUI
// import Charts  // Commented out - Charts framework not available

struct InsightsView: View {
    @EnvironmentObject var dataManager: RBCDataManager
    @State private var selectedTimeframe: Timeframe = .month
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Timeframe Selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // AI Insights
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Insights")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(dataManager.insights, id: \.id) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                    
                    // Spending Analysis
                    SpendingAnalysisView(dataManager: dataManager, timeframe: selectedTimeframe)
                    
                    // Budget Overview
                    BudgetOverviewView(dataManager: dataManager)
                    
                    // Financial Health Score
                    FinancialHealthScoreView(dataManager: dataManager)
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct InsightCard: View {
    let insight: AccountInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.title3)
                    .foregroundColor(insight.severity.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(insight.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Circle()
                        .fill(insight.severity.color)
                        .frame(width: 8, height: 8)
                    
                    Text(DateFormatter.shortDate.string(from: insight.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            if insight.actionable {
                Button(action: {
                    // Handle action
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                        Text("Take Action")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct SpendingAnalysisView: View {
    let dataManager: RBCDataManager
    let timeframe: InsightsView.Timeframe
    
    private var spendingData: [TransactionCategory: Double] {
        let days: TimeInterval
        switch timeframe {
        case .week: days = 7
        case .month: days = 30
        case .quarter: days = 90
        case .year: days = 365
        }
        
        return dataManager.getSpendingByCategory(
            for: DateInterval(
                start: Date().addingTimeInterval(-days * 24 * 3600),
                end: Date()
            )
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            let totalSpending = spendingData.values.reduce(0, +)
            
            if !spendingData.isEmpty {
                // Pie Chart
                Chart(Array(spendingData.prefix(6)), id: \.key) { category, amount in
                    SectorMark(
                        angle: .value("Amount", amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(category.color.gradient)
                    .opacity(0.8)
                }
                .frame(height: 200)
                .chartAngleSelection(value: .constant(nil))
                .chartBackground { _ in
                    VStack(spacing: 4) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.0f", totalSpending))")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                // Category Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Categories")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let sortedSpending = spendingData.sorted { $0.value > $1.value }
                    
                    ForEach(Array(sortedSpending.prefix(5)), id: \.key) { category, amount in
                        HStack {
                            Image(systemName: category.icon)
                                .font(.caption)
                                .foregroundColor(category.color)
                                .frame(width: 20)
                            
                            Text(category.rawValue)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$\(String(format: "%.2f", amount))")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("\(String(format: "%.1f", totalSpending > 0 ? (amount / totalSpending * 100) : 0))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Text("No spending data for selected period")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct BudgetOverviewView: View {
    let dataManager: RBCDataManager
    
    private var spendingData: [TransactionCategory: Double] {
        dataManager.getSpendingByCategory()
    }
    
    private let budgetRecommendations: [TransactionCategory: Double] = [
        .groceries: 400.0,
        .dining: 200.0,
        .entertainment: 100.0,
        .transportation: 150.0,
        .shopping: 250.0
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(Array(budgetRecommendations.keys), id: \.self) { category in
                    let spent = spendingData[category] ?? 0
                    let budget = budgetRecommendations[category] ?? 0
                    let percentage = budget > 0 ? min(spent / budget, 1.0) : 0
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: category.icon)
                                .font(.caption)
                                .foregroundColor(category.color)
                                .frame(width: 20)
                            
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.0f", spent)) / $\(String(format: "%.0f", budget))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: percentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: percentage)))
                            .scaleEffect(y: 1.5)
                        
                        if percentage > 1.0 {
                            Text("Over budget by $\(String(format: "%.2f", spent - budget))")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if percentage > 0.8 {
                            Text("Close to budget limit")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage > 1.0 {
            return .red
        } else if percentage > 0.8 {
            return .orange
        } else if percentage > 0.6 {
            return .yellow
        } else {
            return .green
        }
    }
}

struct FinancialHealthScoreView: View {
    let dataManager: RBCDataManager
    
    private var healthScore: Int {
        var score = 50 // Base score
        
        // Net worth factor (30 points)
        let netWorth = dataManager.getNetWorth()
        if netWorth > 10000 {
            score += 30
        } else if netWorth > 0 {
            score += Int((netWorth / 10000) * 30)
        }
        
        // Debt ratio factor (20 points)
        let totalBalance = dataManager.getTotalBalance()
        let totalDebt = dataManager.getTotalDebt()
        let debtRatio = totalBalance > 0 ? totalDebt / totalBalance : 1
        
        if debtRatio < 0.3 {
            score += 20
        } else if debtRatio < 0.5 {
            score += 15
        } else if debtRatio < 0.7 {
            score += 10
        }
        
        return min(score, 100)
    }
    
    private var healthDescription: String {
        switch healthScore {
        case 90...100:
            return "Excellent! Your financial health is outstanding."
        case 80..<90:
            return "Very good! You're managing your finances well."
        case 70..<80:
            return "Good! There's room for improvement."
        case 60..<70:
            return "Fair. Consider reviewing your spending habits."
        case 50..<60:
            return "Below average. Focus on reducing debt and increasing savings."
        default:
            return "Needs attention. Create a budget and financial plan."
        }
    }
    
    private var scoreColor: Color {
        switch healthScore {
        case 80...100:
            return .green
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Health Score")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Score Display
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(healthScore)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(scoreColor)
                        
                        Text("out of 100")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Circular Progress
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(healthScore) / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: healthScore)
                    }
                }
                
                // Description
                Text(healthDescription)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                
                // Recommendations
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let recommendations = getRecommendations()
                    ForEach(recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .frame(width: 16)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private func getRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let netWorth = dataManager.getNetWorth()
        if netWorth < 0 {
            recommendations.append("Focus on paying down high-interest debt")
        }
        
        let totalBalance = dataManager.getTotalBalance()
        let totalDebt = dataManager.getTotalDebt()
        let debtRatio = totalBalance > 0 ? totalDebt / totalBalance : 1
        
        if debtRatio > 0.5 {
            recommendations.append("Work on reducing your debt-to-income ratio")
        }
        
        let spending = dataManager.getSpendingByCategory()
        let totalSpending = spending.values.reduce(0, +)
        
        if totalSpending > 2000 {
            recommendations.append("Review and categorize your monthly expenses")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Continue your excellent financial habits")
            recommendations.append("Consider increasing your savings rate")
        }
        
        return Array(recommendations.prefix(3))
    }
}

#Preview {
    InsightsView()
        .environmentObject(RBCDataManager())
}
