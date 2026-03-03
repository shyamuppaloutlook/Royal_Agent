import Foundation
import Combine

class FinancialAnalyzer {
    private let marketDataProvider = MarketDataProvider()
    private let riskCalculator = RiskCalculator()
    private let projectionEngine = ProjectionEngine()
    private let budgetOptimizer = BudgetOptimizer()
    
    // MARK: - Comprehensive Analysis
    
    func performComprehensiveAnalysis(dataManager: RBCDataManager, query: ProcessedQuery, userPreferences: UserPreferences) -> ComprehensiveAnalysis {
        let accounts = dataManager.accounts
        let transactions = accounts.flatMap { $0.transactions }
        
        // Calculate key metrics
        let netWorth = dataManager.getNetWorth()
        let totalAssets = dataManager.getTotalBalance()
        let totalDebt = dataManager.getTotalDebt()
        let monthlyIncome = calculateMonthlyIncome(transactions)
        let monthlyExpenses = calculateMonthlyExpenses(transactions)
        let savingsRate = calculateSavingsRate(monthlyIncome: monthlyIncome, monthlyExpenses: monthlyExpenses)
        
        // Cash flow analysis
        let cashFlowAnalysis = analyzeCashFlow(transactions: transactions)
        
        // Spending patterns
        let spendingPatterns = analyzeSpendingPatterns(transactions: transactions)
        
        // Account performance
        let accountPerformance = analyzeAccountPerformance(accounts: accounts)
        
        // Risk assessment
        let riskProfile = assessFinancialRisk(accounts: accounts, transactions: transactions, userPreferences: userPreferences)
        
        // Investment analysis
        let investmentAnalysis = analyzeInvestments(accounts: accounts.filter { $0.accountType == .investment || $0.accountType == .tfSA || $0.accountType == .rRSP })
        
        // Goal progress
        let goalProgress = analyzeGoalProgress(userPreferences: userPreferences, currentNetWorth: netWorth)
        
        // Predictive insights
        let predictiveInsights = generatePredictiveInsights(
            currentData: FinancialDataSnapshot(
                netWorth: netWorth,
                monthlyIncome: monthlyIncome,
                monthlyExpenses: monthlyExpenses,
                savingsRate: savingsRate
            ),
            historicalTrends: extractHistoricalTrends(transactions: transactions)
        )
        
        return ComprehensiveAnalysis(
            keyMetrics: FinancialMetrics(
                netWorth: netWorth,
                totalAssets: totalAssets,
                totalDebt: totalDebt,
                monthlyIncome: monthlyIncome,
                monthlyExpenses: monthlyExpenses,
                savingsRate: savingsRate,
                debtToIncomeRatio: totalDebt / max(monthlyIncome, 1),
                emergencyFundMonths: calculateEmergencyFundMonths(accounts: accounts, monthlyExpenses: monthlyExpenses)
            ),
            cashFlowAnalysis: cashFlowAnalysis,
            spendingPatterns: spendingPatterns,
            accountPerformance: accountPerformance,
            riskProfile: riskProfile,
            investmentAnalysis: investmentAnalysis,
            goalProgress: goalProgress,
            predictiveInsights: predictiveInsights,
            recommendations: generateRecommendations(analysis: ComprehensiveAnalysis(
                keyMetrics: FinancialMetrics(netWorth: netWorth, totalAssets: totalAssets, totalDebt: totalDebt, monthlyIncome: monthlyIncome, monthlyExpenses: monthlyExpenses, savingsRate: savingsRate, debtToIncomeRatio: totalDebt / max(monthlyIncome, 1), emergencyFundMonths: calculateEmergencyFundMonths(accounts: accounts, monthlyExpenses: monthlyExpenses)),
                cashFlowAnalysis: cashFlowAnalysis,
                spendingPatterns: spendingPatterns,
                accountPerformance: accountPerformance,
                riskProfile: riskProfile,
                investmentAnalysis: investmentAnalysis,
                goalProgress: goalProgress,
                predictiveInsights: predictiveInsights,
                recommendations: []
            ))
        )
    }
    
    // MARK: - Transaction Search
    
    func searchTransactions(dataManager: RBCDataManager, query: ProcessedQuery) -> TransactionSearchResults {
        let allTransactions = dataManager.accounts.flatMap { $0.transactions }
        var filteredTransactions = allTransactions
        
        // Apply filters based on query entities
        for entity in query.entities {
            switch entity.type {
            case .amount:
                if let amount = Double(entity.value) {
                    filteredTransactions = filteredTransactions.filter { abs($0.amount - amount) < amount * 0.1 }
                }
            case .date:
                filteredTransactions = filterTransactionsByDate(filteredTransactions, dateEntity: entity)
            case .category:
                if let category = TransactionCategory(rawValue: entity.value.capitalized) {
                    filteredTransactions = filteredTransactions.filter { $0.category == category }
                }
            case .merchant:
                filteredTransactions = filteredTransactions.filter { 
                    $0.merchant?.localizedCaseInsensitiveContains(entity.value) == true ||
                    $0.description.localizedCaseInsensitiveContains(entity.value) == true
                }
            case .accountType:
                filteredTransactions = filterTransactionsByAccountType(filteredTransactions, accountType: entity.value)
            default:
                break
            }
        }
        
        // Sort by relevance (most recent first, then by amount)
        filteredTransactions.sort { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date > rhs.date
            }
            return abs(lhs.amount) > abs(rhs.amount)
        }
        
        // Group and summarize
        let summary = generateTransactionSummary(transactions: filteredTransactions)
        
        return TransactionSearchResults(
            transactions: Array(filteredTransactions.prefix(50)), // Limit to 50 most relevant
            totalCount: filteredTransactions.count,
            summary: summary,
            categories: extractCategoryBreakdown(transactions: filteredTransactions),
            timeDistribution: extractTimeDistribution(transactions: filteredTransactions)
        )
    }
    
    // MARK: - Budget Planning
    
    func createBudgetPlan(dataManager: RBCDataManager, query: ProcessedQuery, userPreferences: UserPreferences) -> BudgetPlan {
        let currentSpending = dataManager.getSpendingByCategory()
        let monthlyIncome = calculateMonthlyIncome(dataManager.accounts.flatMap { $0.transactions })
        
        // Analyze spending patterns
        let spendingAnalysis = analyzeSpendingPatterns(transactions: dataManager.accounts.flatMap { $0.transactions })
        
        // Generate optimized budget
        let optimizedBudget = budgetOptimizer.createOptimizedBudget(
            currentSpending: currentSpending,
            monthlyIncome: monthlyIncome,
            userPreferences: userPreferences,
            spendingAnalysis: spendingAnalysis
        )
        
        // Identify savings opportunities
        let savingsOpportunities = identifySavingsOpportunities(
            currentSpending: currentSpending,
            optimizedBudget: optimizedBudget,
            spendingAnalysis: spendingAnalysis
        )
        
        // Create action plan
        let actionPlan = createBudgetActionPlan(
            currentSpending: currentSpending,
            targetBudget: optimizedBudget,
            opportunities: savingsOpportunities
        )
        
        return BudgetPlan(
            currentSpending: currentSpending,
            recommendedBudget: optimizedBudget,
            savingsOpportunities: savingsOpportunities,
            actionPlan: actionPlan,
            projectedMonthlySavings: calculateProjectedSavings(current: currentSpending, target: optimizedBudget),
            implementationTimeline: createImplementationTimeline(actionPlan: actionPlan)
        )
    }
    
    // MARK: - Investment Advice
    
    func generateInvestmentAdvice(dataManager: RBCDataManager, query: ProcessedQuery, riskProfile: RiskProfile) -> InvestmentAdvice {
        let investmentAccounts = dataManager.accounts.filter { 
            $0.accountType == .investment || $0.accountType == .tfSA || $0.accountType == .rRSP 
        }
        
        let totalInvestableAssets = calculateInvestableAssets(accounts: investmentAccounts)
        let monthlyContributionCapacity = calculateMonthlyContributionCapacity(dataManager: dataManager)
        
        // Get market data and recommendations
        let marketData = marketDataProvider.getCurrentMarketData()
        let assetAllocation = generateAssetAllocation(
            riskProfile: riskProfile,
            investableAssets: totalInvestableAssets,
            age: calculateAge(dataManager.userProfile.memberSince),
            timeHorizon: extractTimeHorizon(from: query)
        )
        
        // Specific investment recommendations
        let recommendations = generateInvestmentRecommendations(
            assetAllocation: assetAllocation,
            marketData: marketData,
            riskProfile: riskProfile,
            investableAmount: totalInvestableAssets
        )
        
        // Risk analysis
        let riskAnalysis = riskCalculator.calculatePortfolioRisk(
            assetAllocation: assetAllocation,
            riskProfile: riskProfile
        )
        
        // Tax optimization strategies
        let taxStrategies = generateTaxEfficientStrategies(
            investmentAccounts: investmentAccounts,
            recommendations: recommendations
        )
        
        return InvestmentAdvice(
            currentPortfolio: analyzeCurrentPortfolio(accounts: investmentAccounts),
            recommendedAssetAllocation: assetAllocation,
            specificRecommendations: recommendations,
            riskAnalysis: riskAnalysis,
            taxStrategies: taxStrategies,
            expectedReturns: calculateExpectedReturns(assetAllocation: assetAllocation),
            contributionPlan: createContributionPlan(
                monthlyCapacity: monthlyContributionCapacity,
                assetAllocation: assetAllocation
            )
        )
    }
    
    // MARK: - Tax Optimization
    
    func generateTaxOptimization(dataManager: RBCDataManager, query: ProcessedQuery, userProfile: UserProfile) -> TaxOptimizationStrategies {
        let accounts = dataManager.accounts
        let transactions = accounts.flatMap { $0.transactions }
        
        // Analyze current tax situation
        let currentTaxSituation = analyzeCurrentTaxSituation(
            accounts: accounts,
            transactions: transactions,
            userProfile: userProfile
        )
        
        // Generate tax-efficient strategies
        let strategies = [
            TaxStrategy(
                type: .taxFreeSavings,
                title: "Maximize TFSA Contributions",
                description: "Contribute the maximum amount to your TFSA to grow investments tax-free",
                potentialSavings: calculateTFSASavings(accounts: accounts),
                implementationDifficulty: .low,
                priority: .high
            ),
            TaxStrategy(
                type: .retirementSavings,
                title: "Optimize RRSP Contributions",
                description: "Strategic RRSP contributions to reduce taxable income",
                potentialSavings: calculateRRSPSavings(accounts: accounts, userProfile: userProfile),
                implementationDifficulty: .medium,
                priority: .high
            ),
            TaxStrategy(
                type: .investmentLocation,
                title: "Tax-Efficient Investment Placement",
                description: "Place investments in the most tax-efficient accounts",
                potentialSavings: calculateInvestmentLocationSavings(accounts: accounts),
                implementationDifficulty: .medium,
                priority: .medium
            ),
            TaxStrategy(
                type: .deductionOptimization,
                title: "Maximize Deductions",
                description: "Identify and optimize all available tax deductions",
                potentialSavings: calculateDeductionSavings(transactions: transactions),
                implementationDifficulty: .low,
                priority: .medium
            )
        ]
        
        return TaxOptimizationStrategies(
            currentSituation: currentTaxSituation,
            strategies: strategies.sorted { $0.potentialSavings > $1.potentialSavings },
            totalPotentialSavings: strategies.reduce(0) { $0 + $1.potentialSavings },
            implementationRoadmap: createTaxImplementationRoadmap(strategies: strategies)
        )
    }
    
    // MARK: - Risk Assessment
    
    func performRiskAssessment(dataManager: RBCDataManager, query: ProcessedQuery) -> RiskAssessment {
        let accounts = dataManager.accounts
        let transactions = accounts.flatMap { $0.transactions }
        
        // Calculate various risk metrics
        let liquidityRisk = calculateLiquidityRisk(accounts: accounts, transactions: transactions)
        let creditRisk = calculateCreditRisk(accounts: accounts, transactions: transactions)
        let marketRisk = calculateMarketRisk(accounts: accounts)
        let concentrationRisk = calculateConcentrationRisk(accounts: accounts, transactions: transactions)
        let incomeRisk = calculateIncomeRisk(transactions: transactions)
        
        // Overall risk score
        let overallRiskScore = calculateOverallRiskScore(
            liquidity: liquidityRisk,
            credit: creditRisk,
            market: marketRisk,
            concentration: concentrationRisk,
            income: incomeRisk
        )
        
        // Risk factors and mitigation strategies
        let riskFactors = identifyRiskFactors(
            accounts: accounts,
            transactions: transactions,
            riskScores: [liquidityRisk, creditRisk, marketRisk, concentrationRisk, incomeRisk]
        )
        
        let mitigationStrategies = generateRiskMitigationStrategies(riskFactors: riskFactors)
        
        return RiskAssessment(
            overallRiskScore: overallRiskScore,
            riskCategories: [
                RiskCategory(name: "Liquidity Risk", score: liquidityRisk, description: "Ability to meet short-term obligations"),
                RiskCategory(name: "Credit Risk", score: creditRisk, description: "Risk of default on debt obligations"),
                RiskCategory(name: "Market Risk", score: marketRisk, description: "Risk from market fluctuations"),
                RiskCategory(name: "Concentration Risk", score: concentrationRisk, description: "Risk from lack of diversification"),
                RiskCategory(name: "Income Risk", score: incomeRisk, description: "Risk of income disruption")
            ],
            riskFactors: riskFactors,
            mitigationStrategies: mitigationStrategies,
            recommendedActions: generateRecommendedRiskActions(riskAssessment: RiskAssessment(
                overallRiskScore: overallRiskScore,
                riskCategories: [],
                riskFactors: riskFactors,
                mitigationStrategies: mitigationStrategies,
                recommendedActions: []
            ))
        )
    }
    
    // MARK: - Future Planning
    
    func generateFutureProjection(dataManager: RBCDataManager, query: ProcessedQuery, userPreferences: UserPreferences) -> FutureProjection {
        let currentData = FinancialDataSnapshot(
            netWorth: dataManager.getNetWorth(),
            monthlyIncome: calculateMonthlyIncome(dataManager.accounts.flatMap { $0.transactions }),
            monthlyExpenses: calculateMonthlyExpenses(dataManager.accounts.flatMap { $0.transactions }),
            savingsRate: calculateSavingsRate(
                monthlyIncome: calculateMonthlyIncome(dataManager.accounts.flatMap { $0.transactions }),
                monthlyExpenses: calculateMonthlyExpenses(dataManager.accounts.flatMap { $0.transactions })
            )
        )
        
        let timeHorizon = extractTimeHorizon(from: query)
        let scenarios = generateProjectionScenarios(
            currentData: currentData,
            timeHorizon: timeHorizon,
            userPreferences: userPreferences
        )
        
        let goalFeasibility = analyzeGoalFeasibility(
            goals: userPreferences.financialGoals,
            projections: scenarios,
            currentData: currentData
        )
        
        return FutureProjection(
            baselineProjection: scenarios.baseline,
            optimisticProjection: scenarios.optimistic,
            pessimisticProjection: scenarios.pessimistic,
            goalFeasibility: goalFeasibility,
            keyAssumptions: generateProjectionAssumptions(currentData: currentData),
            sensitivityAnalysis: performSensitivityAnalysis(scenarios: scenarios),
            recommendedAdjustments: generateRecommendedAdjustments(
                currentData: currentData,
                goalFeasibility: goalFeasibility
            )
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateMonthlyIncome(_ transactions: [Transaction]) -> Double {
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        let recentIncome = transactions
            .filter { $0.amount > 0 && $0.date >= threeMonthsAgo }
            .reduce(0) { $0 + $1.amount }
        
        return recentIncome / 3.0
    }
    
    private func calculateMonthlyExpenses(_ transactions: [Transaction]) -> Double {
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        let recentExpenses = transactions
            .filter { $0.amount < 0 && $0.date >= threeMonthsAgo }
            .reduce(0) { $0 + abs($1.amount) }
        
        return recentExpenses / 3.0
    }
    
    private func calculateSavingsRate(monthlyIncome: Double, monthlyExpenses: Double) -> Double {
        guard monthlyIncome > 0 else { return 0 }
        return max(0, (monthlyIncome - monthlyExpenses) / monthlyIncome)
    }
    
    private func calculateEmergencyFundMonths(accounts: [Account], monthlyExpenses: Double) -> Double {
        let liquidAssets = accounts
            .filter { $0.accountType == .chequing || $0.accountType == .savings }
            .reduce(0) { $0 + max(0, $1.balance) }
        
        guard monthlyExpenses > 0 else { return 0 }
        return liquidAssets / monthlyExpenses
    }
    
    private func analyzeCashFlow(transactions: [Transaction]) -> CashFlowAnalysis {
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        
        let recentTransactions = transactions.filter { $0.date >= sixMonthsAgo }
        
        var monthlyCashFlows: [String: Double] = [:]
        
        for transaction in recentTransactions {
            let monthKey = DateFormatter.monthYear.string(from: transaction.date)
            monthlyCashFlows[monthKey, default: 0] += transaction.amount
        }
        
        let cashFlowTrend = calculateCashFlowTrend(monthlyCashFlows: monthlyCashFlows)
        let volatility = calculateCashFlowVolatility(monthlyCashFlows: monthlyCashFlows)
        
        return CashFlowAnalysis(
            monthlyCashFlows: monthlyCashFlows,
            trend: cashFlowTrend,
            volatility: volatility,
            averageMonthlyCashFlow: monthlyCashFlows.values.reduce(0, +) / Double(monthlyCashFlows.count)
        )
    }
    
    private func analyzeSpendingPatterns(transactions: [Transaction]) -> SpendingPatterns {
        let spendingByCategory = transactions
            .filter { $0.amount < 0 }
            .reduce(into: [TransactionCategory: Double]()) { dict, transaction in
                dict[transaction.category, default: 0] += abs(transaction.amount)
            }
        
        let recurringExpenses = identifyRecurringExpenses(transactions: transactions)
        let seasonalPatterns = identifySeasonalPatterns(transactions: transactions)
        let unusualSpending = identifyUnusualSpending(transactions: transactions)
        
        return SpendingPatterns(
            spendingByCategory: spendingByCategory,
            recurringExpenses: recurringExpenses,
            seasonalPatterns: seasonalPatterns,
            unusualSpending: unusualSpending
        )
    }
    
    private func analyzeAccountPerformance(accounts: [Account]) -> AccountPerformance {
        var accountMetrics: [String: AccountMetrics] = [:]
        
        for account in accounts {
            let transactions = account.transactions
            let totalDeposits = transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
            let totalWithdrawals = abs(transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount })
            let transactionCount = transactions.count
            let averageTransaction = transactionCount > 0 ? (totalDeposits + totalWithdrawals) / Double(transactionCount) : 0
            
            accountMetrics[account.id] = AccountMetrics(
                totalDeposits: totalDeposits,
                totalWithdrawals: totalWithdrawals,
                netFlow: totalDeposits - totalWithdrawals,
                transactionCount: transactionCount,
                averageTransaction: averageTransaction,
                growthRate: calculateAccountGrowthRate(account: account)
            )
        }
        
        return AccountPerformance(accountMetrics: accountMetrics)
    }
    
    private func assessFinancialRisk(accounts: [Account], transactions: [Transaction], userPreferences: UserPreferences) -> RiskProfileAnalysis {
        let debtToIncomeRatio = calculateDebtToIncomeRatio(accounts: accounts, transactions: transactions)
        let emergencyFundAdequacy = calculateEmergencyFundAdequacy(accounts: accounts, transactions: transactions)
        let diversificationScore = calculateDiversificationScore(accounts: accounts)
        let incomeStability = calculateIncomeStability(transactions: transactions)
        
        return RiskProfileAnalysis(
            debtToIncomeRatio: debtToIncomeRatio,
            emergencyFundAdequacy: emergencyFundAdequacy,
            diversificationScore: diversificationScore,
            incomeStability: incomeStability,
            overallRiskLevel: determineOverallRiskLevel(
                debtToIncome: debtToIncomeRatio,
                emergencyFund: emergencyFundAdequacy,
                diversification: diversificationScore,
                incomeStability: incomeStability
            )
        )
    }
    
    private func analyzeInvestments(_ investmentAccounts: [Account]) -> InvestmentAnalysis {
        let totalInvestmentValue = investmentAccounts.reduce(0) { $0 + max(0, $1.balance) }
        let investmentTransactions = investmentAccounts.flatMap { $0.transactions }
        let totalContributions = investmentTransactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        let totalReturns = investmentTransactions.filter { $0.category == .deposit && $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        
        let rateOfReturn = totalContributions > 0 ? (totalReturns - totalContributions) / totalContributions : 0
        
        return InvestmentAnalysis(
            totalValue: totalInvestmentValue,
            totalContributions: totalContributions,
            totalReturns: totalReturns,
            rateOfReturn: rateOfReturn,
            assetDistribution: calculateAssetDistribution(accounts: investmentAccounts),
            performanceTrend: calculateInvestmentPerformanceTrend(transactions: investmentTransactions)
        )
    }
    
    private func analyzeGoalProgress(userPreferences: UserPreferences, currentNetWorth: Double) -> GoalProgressAnalysis {
        var goalProgress: [String: GoalProgress] = [:]
        
        for goal in userPreferences.financialGoals {
            let progress = calculateGoalProgress(goal: goal, currentNetWorth: currentNetWorth)
            goalProgress[goal.id] = progress
        }
        
        return GoalProgressAnalysis(
            goalProgress: goalProgress,
            overallProgress: calculateOverallGoalProgress(goalProgress: goalProgress),
            recommendedAdjustments: generateGoalAdjustments(goalProgress: goalProgress)
        )
    }
    
    private func generatePredictiveInsights(currentData: FinancialDataSnapshot, historicalTrends: HistoricalTrends) -> [PredictiveInsight] {
        var insights: [PredictiveInsight] = []
        
        // Net worth projection
        let netWorthProjection = projectionEngine.projectNetWorth(
            current: currentData.netWorth,
            monthlyGrowthRate: historicalTrends.netWorthGrowthRate,
            timeHorizon: 12 // months
        )
        
        insights.append(PredictiveInsight(
            type: .netWorthProjection,
            title: "Net Worth Projection",
            description: "Based on current trends, your net worth is projected to reach $\(String(format: "%.2f", netWorthProjection)) in 12 months",
            confidence: 0.75,
            timeframe: "12 months",
            actionable: true
        ))
        
        // Savings rate analysis
        if currentData.savingsRate < 0.2 {
            insights.append(PredictiveInsight(
                type: .savingsRateWarning,
                title: "Low Savings Rate",
                description: "Your current savings rate of \(String(format: "%.1f", currentData.savingsRate * 100))% is below the recommended 20%",
                confidence: 0.9,
                timeframe: "Immediate",
                actionable: true
            ))
        }
        
        // Income stability
        if historicalTrends.incomeVolatility > 0.3 {
            insights.append(PredictiveInsight(
                type: .incomeVolatility,
                title: "Income Volatility Detected",
                description: "Your income shows significant volatility. Consider building a larger emergency fund",
                confidence: 0.8,
                timeframe: "3-6 months",
                actionable: true
            ))
        }
        
        return insights
    }
    
    private func generateRecommendations(analysis: ComprehensiveAnalysis) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Emergency fund recommendation
        if analysis.keyMetrics.emergencyFundMonths < 3 {
            recommendations.append(Recommendation(
                type: .emergencyFund,
                title: "Build Emergency Fund",
                description: "Increase your emergency fund to cover 3-6 months of expenses",
                priority: .high,
                estimatedImpact: "High financial security",
                difficulty: .medium,
                timeframe: "6-12 months"
            ))
        }
        
        // Debt reduction
        if analysis.keyMetrics.debtToIncomeRatio > 0.4 {
            recommendations.append(Recommendation(
                type: .debtReduction,
                title: "Reduce High-Interest Debt",
                description: "Focus on paying down high-interest debt to improve your debt-to-income ratio",
                priority: .high,
                estimatedImpact: "Improved cash flow and credit score",
                difficulty: .high,
                timeframe: "12-24 months"
            ))
        }
        
        // Savings optimization
        if analysis.keyMetrics.savingsRate < 0.15 {
            recommendations.append(Recommendation(
                type: .savingsOptimization,
                title: "Increase Savings Rate",
                description: "Aim to save at least 15-20% of your monthly income",
                priority: .medium,
                estimatedImpact: "Faster wealth building",
                difficulty: .medium,
                timeframe: "3-6 months"
            ))
        }
        
        // Investment diversification
        if analysis.riskProfile.diversificationScore < 0.6 {
            recommendations.append(Recommendation(
                type: .diversification,
                title: "Diversify Investments",
                description: "Consider diversifying your investment portfolio to reduce risk",
                priority: .medium,
                estimatedImpact: "Reduced portfolio volatility",
                difficulty: .medium,
                timeframe: "6-12 months"
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // Additional helper methods would be implemented here...
    // Due to length constraints, I'm showing the main structure
}

// MARK: - Data Structures

struct ComprehensiveAnalysis {
    let keyMetrics: FinancialMetrics
    let cashFlowAnalysis: CashFlowAnalysis
    let spendingPatterns: SpendingPatterns
    let accountPerformance: AccountPerformance
    let riskProfile: RiskProfileAnalysis
    let investmentAnalysis: InvestmentAnalysis
    let goalProgress: GoalProgressAnalysis
    let predictiveInsights: [PredictiveInsight]
    let recommendations: [Recommendation]
}

struct FinancialMetrics {
    let netWorth: Double
    let totalAssets: Double
    let totalDebt: Double
    let monthlyIncome: Double
    let monthlyExpenses: Double
    let savingsRate: Double
    let debtToIncomeRatio: Double
    let emergencyFundMonths: Double
}

struct CashFlowAnalysis {
    let monthlyCashFlows: [String: Double]
    let trend: CashFlowTrend
    let volatility: Double
    let averageMonthlyCashFlow: Double
}

enum CashFlowTrend {
    case increasing, decreasing, stable
}

struct SpendingPatterns {
    let spendingByCategory: [TransactionCategory: Double]
    let recurringExpenses: [RecurringExpense]
    let seasonalPatterns: [SeasonalPattern]
    let unusualSpending: [UnusualSpending]
}

struct RecurringExpense {
    let description: String
    let averageAmount: Double
    let frequency: String
    let nextExpectedDate: Date
}

struct SeasonalPattern {
    let category: TransactionCategory
    let season: String
    let averageAmount: Double
    let variance: Double
}

struct UnusualSpending {
    let transaction: Transaction
    let reason: String
    let confidence: Double
}

struct AccountPerformance {
    let accountMetrics: [String: AccountMetrics]
}

struct AccountMetrics {
    let totalDeposits: Double
    let totalWithdrawals: Double
    let netFlow: Double
    let transactionCount: Int
    let averageTransaction: Double
    let growthRate: Double
}

struct RiskProfileAnalysis {
    let debtToIncomeRatio: Double
    let emergencyFundAdequacy: Double
    let diversificationScore: Double
    let incomeStability: Double
    let overallRiskLevel: RiskLevel
}

enum RiskLevel {
    case low, medium, high, veryHigh
}

struct InvestmentAnalysis {
    let totalValue: Double
    let totalContributions: Double
    let totalReturns: Double
    let rateOfReturn: Double
    let assetDistribution: [String: Double]
    let performanceTrend: PerformanceTrend
}

enum PerformanceTrend {
    case outperforming, underperforming, stable
}

struct GoalProgressAnalysis {
    let goalProgress: [String: GoalProgress]
    let overallProgress: Double
    let recommendedAdjustments: [GoalAdjustment]
}

struct GoalProgress {
    let goalId: String
    let currentProgress: Double
    let targetAmount: Double
    let timeRemaining: TimeInterval
    let onTrack: Bool
    let projectedCompletion: Date?
}

struct GoalAdjustment {
    let goalId: String
    let adjustmentType: AdjustmentType
    let description: String
    let impact: String
}

enum AdjustmentType {
    case increaseSavings, extendTimeline, reduceTarget, reallocateFunds
}

struct PredictiveInsight {
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let timeframe: String
    let actionable: Bool
}

enum InsightType {
    case netWorthProjection, savingsRateWarning, incomeVolatility, spendingAnomaly, investmentOpportunity
}

struct Recommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let priority: Priority
    let estimatedImpact: String
    let difficulty: Difficulty
    let timeframe: String
}

enum RecommendationType {
    case emergencyFund, debtReduction, savingsOptimization, diversification, taxOptimization
}

enum Priority: Int {
    case low = 1, medium = 2, high = 3, critical = 4
}

enum Difficulty {
    case easy, medium, hard
}

struct TransactionSearchResults {
    let transactions: [Transaction]
    let totalCount: Int
    let summary: TransactionSummary
    let categories: [TransactionCategory: Double]
    let timeDistribution: [String: Int]
}

struct TransactionSummary {
    let totalAmount: Double
    let averageAmount: Double
    let dateRange: (start: Date, end: Date)
    let topCategories: [(category: TransactionCategory, amount: Double)]
}

struct BudgetPlan {
    let currentSpending: [TransactionCategory: Double]
    let recommendedBudget: [TransactionCategory: Double]
    let savingsOpportunities: [SavingsOpportunity]
    let actionPlan: [BudgetAction]
    let projectedMonthlySavings: Double
    let implementationTimeline: [TimelineMilestone]
}

struct SavingsOpportunity {
    let category: TransactionCategory
    let currentSpending: Double
    let recommendedSpending: Double
    let potentialSavings: Double
    let difficulty: Difficulty
    let suggestions: [String]
}

struct BudgetAction {
    let category: TransactionCategory
    let action: String
    let timeline: String
    let expectedSavings: Double
}

struct TimelineMilestone {
    let date: Date
    let description: String
    let actions: [String]
}

struct InvestmentAdvice {
    let currentPortfolio: PortfolioAnalysis
    let recommendedAssetAllocation: AssetAllocation
    let specificRecommendations: [InvestmentRecommendation]
    let riskAnalysis: PortfolioRiskAnalysis
    let taxStrategies: [TaxStrategy]
    let expectedReturns: ExpectedReturns
    let contributionPlan: ContributionPlan
}

struct PortfolioAnalysis {
    let totalValue: Double
    let assetAllocation: [String: Double]
    let performance: PerformanceMetrics
}

struct AssetAllocation {
    let stocks: Double
    let bonds: Double
    let realEstate: Double
    let commodities: Double
    let cash: Double
}

struct InvestmentRecommendation {
    let symbol: String
    let name: String
    let type: InvestmentType
    let allocation: Double
    let expectedReturn: Double
    let risk: RiskLevel
    let rationale: String
}

enum InvestmentType {
    case stock, bond, etf, mutualFund, reit
}

struct PortfolioRiskAnalysis {
    let overallRisk: Double
    let volatility: Double
    let maxDrawdown: Double
    let sharpeRatio: Double
}

struct ExpectedReturns {
    let annualReturn: Double
    let fiveYearReturn: Double
    let tenYearReturn: Double
    let confidence: Double
}

struct ContributionPlan {
    let monthlyAmount: Double
    let allocation: [String: Double]
    let schedule: ContributionSchedule
}

struct ContributionSchedule {
    let frequency: String
    let nextContribution: Date
    let autoIncrease: Bool
}

struct TaxOptimizationStrategies {
    let currentSituation: CurrentTaxSituation
    let strategies: [TaxStrategy]
    let totalPotentialSavings: Double
    let implementationRoadmap: [TaxRoadmapStep]
}

struct CurrentTaxSituation {
    let estimatedTaxBracket: String
    let currentDeductions: Double
    let taxEfficiency: Double
}

struct TaxStrategy {
    let type: TaxStrategyType
    let title: String
    let description: String
    let potentialSavings: Double
    let implementationDifficulty: Difficulty
    let priority: Priority
}

enum TaxStrategyType {
    case taxFreeSavings, retirementSavings, investmentLocation, deductionOptimization
}

struct TaxRoadmapStep {
    let order: Int
    let strategy: TaxStrategy
    let timeline: String
    let dependencies: [String]
}

struct RiskAssessment {
    let overallRiskScore: Double
    let riskCategories: [RiskCategory]
    let riskFactors: [RiskFactor]
    let mitigationStrategies: [MitigationStrategy]
    let recommendedActions: [RiskAction]
}

struct RiskCategory {
    let name: String
    let score: Double
    let description: String
}

struct RiskFactor {
    let type: String
    let severity: RiskLevel
    let description: String
    let impact: String
}

struct MitigationStrategy {
    let riskFactor: String
    let strategy: String
    let effectiveness: Double
    let cost: String
    let timeline: String
}

struct RiskAction {
    let priority: Priority
    let action: String
    let timeline: String
    let resources: [String]
}

struct FutureProjection {
    let baselineProjection: ProjectionScenario
    let optimisticProjection: ProjectionScenario
    let pessimisticProjection: ProjectionScenario
    let goalFeasibility: [String: GoalFeasibility]
    let keyAssumptions: [ProjectionAssumption]
    let sensitivityAnalysis: SensitivityAnalysis
    let recommendedAdjustments: [ProjectionAdjustment]
}

struct ProjectionScenario {
    let name: String
    let timeHorizon: TimeInterval
    let projections: [TimePointProjection]
    let confidence: Double
}

struct TimePointProjection {
    let date: Date
    let netWorth: Double
    let income: Double
    let expenses: Double
    let savings: Double
}

struct GoalFeasibility {
    let goalId: String
    let achievable: Bool
    let probability: Double
    let timelineAdjustment: TimeInterval?
    let amountAdjustment: Double?
}

struct ProjectionAssumption {
    let parameter: String
    let value: Double
    let rationale: String
    let sensitivity: Double
}

struct SensitivityAnalysis {
    let parameters: [String: [SensitivityResult]]
}

struct SensitivityResult {
    let parameterValue: Double
    let outcome: Double
    let impact: Double
}

struct ProjectionAdjustment {
    let type: AdjustmentType
    let description: String
    let impact: String
    let difficulty: Difficulty
}

// Additional supporting classes and extensions would continue here...
// This is a comprehensive foundation for the financial analysis system
