import Foundation
import SwiftUI

class InsightEngine {
    private var financialKnowledgeBase: FinancialKnowledgeBase = FinancialKnowledgeBase()
    private var patternRecognizer: PatternRecognizer = PatternRecognizer()
    private var anomalyDetector: AnomalyDetector = AnomalyDetector()
    private var predictiveModeler: PredictiveModeler = PredictiveModeler()
    
    func generateProactiveInsights(dataManager: RBCDataManager, userBehavior: UserBehaviorTracker, conversationHistory: ConversationContext) -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Analyze current financial data
        let currentSnapshot = createFinancialSnapshot(dataManager: dataManager)
        
        // Generate insights based on different analysis types
        
        // 1. Spending pattern insights
        insights.append(contentsOf: generateSpendingPatternInsights(
            snapshot: currentSnapshot,
            behavior: userBehavior
        ))
        
        // 2. Account optimization insights
        insights.append(contentsOf: generateAccountOptimizationInsights(
            accounts: dataManager.accounts
        ))
        
        // 3. Goal progress insights
        insights.append(contentsOf: generateGoalProgressInsights(
            snapshot: currentSnapshot,
            userPreferences: userBehavior.getUserPreferences()
        ))
        
        // 4. Market opportunity insights
        insights.append(contentsOf: generateMarketOpportunityInsights(
            snapshot: currentSnapshot
        ))
        
        // 5. Risk alert insights
        insights.append(contentsOf: generateRiskAlertInsights(
            snapshot: currentSnapshot,
            accounts: dataManager.accounts
        ))
        
        // 6. Seasonal insights
        insights.append(contentsOf: generateSeasonalInsights(
            snapshot: currentSnapshot
        ))
        
        // 7. Behavioral insights
        insights.append(contentsOf: generateBehavioralInsights(
            behavior: userBehavior,
            conversationHistory: conversationHistory
        ))
        
        // Sort by priority and confidence
        insights.sort { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority.rawValue > rhs.priority.rawValue
            }
            return lhs.confidence > rhs.confidence
        }
        
        // Return top insights
        return Array(insights.prefix(5))
    }
    
    // MARK: - Insight Generation Methods
    
    private func generateSpendingPatternInsights(snapshot: FinancialSnapshot, behavior: UserBehaviorTracker) -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Analyze spending trends
        let spendingAnalysis = analyzeSpendingTrends(snapshot: snapshot)
        
        // Unusual spending increase
        if let increase = spendingAnalysis.unusualIncrease {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .spendingAnomaly,
                title: "Unusual Spending Increase Detected",
                content: "Your \(increase.category) spending increased by \(String(format: "%.1f", increase.percentage))% this month. This is significantly higher than your usual pattern.",
                confidence: 0.85,
                priority: .medium,
                actionable: true,
                data: increase,
                suggestedActions: [
                    "Review recent \(increase.category.lowercased()) transactions",
                    "Set a budget alert for this category",
                    "Consider if this increase is temporary or permanent"
                ]
            ))
        }
        
        // Subscription optimization
        let subscriptions = identifySubscriptionOpportunities(snapshot: snapshot)
        if !subscriptions.isEmpty {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .savingsOpportunity,
                title: "Subscription Optimization Opportunity",
                content: "I found \(subscriptions.count) subscription\(subscriptions.count == 1 ? "" : "s") that could potentially be optimized or canceled, saving you up to $\(String(format: "%.2f", subscriptions.reduce(0) { $0 + $1.potentialSavings })) per month.",
                confidence: 0.75,
                priority: .low,
                actionable: true,
                data: subscriptions,
                suggestedActions: subscriptions.map { "Review \($0.name) subscription" }
            ))
        }
        
        // Recurring payment patterns
        let recurringPatterns = analyzeRecurringPaymentPatterns(snapshot: snapshot)
        if let pattern = recurringPatterns.concerningPattern {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .cashFlowPattern,
                title: "Recurring Payment Pattern Alert",
                content: "I've noticed a pattern in your \(pattern.category) payments that might indicate an opportunity for optimization or a potential issue.",
                confidence: 0.70,
                priority: .medium,
                actionable: true,
                data: pattern,
                suggestedActions: [
                    "Review recurring \(pattern.category.lowercased()) payments",
                    "Consider negotiating better rates",
                    "Look for alternative providers"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateAccountOptimizationInsights(accounts: [Account]) -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Idle account detection
        let idleAccounts = identifyIdleAccounts(accounts: accounts)
        if !idleAccounts.isEmpty {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .accountOptimization,
                title: "Idle Account Opportunity",
                content: "You have \(idleAccounts.count) account\(idleAccounts.count == 1 ? "" : "s") with no recent activity. Consider consolidating or closing these to optimize your financial structure.",
                confidence: 0.80,
                priority: .low,
                actionable: true,
                data: idleAccounts,
                suggestedActions: idleAccounts.map { "Review \($0.nickname ?? $0.accountType.rawValue) account" }
            ))
        }
        
        // High-fee account detection
        let highFeeAccounts = identifyHighFeeAccounts(accounts: accounts)
        if !highFeeAccounts.isEmpty {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .costOptimization,
                title: "High-Fee Account Alert",
                content: "I've identified \(highFeeAccounts.count) account\(highFeeAccounts.count == 1 ? "" : "s") with potentially high fees. Switching to lower-fee alternatives could save you $\(String(format: "%.2f", highFeeAccounts.reduce(0) { $0 + $1.annualSavings })) annually.",
                confidence: 0.75,
                priority: .medium,
                actionable: true,
                data: highFeeAccounts,
                suggestedActions: highFeeAccounts.map { "Compare fees for \($0.nickname ?? $0.accountType.rawValue)" }
            ))
        }
        
        // Interest rate optimization
        let interestOpportunities = identifyInterestRateOpportunities(accounts: accounts)
        if !interestOpportunities.isEmpty {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .interestOptimization,
                title: "Interest Rate Optimization",
                content: "Your savings could earn \(String(format: "%.2f", interestOpportunities.reduce(0) { $0 + $1.additionalInterest })) more annually with better interest rates.",
                confidence: 0.70,
                priority: .medium,
                actionable: true,
                data: interestOpportunities,
                suggestedActions: interestOpportunities.map { "Explore higher-yield options for \($0.accountName)" }
            ))
        }
        
        return insights
    }
    
    private func generateGoalProgressInsights(snapshot: FinancialSnapshot, userPreferences: UserPreferences) -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Goal progress analysis
        let goalAnalysis = analyzeGoalProgress(snapshot: snapshot, goals: userPreferences.financialGoals)
        
        // Off-track goals
        let offTrackGoals = goalAnalysis.offTrackGoals
        if !offTrackGoals.isEmpty {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .goalAlert,
                title: "Goal Progress Alert",
                content: "\(offTrackGoals.count) of your financial goal\(offTrackGoals.count == 1 ? "" : "s") \(offTrackGoals.count == 1 ? "is" : "are") behind schedule. Adjustments may be needed to stay on track.",
                confidence: 0.85,
                priority: .high,
                actionable: true,
                data: offTrackGoals,
                suggestedActions: offTrackGoals.map { "Review \($0.description) progress" }
            ))
        }
        
        // Goal achievement opportunities
        let achievabilityAnalysis = analyzeGoalAchievability(snapshot: snapshot, goals: userPreferences.financialGoals)
        if let opportunity = achievabilityAnalysis.accelerationOpportunity {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .goalOpportunity,
                title: "Goal Acceleration Opportunity",
                content: "With your current savings rate, you could achieve your '\(opportunity.goalDescription)' goal \(opportunity.monthsEarlier) months earlier by making small adjustments.",
                confidence: 0.75,
                priority: .medium,
                actionable: true,
                data: opportunity,
                suggestedActions: [
                    "Increase monthly savings by $\(String(format: "%.0f", opportunity.additionalSavingsNeeded))",
                    "Optimize investment returns",
                    "Reduce expenses in flexible categories"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateMarketOpportunityInsights(snapshot: FinancialSnapshot) -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Investment opportunities
        let investmentAnalysis = analyzeInvestmentOpportunities(snapshot: snapshot)
        
        if let opportunity = investmentAnalysis.topOpportunity {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .investmentOpportunity,
                title: "Investment Opportunity Alert",
                content: "Current market conditions present an opportunity in \(opportunity.sector). Based on your risk profile, this could align well with your investment strategy.",
                confidence: 0.70,
                priority: .medium,
                actionable: true,
                data: opportunity,
                suggestedActions: [
                    "Research \(opportunity.sector) investments",
                    "Consult with investment advisor",
                    "Consider allocation adjustment"
                ]
            ))
        }
        
        // Tax-loss harvesting opportunities
        let taxOpportunities = analyzeTaxOptimizationOpportunities(snapshot: snapshot)
        if !taxOpportunities.isEmpty {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .taxOptimization,
                title: "Tax Optimization Opportunity",
                content: "I've identified \(taxOpportunities.count) tax optimization opportunity\(taxOpportunities.count == 1 ? "" : "s") that could save you approximately $\(String(format: "%.2f", taxOpportunities.reduce(0) { $0 + $1.potentialSavings })) this year.",
                confidence: 0.75,
                priority: .medium,
                actionable: true,
                data: taxOpportunities,
                suggestedActions: taxOpportunities.map { "Consider \($0.strategy)" }
            ))
        }
        
        return insights
    }
    
    private func generateRiskAlertInsights(snapshot: FinancialSnapshot, accounts: [Account]) -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Emergency fund adequacy
        let emergencyFundAnalysis = analyzeEmergencyFundAdequacy(snapshot: snapshot)
        if emergencyFundAnalysis.monthsCovered < 3 {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .riskAlert,
                title: "Emergency Fund Alert",
                content: "Your emergency fund covers only \(String(format: "%.1f", emergencyFundAnalysis.monthsCovered)) months of expenses. Financial experts recommend 3-6 months.",
                confidence: 0.90,
                priority: .high,
                actionable: true,
                data: emergencyFundAnalysis,
                suggestedActions: [
                    "Set up automatic emergency fund transfers",
                    "Reduce discretionary spending temporarily",
                    "Consider a high-yield savings account"
                ]
            ))
        }
        
        // Debt concentration risk
        let debtAnalysis = analyzeDebtConcentration(accounts: accounts)
        if debtAnalysis.concentrationRisk > 0.7 {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .concentrationRisk,
                title: "Debt Concentration Risk",
                content: "\(String(format: "%.1f", debtAnalysis.concentrationRisk * 100))% of your debt is concentrated in \(debtAnalysis.primaryDebtType). Consider diversifying your debt structure.",
                confidence: 0.80,
                priority: .medium,
                actionable: true,
                data: debtAnalysis,
                suggestedActions: [
                    "Explore debt consolidation options",
                    "Prioritize high-interest debt repayment",
                    "Consider refinancing opportunities"
                ]
            ))
        }
        
        // Income volatility risk
        let incomeAnalysis = analyzeIncomeStability(snapshot: snapshot)
        if incomeAnalysis.volatilityScore > 0.4 {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .incomeRisk,
                title: "Income Volatility Alert",
                content: "Your income shows significant volatility. Building a larger emergency fund and diversifying income sources could provide more stability.",
                confidence: 0.75,
                priority: .medium,
                actionable: true,
                data: incomeAnalysis,
                suggestedActions: [
                    "Build a 6-month emergency fund",
                    "Explore additional income streams",
                    "Consider income protection insurance"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateSeasonalInsights(snapshot: FinancialSnapshot) -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Seasonal spending patterns
        let seasonalAnalysis = analyzeSeasonalPatterns(snapshot: snapshot)
        
        if let upcomingSeason = seasonalAnalysis.upcomingHighSpendingSeason {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .seasonalAlert,
                title: "Seasonal Spending Alert",
                content: "Historically, your spending increases by \(String(format: "%.1f", upcomingSeason.averageIncrease))% during \(upcomingSeason.season). Consider budgeting accordingly.",
                confidence: 0.80,
                priority: .medium,
                actionable: true,
                data: upcomingSeason,
                suggestedActions: [
                    "Set aside extra funds for \(upcomingSeason.season.lowercased())",
                    "Look for early-bird deals",
                    "Create a seasonal budget"
                ]
            ))
        }
        
        // Tax season preparation
        if isTaxSeasonApproaching() {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .seasonalPreparation,
                title: "Tax Season Preparation",
                content: "Tax season is approaching. Start organizing your financial documents and consider tax optimization strategies.",
                confidence: 0.85,
                priority: .medium,
                actionable: true,
                data: ["season": "tax", "deadline": getTaxDeadline()],
                suggestedActions: [
                    "Gather tax documents",
                    "Review tax-deductible expenses",
                    "Consider RRSP contributions"
                ]
            ))
        }
        
        return insights
    }
    
    private func generateBehavioralInsights(behavior: UserBehaviorTracker, conversationHistory: ConversationContext) -> [ProactiveInsight] {
        var insights: [ProactiveInsight] = []
        
        // Usage patterns
        let behaviorInsights = behavior.getBehaviorInsights()
        
        // Peak activity time insights
        if behaviorInsights.mostActiveHour >= 20 || behaviorInsights.mostActiveHour <= 6 {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .behavioralPattern,
                title: "Financial Wellness Reminder",
                content: "I notice you often check your finances late at night or early in the morning. Remember that financial decisions are best made when you're well-rested.",
                confidence: 0.65,
                priority: .low,
                actionable: true,
                data: ["activeHour": behaviorInsights.mostActiveHour],
                suggestedActions: [
                    "Schedule regular financial check-ins",
                    "Set up automated alerts",
                    "Practice mindful financial decision-making"
                ]
            ))
        }
        
        // Topic preferences
        if let preferredTopic = behaviorInsights.preferredTopics.first {
            insights.append(ProactiveInsight(
                id: UUID().uuidString,
                type: .personalizationOpportunity,
                title: "Deep Dive Opportunity",
                content: "You frequently ask about \(preferredTopic). Would you like me to prepare a comprehensive analysis of your \(preferredTopic) situation?",
                confidence: 0.70,
                priority: .low,
                actionable: true,
                data: ["preferredTopic": preferredTopic],
                suggestedActions: [
                    "Request detailed \(preferredTopic) analysis",
                    "Set up \(preferredTopic) monitoring",
                    "Explore advanced \(preferredTopic) strategies"
                ]
            ))
        }
        
        return insights
    }
    
    // MARK: - Analysis Helper Methods
    
    private func createFinancialSnapshot(dataManager: RBCDataManager) -> FinancialSnapshot {
        return FinancialSnapshot(
            netWorth: dataManager.getNetWorth(),
            monthlyIncome: calculateMonthlyIncome(dataManager: dataManager),
            monthlyExpenses: calculateMonthlyExpenses(dataManager: dataManager),
            savingsRate: calculateSavingsRate(dataManager: dataManager),
            accounts: dataManager.accounts,
            recentTransactions: dataManager.accounts.flatMap { $0.transactions }.filter { 
                $0.date >= Date().addingTimeInterval(-90*24*3600) 
            }
        )
    }
    
    private func analyzeSpendingTrends(snapshot: FinancialSnapshot) -> SpendingTrendAnalysis {
        let transactions = snapshot.recentTransactions.filter { $0.amount < 0 }
        let spendingByCategory = Dictionary(grouping: transactions) { $0.category }
            .mapValues { $0.reduce(0) { $0 + abs($1.amount) } }
        
        // Look for unusual increases
        var unusualIncrease: SpendingIncrease?
        
        // This would involve comparing current month to historical averages
        // For now, we'll use a simplified approach
        
        return SpendingTrendAnalysis(
            unusualIncrease: unusualIncrease,
            topCategories: Array(spendingByCategory.sorted { $0.value > $1.value }.prefix(3))
        )
    }
    
    private func identifySubscriptionOpportunities(snapshot: FinancialSnapshot) -> [SubscriptionOpportunity] {
        let transactions = snapshot.recentTransactions
        let subscriptionKeywords = ["netflix", "spotify", "apple", "google", "amazon", "microsoft", "adobe"]
        
        var opportunities: [SubscriptionOpportunity] = []
        
        for transaction in transactions {
            if subscriptionKeywords.contains(where: { transaction.description.lowercased().contains($0) }) {
                // This is a simplified detection - in production, you'd use more sophisticated methods
                opportunities.append(SubscriptionOpportunity(
                    name: transaction.description,
                    amount: abs(transaction.amount),
                    frequency: "monthly",
                    potentialSavings: abs(transaction.amount) * 0.5 // Assume 50% could be saved
                ))
            }
        }
        
        return opportunities
    }
    
    private func analyzeRecurringPaymentPatterns(snapshot: FinancialSnapshot) -> RecurringPaymentAnalysis {
        // Analyze patterns in recurring payments
        // This would involve more sophisticated pattern recognition
        
        return RecurringPaymentAnalysis(
            concerningPattern: nil // Would be populated based on analysis
        )
    }
    
    private func identifyIdleAccounts(accounts: [Account]) -> [IdleAccount] {
        let threeMonthsAgo = Date().addingTimeInterval(-90*24*3600)
        
        return accounts.compactMap { account in
            let recentTransactions = account.transactions.filter { $0.date >= threeMonthsAgo }
            if recentTransactions.isEmpty && account.accountType != .investment {
                return IdleAccount(
                    account: account,
                    lastActivity: account.transactions.max { $0.date < $1.date }?.date ?? Date.distantPast,
                    balance: account.balance
                )
            }
            return nil
        }
    }
    
    private func identifyHighFeeAccounts(accounts: [Account]) -> [HighFeeAccount] {
        // This would involve actual fee analysis
        // For now, return empty array
        return []
    }
    
    private func identifyInterestRateOpportunities(accounts: [Account]) -> [InterestRateOpportunity] {
        var opportunities: [InterestRateOpportunity] = []
        
        for account in accounts {
            if account.accountType == .savings && account.balance > 1000 {
                // Assume current rate is 0.5% and market rate is 2.0%
                let currentRate = 0.005
                let marketRate = 0.02
                let additionalInterest = account.balance * (marketRate - currentRate)
                
                if additionalInterest > 50 { // Only if meaningful
                    opportunities.append(InterestRateOpportunity(
                        accountName: account.nickname ?? account.accountType.rawValue,
                        currentRate: currentRate,
                        marketRate: marketRate,
                        additionalInterest: additionalInterest
                    ))
                }
            }
        }
        
        return opportunities
    }
    
    private func analyzeGoalProgress(snapshot: FinancialSnapshot, goals: [UserGoal]) -> GoalProgressAnalysis {
        var offTrackGoals: [UserGoal] = []
        
        for goal in goals {
            // Simplified progress calculation
            let progress = calculateGoalProgress(goal: goal, currentNetWorth: snapshot.netWorth)
            if !progress.onTrack {
                offTrackGoals.append(goal)
            }
        }
        
        return GoalProgressAnalysis(offTrackGoals: offTrackGoals)
    }
    
    private func analyzeGoalAchievability(snapshot: FinancialSnapshot, goals: [UserGoal]) -> GoalAchievabilityAnalysis {
        // Look for goals that could be achieved faster
        // This would involve more sophisticated projection
        
        return GoalAchievabilityAnalysis(
            accelerationOpportunity: nil // Would be populated based on analysis
        )
    }
    
    private func analyzeInvestmentOpportunities(snapshot: FinancialSnapshot) -> InvestmentOpportunityAnalysis {
        // This would involve market analysis
        return InvestmentOpportunityAnalysis(
            topOpportunity: nil // Would be populated based on market conditions
        )
    }
    
    private func analyzeTaxOptimizationOpportunities(snapshot: FinancialSnapshot) -> [TaxOpportunity] {
        // This would involve tax analysis
        return []
    }
    
    private func analyzeEmergencyFundAdequacy(snapshot: FinancialSnapshot) -> EmergencyFundAnalysis {
        let monthsCovered = snapshot.monthlyExpenses > 0 ? 
            (snapshot.accounts.filter { $0.accountType == .savings || $0.accountType == .chequing }
                .reduce(0) { $0 + max(0, $1.balance) }) / snapshot.monthlyExpenses : 0
        
        return EmergencyFundAnalysis(monthsCovered: monthsCovered)
    }
    
    private func analyzeDebtConcentration(accounts: [Account]) -> DebtConcentrationAnalysis {
        let debtAccounts = accounts.filter { $0.balance < 0 }
        let totalDebt = debtAccounts.reduce(0) { $0 + abs($1.balance) }
        
        let primaryDebtType = debtAccounts.max { abs($0.balance) < abs($1.balance) }?.accountType.rawValue ?? "none"
        let primaryDebtAmount = debtAccounts.max { abs($0.balance) < abs($1.balance) }.map { abs($0.balance) } ?? 0
        let concentrationRisk = totalDebt > 0 ? primaryDebtAmount / totalDebt : 0
        
        return DebtConcentrationAnalysis(
            concentrationRisk: concentrationRisk,
            primaryDebtType: primaryDebtType
        )
    }
    
    private func analyzeIncomeStability(snapshot: FinancialSnapshot) -> IncomeStabilityAnalysis {
        // This would involve analyzing income volatility over time
        return IncomeStabilityAnalysis(
            volatilityScore: 0.3 // Placeholder
        )
    }
    
    private func analyzeSeasonalPatterns(snapshot: FinancialSnapshot) -> SeasonalAnalysis {
        // This would involve analyzing seasonal spending patterns
        return SeasonalAnalysis(
            upcomingHighSpendingSeason: nil // Would be populated based on analysis
        )
    }
    
    private func isTaxSeasonApproaching() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        
        // Tax season typically approaches in February-April
        return month >= 2 && month <= 4
    }
    
    private func getTaxDeadline() -> String {
        return "April 30" // Canadian tax deadline
    }
    
    // MARK: - Helper Calculation Methods
    
    private func calculateMonthlyIncome(dataManager: RBCDataManager) -> Double {
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        let recentIncome = dataManager.accounts.flatMap { $0.transactions }
            .filter { $0.amount > 0 && $0.date >= threeMonthsAgo }
            .reduce(0) { $0 + $1.amount }
        
        return recentIncome / 3.0
    }
    
    private func calculateMonthlyExpenses(dataManager: RBCDataManager) -> Double {
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        let recentExpenses = dataManager.accounts.flatMap { $0.transactions }
            .filter { $0.amount < 0 && $0.date >= threeMonthsAgo }
            .reduce(0) { $0 + abs($1.amount) }
        
        return recentExpenses / 3.0
    }
    
    private func calculateSavingsRate(dataManager: RBCDataManager) -> Double {
        let income = calculateMonthlyIncome(dataManager: dataManager)
        let expenses = calculateMonthlyExpenses(dataManager: dataManager)
        
        return income > 0 ? max(0, (income - expenses) / income) : 0
    }
    
    private func calculateGoalProgress(goal: UserGoal, currentNetWorth: Double) -> GoalProgress {
        // Simplified progress calculation
        let progress = goal.targetAmount > 0 ? min(1.0, currentNetWorth / goal.targetAmount) : 0
        
        return GoalProgress(
            goalId: goal.id,
            currentProgress: progress,
            targetAmount: goal.targetAmount,
            timeRemaining: goal.targetDate?.timeIntervalSinceNow ?? 0,
            onTrack: progress > 0.5, // Simplified
            projectedCompletion: goal.targetDate
        )
    }
    
    // MARK: - Knowledge Base Loading
    
    func loadFinancialKnowledgeBase() {
        financialKnowledgeBase.loadDefaultKnowledge()
        patternRecognizer.initializePatterns()
        anomalyDetector.loadBaselinePatterns()
        predictiveModeler.initializeModels()
    }
}

// MARK: - Data Structures

struct ProactiveInsight {
    let id: String
    let type: InsightType
    let title: String
    let content: String
    let confidence: Double
    let priority: InsightPriority
    let actionable: Bool
    let data: Any?
    let suggestedActions: [String]
    let generatedAt: Date = Date()
}


enum InsightPriority: Int {
    case low = 1, medium = 2, high = 3, critical = 4
}

struct FinancialSnapshot {
    let netWorth: Double
    let monthlyIncome: Double
    let monthlyExpenses: Double
    let savingsRate: Double
    let accounts: [Account]
    let recentTransactions: [Transaction]
}

struct SpendingTrendAnalysis {
    let unusualIncrease: SpendingIncrease?
    let topCategories: [(TransactionCategory, Double)]
}

struct SpendingIncrease {
    let category: String
    let percentage: Double
    let amount: Double
}

struct SubscriptionOpportunity {
    let name: String
    let amount: Double
    let frequency: String
    let potentialSavings: Double
}

struct RecurringPaymentAnalysis {
    let concerningPattern: RecurringPaymentPattern?
}

struct RecurringPaymentPattern {
    let category: String
    let pattern: String
    let concern: String
}

struct IdleAccount {
    let account: Account
    let lastActivity: Date
    let balance: Double
}

struct HighFeeAccount {
    let accountName: String
    let currentFees: Double
    let alternativeFees: Double
    let annualSavings: Double
}

struct InterestRateOpportunity {
    let accountName: String
    let currentRate: Double
    let marketRate: Double
    let additionalInterest: Double
}

struct GoalProgressAnalysis {
    let offTrackGoals: [UserGoal]
}

struct GoalAchievabilityAnalysis {
    let accelerationOpportunity: GoalAccelerationOpportunity?
}

struct GoalAccelerationOpportunity {
    let goalDescription: String
    let monthsEarlier: Int
    let additionalSavingsNeeded: Double
}

struct InvestmentOpportunityAnalysis {
    let topOpportunity: MarketOpportunity?
}

struct MarketOpportunity {
    let sector: String
    let description: String
    let riskLevel: String
    let potentialReturn: Double
}

struct TaxOpportunity {
    let strategy: String
    let potentialSavings: Double
    let complexity: String
}

struct EmergencyFundAnalysis {
    let monthsCovered: Double
}

struct DebtConcentrationAnalysis {
    let concentrationRisk: Double
    let primaryDebtType: String
}

struct IncomeStabilityAnalysis {
    let volatilityScore: Double
}

struct SeasonalAnalysis {
    let upcomingHighSpendingSeason: SeasonalSpendingPattern?
}

struct SeasonalSpendingPattern {
    let season: String
    let averageIncrease: Double
    let typicalCategories: [String]
}

// MARK: - Supporting Classes (Simplified for brevity)

class FinancialKnowledgeBase {
    func loadDefaultKnowledge() {
        // Load financial rules, best practices, etc.
    }
}

class PatternRecognizer {
    func initializePatterns() {
        // Initialize spending patterns, seasonal patterns, etc.
    }
}

class AnomalyDetector {
    func loadBaselinePatterns() {
        // Load baseline patterns for anomaly detection
    }
}

class PredictiveModeler {
    func initializeModels() {
        // Initialize predictive models
    }
}

extension UserBehaviorTracker {
    func getUserPreferences() -> UserPreferences {
        // Return user preferences - would be stored in the tracker
        return UserPreferences()
    }
}
