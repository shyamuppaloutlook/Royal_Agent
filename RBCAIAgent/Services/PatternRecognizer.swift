import Foundation
import SwiftUI
import Combine

class PatternRecognizer: ObservableObject {
    @Published var detectedPatterns: [FinancialPattern] = []
    @Published var patternHistory: [PatternHistory] = []
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0.0
    
    private let dataManager: RBCDataManager
    private let analysisQueue = DispatchQueue(label: "com.rbc.pattern.analysis", qos: .userInitiated)
    
    // MARK: - Pattern Types
    
    enum PatternType: String, CaseIterable {
        case spendingAnomaly = "Spending Anomaly"
        case incomeIrregularity = "Income Irregularity"
        case seasonalSpending = "Seasonal Spending"
        case subscriptionCreep = "Subscription Creep"
        case debtAccumulation = "Debt Accumulation"
        case savingsDecline = "Savings Decline"
        case investmentPattern = "Investment Pattern"
        case cashFlowCycle = "Cash Flow Cycle"
        case categoryShift = "Category Shift"
        case frequencyChange = "Frequency Change"
        case amountEscalation = "Amount Escalation"
        case timingPattern = "Timing Pattern"
        case vendorPattern = "Vendor Pattern"
        case locationPattern = "Location Pattern"
        case behavioralPattern = "Behavioral Pattern"
        case riskPattern = "Risk Pattern"
        case opportunityPattern = "Opportunity Pattern"
        case goalPattern = "Goal Pattern"
        case marketPattern = "Market Pattern"
        case economicPattern = "Economic Pattern"
    }
    
    enum PatternSeverity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var priority: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
    }
    
    enum PatternConfidence: String, CaseIterable {
        case veryLow = "Very Low"
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case veryHigh = "Very High"
        
        var score: Double {
            switch self {
            case .veryLow: return 0.0...0.2
            case .low: return 0.2...0.4
            case .medium: return 0.4...0.6
            case .high: return 0.6...0.8
            case .veryHigh: return 0.8...1.0
            }
        }
    }
    
    init(dataManager: RBCDataManager) {
        self.dataManager = dataManager
    }
    
    // MARK: - Main Analysis Methods
    
    func analyzeAllPatterns() {
        isAnalyzing = true
        analysisProgress = 0.0
        
        analysisQueue.async {
            let transactions = self.dataManager.accounts.flatMap { $0.transactions }
            let accounts = self.dataManager.accounts
            let userProfile = self.dataManager.userProfile
            
            var allPatterns: [FinancialPattern] = []
            let totalPatternTypes = PatternType.allCases.count
            
            for (index, patternType) in PatternType.allCases.enumerated() {
                let patterns = self.analyzePatternType(
                    type: patternType,
                    transactions: transactions,
                    accounts: accounts,
                    userProfile: userProfile
                )
                
                allPatterns.append(contentsOf: patterns)
                
                DispatchQueue.main.async {
                    self.analysisProgress = Double(index + 1) / Double(totalPatternTypes)
                    
                    if index == totalPatternTypes - 1 {
                        self.detectedPatterns = allPatterns.sorted { $0.severity.priority > $1.severity.priority }
                        self.isAnalyzing = false
                    }
                }
            }
        }
    }
    
    private func analyzePatternType(type: PatternType, transactions: [Transaction], accounts: [Account], userProfile: UserProfile) -> [FinancialPattern] {
        switch type {
        case .spendingAnomaly:
            return analyzeSpendingAnomalies(transactions: transactions)
        case .incomeIrregularity:
            return analyzeIncomeIrregularities(transactions: transactions)
        case .seasonalSpending:
            return analyzeSeasonalSpending(transactions: transactions)
        case .subscriptionCreep:
            return analyzeSubscriptionCreep(transactions: transactions)
        case .debtAccumulation:
            return analyzeDebtAccumulation(accounts: accounts, transactions: transactions)
        case .savingsDecline:
            return analyzeSavingsDecline(accounts: accounts, transactions: transactions)
        case .investmentPattern:
            return analyzeInvestmentPatterns(accounts: accounts, transactions: transactions)
        case .cashFlowCycle:
            return analyzeCashFlowCycles(transactions: transactions)
        case .categoryShift:
            return analyzeCategoryShifts(transactions: transactions)
        case .frequencyChange:
            return analyzeFrequencyChanges(transactions: transactions)
        case .amountEscalation:
            return analyzeAmountEscalation(transactions: transactions)
        case .timingPattern:
            return analyzeTimingPatterns(transactions: transactions)
        case .vendorPattern:
            return analyzeVendorPatterns(transactions: transactions)
        case .locationPattern:
            return analyzeLocationPatterns(transactions: transactions)
        case .behavioralPattern:
            return analyzeBehavioralPatterns(transactions: transactions, userProfile: userProfile)
        case .riskPattern:
            return analyzeRiskPatterns(accounts: accounts, transactions: transactions)
        case .opportunityPattern:
            return analyzeOpportunityPatterns(accounts: accounts, transactions: transactions)
        case .goalPattern:
            return analyzeGoalPatterns(userProfile: userProfile, accounts: accounts)
        case .marketPattern:
            return analyzeMarketPatterns(transactions: transactions)
        case .economicPattern:
            return analyzeEconomicPatterns(transactions: transactions)
        }
    }
    
    // MARK: - Specific Pattern Analysis Methods
    
    private func analyzeSpendingAnomalies(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Group transactions by category
        let categoryGroups = Dictionary(grouping: transactions) { $0.category }
        
        for (category, categoryTransactions) in categoryGroups {
            // Calculate average spending for this category
            let amounts = categoryTransactions.map { abs($0.amount) }
            let avgAmount = amounts.reduce(0, +) / Double(amounts.count)
            let stdDev = calculateStandardDeviation(values: amounts)
            
            // Find transactions that are outliers (more than 2 standard deviations from mean)
            let outliers = categoryTransactions.filter { abs(abs($0.amount) - avgAmount) > 2 * stdDev }
            
            for outlier in outliers {
                let severity = determineAnomalySeverity(amount: abs(outlier.amount), avgAmount: avgAmount, stdDev: stdDev)
                let confidence = calculateAnomalyConfidence(outlier: outlier, avgAmount: avgAmount, stdDev: stdDev)
                
                let pattern = FinancialPattern(
                    id: UUID().uuidString,
                    type: .spendingAnomaly,
                    severity: severity,
                    confidence: confidence,
                    description: "Unusual spending detected in \(category.rawValue)",
                    details: "Transaction of \(formatCurrency(abs(outlier.amount))) is significantly different from average \(formatCurrency(avgAmount))",
                    detectedAt: Date(),
                    relatedTransactions: [outlier],
                    recommendations: generateAnomalyRecommendations(category: category, amount: abs(outlier.amount)),
                    trend: .increasing,
                    impact: calculateImpact(amount: abs(outlier.amount), category: category)
                )
                
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    private func analyzeIncomeIrregularities(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Filter income transactions
        let incomeTransactions = transactions.filter { $0.amount > 0 }
        
        // Group by month
        let monthlyIncome = Dictionary(grouping: incomeTransactions) { transaction in
            Calendar.current.dateComponents([.year, .month], from: transaction.date)
        }
        
        let monthlyAmounts = monthlyIncome.map { (key, transactions) in
            (key, transactions.reduce(0) { $0 + $1.amount })
        }.sorted { $0.key < $1.key }
        
        // Calculate average monthly income
        let amounts = monthlyAmounts.map { $1 }
        let avgIncome = amounts.reduce(0, +) / Double(amounts.count)
        let stdDev = calculateStandardDeviation(values: amounts)
        
        // Find months with unusual income
        for (dateComponents, amount) in monthlyAmounts {
            if abs(amount - avgIncome) > 1.5 * stdDev {
                let severity = amount < avgIncome * 0.7 ? .high : .medium
                let confidence = calculateIncomeIrregularityConfidence(amount: amount, avgAmount: avgIncome, stdDev: stdDev)
                
                let pattern = FinancialPattern(
                    id: UUID().uuidString,
                    type: .incomeIrregularity,
                    severity: severity,
                    confidence: confidence,
                    description: "Income irregularity detected",
                    details: "\(Calendar.current.monthSymbols[dateComponents.month! - 1]) income of \(formatCurrency(amount)) differs from average \(formatCurrency(avgIncome))",
                    detectedAt: Date(),
                    relatedTransactions: monthlyIncome[dateComponents] ?? [],
                    recommendations: generateIncomeRecommendations(amount: amount, avgAmount: avgIncome),
                    trend: amount < avgIncome ? .decreasing : .increasing,
                    impact: abs(amount - avgIncome)
                )
                
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    private func analyzeSeasonalSpending(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Group by month to identify seasonal patterns
        let monthlySpending = Dictionary(grouping: transactions) { transaction in
            Calendar.current.component(.month, from: transaction.date)
        }
        
        let monthlyAverages = monthlySpending.mapValues { transactions in
            transactions.reduce(0) { $0 + abs($1.amount) } / Double(transactions.count)
        }
        
        // Identify months with significantly higher spending
        let overallAvg = monthlyAverages.values.reduce(0, +) / Double(monthlyAverages.count)
        
        for (month, avgSpending) in monthlyAverages {
            if avgSpending > overallAvg * 1.3 {
                let monthName = Calendar.current.monthSymbols[month - 1]
                let severity = avgSpending > overallAvg * 1.5 ? .high : .medium
                let confidence = calculateSeasonalConfidence(avgSpending: avgSpending, overallAvg: overallAvg)
                
                let pattern = FinancialPattern(
                    id: UUID().uuidString,
                    type: .seasonalSpending,
                    severity: severity,
                    confidence: confidence,
                    description: "Seasonal spending pattern in \(monthName)",
                    details: "\(monthName) spending is \(String(format: "%.1f", (avgSpending / overallAvg - 1) * 100))% higher than average",
                    detectedAt: Date(),
                    relatedTransactions: monthlySpending[month] ?? [],
                    recommendations: generateSeasonalRecommendations(month: monthName, avgSpending: avgSpending),
                    trend: .seasonal,
                    impact: avgSpending - overallAvg
                )
                
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    private func analyzeSubscriptionCreep(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Identify recurring transactions that look like subscriptions
        let subscriptionKeywords = ["netflix", "spotify", "apple", "google", "amazon", "microsoft", "adobe", "disney"]
        let potentialSubscriptions = transactions.filter { transaction in
            let description = transaction.description.lowercased()
            return subscriptionKeywords.contains { description.contains($0) } ||
                   description.contains("subscription") ||
                   description.contains("monthly") ||
                   description.contains("recurring")
        }
        
        // Group by vendor
        let vendorGroups = Dictionary(grouping: potentialSubscriptions) { $0.description.lowercased() }
        
        for (vendor, vendorTransactions) in vendorGroups {
            // Check if this is truly recurring (at least 3 transactions in 6 months)
            let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            let recentTransactions = vendorTransactions.filter { $0.date >= sixMonthsAgo }
            
            if recentTransactions.count >= 3 {
                let monthlyAmount = recentTransactions.map { abs($0.amount) }.reduce(0, +) / Double(recentTransactions.count)
                let annualCost = monthlyAmount * 12
                
                // Check for price increases
                let sortedTransactions = recentTransactions.sorted { $0.date < $1.date }
                let priceIncreases = detectPriceIncreases(transactions: sortedTransactions)
                
                let severity = annualCost > 1200 ? .high : annualCost > 600 ? .medium : .low
                let confidence = calculateSubscriptionConfidence(transactions: recentTransactions)
                
                let pattern = FinancialPattern(
                    id: UUID().uuidString,
                    type: .subscriptionCreep,
                    severity: severity,
                    confidence: confidence,
                    description: "Recurring subscription detected: \(vendor)",
                    details: "\(vendor) costs \(formatCurrency(monthlyAmount))/month (\(formatCurrency(annualCost))/year)",
                    detectedAt: Date(),
                    relatedTransactions: recentTransactions,
                    recommendations: generateSubscriptionRecommendations(vendor: vendor, monthlyAmount: monthlyAmount, priceIncreases: priceIncreases),
                    trend: priceIncreases.isEmpty ? .stable : .increasing,
                    impact: annualCost
                )
                
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    private func analyzeDebtAccumulation(accounts: [Account], transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Focus on credit accounts
        let creditAccounts = accounts.filter { $0.accountType == .creditCard || $0.accountType == .lineOfCredit }
        
        for account in creditAccounts {
            let accountTransactions = transactions.filter { $0.accountId == account.id }
            
            // Calculate debt trend over time
            let monthlyDebt = calculateMonthlyDebt(transactions: accountTransactions)
            let debtTrend = calculateDebtTrend(monthlyDebt: monthlyDebt)
            
            if debtTrend > 0.1 { // 10% increase in debt
                let severity = debtTrend > 0.25 ? .critical : debtTrend > 0.15 ? .high : .medium
                let confidence = calculateDebtConfidence(trend: debtTrend, dataPoints: monthlyDebt.count)
                
                let pattern = FinancialPattern(
                    id: UUID().uuidString,
                    type: .debtAccumulation,
                    severity: severity,
                    confidence: confidence,
                    description: "Debt accumulation pattern detected for \(account.nickname ?? account.accountType.rawValue)",
                    details: "Debt has increased by \(String(format: "%.1f", debtTrend * 100))% over recent months",
                    detectedAt: Date(),
                    relatedTransactions: accountTransactions,
                    recommendations: generateDebtRecommendations(account: account, trend: debtTrend),
                    trend: .increasing,
                    impact: abs(account.balance) * debtTrend
                )
                
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    private func analyzeSavingsDecline(accounts: [Account], transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Focus on savings accounts
        let savingsAccounts = accounts.filter { $0.accountType == .savings || $0.accountType == .tfSA || $0.accountType == .rRSP }
        
        for account in savingsAccounts {
            let accountTransactions = transactions.filter { $0.accountId == account.id }
            
            // Calculate savings trend
            let monthlySavings = calculateMonthlySavings(transactions: accountTransactions)
            let savingsTrend = calculateSavingsTrend(monthlySavings: monthlySavings)
            
            if savingsTrend < -0.1 { // 10% decrease in savings rate
                let severity = savingsTrend < -0.25 ? .high : savingsTrend < -0.15 ? .medium : .low
                let confidence = calculateSavingsConfidence(trend: savingsTrend, dataPoints: monthlySavings.count)
                
                let pattern = FinancialPattern(
                    id: UUID().uuidString,
                    type: .savingsDecline,
                    severity: severity,
                    confidence: confidence,
                    description: "Savings decline detected for \(account.nickname ?? account.accountType.rawValue)",
                    details: "Savings rate has decreased by \(String(format: "%.1f", abs(savingsTrend * 100)))% over recent months",
                    detectedAt: Date(),
                    relatedTransactions: accountTransactions,
                    recommendations: generateSavingsRecommendations(account: account, trend: savingsTrend),
                    trend: .decreasing,
                    impact: abs(account.balance) * abs(savingsTrend)
                )
                
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    private func analyzeInvestmentPatterns(accounts: [Account], transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Focus on investment accounts
        let investmentAccounts = accounts.filter { $0.accountType == .investment }
        
        for account in investmentAccounts {
            let accountTransactions = transactions.filter { $0.accountId == account.id }
            
            // Analyze contribution patterns
            let contributionPattern = analyzeContributionPattern(transactions: accountTransactions)
            if let pattern = contributionPattern {
                patterns.append(pattern)
            }
            
            // Analyze withdrawal patterns
            let withdrawalPattern = analyzeWithdrawalPattern(transactions: accountTransactions)
            if let pattern = withdrawalPattern {
                patterns.append(pattern)
            }
            
            // Analyze rebalancing patterns
            let rebalancingPattern = analyzeRebalancingPattern(transactions: accountTransactions)
            if let pattern = rebalancingPattern {
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    private func analyzeCashFlowCycles(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Calculate weekly cash flow
        let weeklyCashFlow = calculateWeeklyCashFlow(transactions: transactions)
        
        // Identify cycles in cash flow
        let cycles = detectCashFlowCycles(cashFlowData: weeklyCashFlow)
        
        for cycle in cycles {
            let severity = cycle.amplitude > 1000 ? .medium : .low
            let confidence = calculateCycleConfidence(cycle: cycle)
            
            let pattern = FinancialPattern(
                id: UUID().uuidString,
                type: .cashFlowCycle,
                severity: severity,
                confidence: confidence,
                description: "Cash flow cycle detected",
                details: "\(cycle.period)-week cycle with \(formatCurrency(cycle.amplitude)) amplitude",
                detectedAt: Date(),
                relatedTransactions: [],
                recommendations: generateCashFlowRecommendations(cycle: cycle),
                trend: .cyclical,
                impact: cycle.amplitude
            )
            
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    private func analyzeCategoryShifts(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze spending category changes over time
        let categoryShifts = detectCategoryShifts(transactions: transactions)
        
        for shift in categoryShifts {
            let severity = shift.magnitude > 0.3 ? .high : shift.magnitude > 0.2 ? .medium : .low
            let confidence = calculateShiftConfidence(shift: shift)
            
            let pattern = FinancialPattern(
                id: UUID().uuidString,
                type: .categoryShift,
                severity: severity,
                confidence: confidence,
                description: "Spending category shift detected",
                details: "Spending shifted from \(shift.fromCategory.rawValue) to \(shift.toCategory.rawValue) by \(String(format: "%.1f", shift.magnitude * 100))%",
                detectedAt: Date(),
                relatedTransactions: shift.relatedTransactions,
                recommendations: generateCategoryShiftRecommendations(shift: shift),
                trend: shift.toAmount > shift.fromAmount ? .increasing : .decreasing,
                impact: abs(shift.toAmount - shift.fromAmount)
            )
            
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    private func analyzeFrequencyChanges(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze transaction frequency changes
        let frequencyChanges = detectFrequencyChanges(transactions: transactions)
        
        for change in frequencyChanges {
            let severity = change.percentageChange > 0.5 ? .high : change.percentageChange > 0.3 ? .medium : .low
            let confidence = calculateFrequencyConfidence(change: change)
            
            let pattern = FinancialPattern(
                id: UUID().uuidString,
                type: .frequencyChange,
                severity: severity,
                confidence: confidence,
                description: "Transaction frequency change detected",
                details: "\(change.category.rawValue) transaction frequency changed by \(String(format: "%.1f", change.percentageChange * 100))%",
                detectedAt: Date(),
                relatedTransactions: change.transactions,
                recommendations: generateFrequencyRecommendations(change: change),
                trend: change.newFrequency > change.oldFrequency ? .increasing : .decreasing,
                impact: Double(change.transactions.count) * 50 // Estimated impact
            )
            
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    private func analyzeAmountEscalation(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze amount escalation patterns
        let escalations = detectAmountEscalation(transactions: transactions)
        
        for escalation in escalations {
            let severity = escalation.escalationRate > 0.2 ? .high : escalation.escalationRate > 0.1 ? .medium : .low
            let confidence = calculateEscalationConfidence(escalation: escalation)
            
            let pattern = FinancialPattern(
                id: UUID().uuidString,
                type: .amountEscalation,
                severity: severity,
                confidence: confidence,
                description: "Amount escalation pattern detected",
                details: "\(escalation.category.rawValue) amounts increased by \(String(format: "%.1f", escalation.escalationRate * 100))% over time",
                detectedAt: Date(),
                relatedTransactions: escalation.transactions,
                recommendations: generateEscalationRecommendations(escalation: escalation),
                trend: .increasing,
                impact: escalation.currentAmount - escalation.initialAmount
            )
            
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    private func analyzeTimingPatterns(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze timing patterns
        let timingPatterns = detectTimingPatterns(transactions: transactions)
        
        for pattern in timingPatterns {
            let severity = pattern.regularity > 0.8 ? .medium : .low
            let confidence = calculateTimingConfidence(pattern: pattern)
            
            let financialPattern = FinancialPattern(
                id: UUID().uuidString,
                type: .timingPattern,
                severity: severity,
                confidence: confidence,
                description: "Timing pattern detected",
                details: "Regular \(pattern.category.rawValue) transactions on \(pattern.dayOfWeek)s",
                detectedAt: Date(),
                relatedTransactions: pattern.transactions,
                recommendations: generateTimingRecommendations(pattern: pattern),
                trend: .regular,
                impact: Double(pattern.transactions.count) * 25
            )
            
            patterns.append(financialPattern)
        }
        
        return patterns
    }
    
    private func analyzeVendorPatterns(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze vendor-specific patterns
        let vendorPatterns = detectVendorPatterns(transactions: transactions)
        
        for pattern in vendorPatterns {
            let severity = pattern.frequency > 10 ? .medium : .low
            let confidence = calculateVendorConfidence(pattern: pattern)
            
            let financialPattern = FinancialPattern(
                id: UUID().uuidString,
                type: .vendorPattern,
                severity: severity,
                confidence: confidence,
                description: "Vendor pattern detected",
                details: "Frequent transactions with \(pattern.vendor)",
                detectedAt: Date(),
                relatedTransactions: pattern.transactions,
                recommendations: generateVendorRecommendations(pattern: pattern),
                trend: .stable,
                impact: pattern.totalAmount
            )
            
            patterns.append(financialPattern)
        }
        
        return patterns
    }
    
    private func analyzeLocationPatterns(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze location-based patterns (if location data is available)
        let locationPatterns = detectLocationPatterns(transactions: transactions)
        
        for pattern in locationPatterns {
            let severity = pattern.concentration > 0.7 ? .medium : .low
            let confidence = calculateLocationConfidence(pattern: pattern)
            
            let financialPattern = FinancialPattern(
                id: UUID().uuidString,
                type: .locationPattern,
                severity: severity,
                confidence: confidence,
                description: "Location pattern detected",
                details: "High concentration of transactions in \(pattern.location)",
                detectedAt: Date(),
                relatedTransactions: pattern.transactions,
                recommendations: generateLocationRecommendations(pattern: pattern),
                trend: .stable,
                impact: pattern.totalAmount
            )
            
            patterns.append(financialPattern)
        }
        
        return patterns
    }
    
    private func analyzeBehavioralPatterns(transactions: [Transaction], userProfile: UserProfile) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze behavioral patterns
        let behavioralPatterns = detectBehavioralPatterns(transactions: transactions, userProfile: userProfile)
        
        for pattern in behavioralPatterns {
            let severity = pattern.impactScore > 0.7 ? .high : pattern.impactScore > 0.4 ? .medium : .low
            let confidence = calculateBehavioralConfidence(pattern: pattern)
            
            let financialPattern = FinancialPattern(
                id: UUID().uuidString,
                type: .behavioralPattern,
                severity: severity,
                confidence: confidence,
                description: "Behavioral pattern detected: \(pattern.behaviorType)",
                details: pattern.description,
                detectedAt: Date(),
                relatedTransactions: pattern.transactions,
                recommendations: generateBehavioralRecommendations(pattern: pattern),
                trend: pattern.trend,
                impact: pattern.impactScore * 1000
            )
            
            patterns.append(financialPattern)
        }
        
        return patterns
    }
    
    private func analyzeRiskPatterns(accounts: [Account], transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze risk patterns
        let riskPatterns = detectRiskPatterns(accounts: accounts, transactions: transactions)
        
        for pattern in riskPatterns {
            let severity = pattern.riskLevel == .high ? .high : pattern.riskLevel == .medium ? .medium : .low
            let confidence = calculateRiskConfidence(pattern: pattern)
            
            let financialPattern = FinancialPattern(
                id: UUID().uuidString,
                type: .riskPattern,
                severity: severity,
                confidence: confidence,
                description: "Risk pattern detected: \(pattern.riskType)",
                details: pattern.description,
                detectedAt: Date(),
                relatedTransactions: pattern.transactions,
                recommendations: generateRiskRecommendations(pattern: pattern),
                trend: pattern.trend,
                impact: pattern.potentialLoss
            )
            
            patterns.append(financialPattern)
        }
        
        return patterns
    }
    
    private func analyzeOpportunityPatterns(accounts: [Account], transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze opportunity patterns
        let opportunityPatterns = detectOpportunityPatterns(accounts: accounts, transactions: transactions)
        
        for pattern in opportunityPatterns {
            let severity = pattern.potentialGain > 1000 ? .medium : .low
            let confidence = calculateOpportunityConfidence(pattern: pattern)
            
            let financialPattern = FinancialPattern(
                id: UUID().uuidString,
                type: .opportunityPattern,
                severity: severity,
                confidence: confidence,
                description: "Opportunity pattern detected: \(pattern.opportunityType)",
                details: pattern.description,
                detectedAt: Date(),
                relatedTransactions: pattern.transactions,
                recommendations: generateOpportunityRecommendations(pattern: pattern),
                trend: .opportunity,
                impact: pattern.potentialGain
            )
            
            patterns.append(financialPattern)
        }
        
        return patterns
    }
    
    private func analyzeGoalPatterns(userProfile: UserProfile, accounts: [Account]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze goal-related patterns
        let goalPatterns = detectGoalPatterns(userProfile: userProfile, accounts: accounts)
        
        for pattern in goalPatterns {
            let severity = pattern.urgency == .high ? .high : pattern.urgency == .medium ? .medium : .low
            let confidence = calculateGoalConfidence(pattern: pattern)
            
            let financialPattern = FinancialPattern(
                id: UUID().uuidString,
                type: .goalPattern,
                severity: severity,
                confidence: confidence,
                description: "Goal pattern detected: \(pattern.goalType)",
                details: pattern.description,
                detectedAt: Date(),
                relatedTransactions: [],
                recommendations: generateGoalRecommendations(pattern: pattern),
                trend: pattern.progress > 0.7 ? .onTrack : pattern.progress > 0.3 ? .atRisk : .offTrack,
                impact: pattern.remainingAmount
            )
            
            patterns.append(financialPattern)
        }
        
        return patterns
    }
    
    private func analyzeMarketPatterns(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze market-related patterns
        let marketPatterns = detectMarketPatterns(transactions: transactions)
        
        for pattern in marketPatterns {
            let severity = pattern.volatility > 0.3 ? .high : pattern.volatility > 0.15 ? .medium : .low
            let confidence = calculateMarketConfidence(pattern: pattern)
            
            let financialPattern = FinancialPattern(
                id: UUID().uuidString,
                type: .marketPattern,
                severity: severity,
                confidence: confidence,
                description: "Market pattern detected: \(pattern.marketType)",
                details: pattern.description,
                detectedAt: Date(),
                relatedTransactions: pattern.transactions,
                recommendations: generateMarketRecommendations(pattern: pattern),
                trend: pattern.trend,
                impact: pattern.marketImpact
            )
            
            patterns.append(financialPattern)
        }
        
        return patterns
    }
    
    private func analyzeEconomicPatterns(transactions: [Transaction]) -> [FinancialPattern] {
        var patterns: [FinancialPattern] = []
        
        // Analyze economic patterns
        let economicPatterns = detectEconomicPatterns(transactions: transactions)
        
        for pattern in economicPatterns {
            let severity = pattern.impact > 0.5 ? .medium : .low
            let confidence = calculateEconomicConfidence(pattern: pattern)
            
            let financialPattern = FinancialPattern(
                id: UUID().uuidString,
                type: .economicPattern,
                severity: severity,
                confidence: confidence,
                description: "Economic pattern detected: \(pattern.economicIndicator)",
                details: pattern.description,
                detectedAt: Date(),
                relatedTransactions: pattern.transactions,
                recommendations: generateEconomicRecommendations(pattern: pattern),
                trend: pattern.trend,
                impact: pattern.impact * 1000
            )
            
            patterns.append(financialPattern)
        }
        
        return patterns
    }
    
    // MARK: - Helper Methods
    
    private func calculateStandardDeviation(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count - 1)
        
        return sqrt(variance)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
    
    private func determineAnomalySeverity(amount: Double, avgAmount: Double, stdDev: Double) -> PatternSeverity {
        let deviation = abs(amount - avgAmount) / stdDev
        
        if deviation > 4 {
            return .critical
        } else if deviation > 3 {
            return .high
        } else if deviation > 2 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func calculateAnomalyConfidence(outlier: Transaction, avgAmount: Double, stdDev: Double) -> PatternConfidence {
        let deviation = abs(abs(outlier.amount) - avgAmount) / stdDev
        
        if deviation > 3.5 {
            return .veryHigh
        } else if deviation > 2.5 {
            return .high
        } else if deviation > 2 {
            return .medium
        } else {
            return .low
        }
    }
    
    // Additional helper methods would be implemented here...
    // For brevity, I'm including the main structure and key methods
    
    private func generateAnomalyRecommendations(category: TransactionCategory, amount: Double) -> [String] {
        return [
            "Review this transaction for accuracy",
            "Consider if this spending aligns with your budget",
            "Set up alerts for similar transactions"
        ]
    }
    
    private func calculateImpact(amount: Double, category: TransactionCategory) -> Double {
        // Calculate financial impact based on amount and category importance
        return amount
    }
    
    // Additional calculation and detection methods would be implemented...
}

// MARK: - Data Structures

struct FinancialPattern {
    let id: String
    let type: PatternRecognizer.PatternType
    let severity: PatternRecognizer.PatternSeverity
    let confidence: PatternRecognizer.PatternConfidence
    let description: String
    let details: String
    let detectedAt: Date
    let relatedTransactions: [Transaction]
    let recommendations: [String]
    let trend: PatternTrend
    let impact: Double
}

struct PatternHistory {
    let patternId: String
    let timestamp: Date
    let action: PatternAction
    let result: PatternResult
}

enum PatternTrend {
    case increasing, decreasing, stable, cyclical, seasonal, regular, opportunity, onTrack, atRisk, offTrack
}

enum PatternAction {
    case acknowledged, ignored, addressed, resolved
}

enum PatternResult {
    case successful, unsuccessful, pending, ongoing
}

// Additional supporting structures would be defined here...
