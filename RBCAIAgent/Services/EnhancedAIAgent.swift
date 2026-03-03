import Foundation
import SwiftUI
import Combine

class EnhancedAIAgent: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var conversationContext = ConversationContext()
    @Published var userPreferences = UserPreferences()
    
    private let dataManager: RBCDataManager
    private let nlpProcessor = NLPProcessor()
    private let financialAnalyzer = FinancialAnalyzer()
    private let insightEngine = InsightEngine()
    private let responseGenerator = ResponseGenerator()
    
    // Conversation memory
    private var shortTermMemory: [ConversationTurn] = []
    private var longTermMemory: LongTermMemory = LongTermMemory()
    
    // User behavior tracking
    private var behaviorTracker = UserBehaviorTracker()
    
    init(dataManager: RBCDataManager) {
        self.dataManager = dataManager
        loadUserPreferences()
        addWelcomeMessage()
        initializeFinancialKnowledge()
    }
    
    private func loadUserPreferences() {
        // Load saved preferences or use defaults
        userPreferences = UserPreferences.loadOrDefault()
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            id: UUID().uuidString,
            content: generatePersonalizedWelcome(),
            isFromUser: false,
            timestamp: Date(),
            messageType: .welcome,
            confidence: 1.0
        )
        messages.append(welcomeMessage)
    }
    
    private func generatePersonalizedWelcome() -> String {
        let userName = dataManager.userProfile.preferredName ?? dataManager.userProfile.name
        let netWorth = dataManager.getNetWorth()
        let timeOfDay = getTimeOfDay()
        let recentInsights = dataManager.insights.filter { $0.actionable && $0.date >= Date().addingTimeInterval(-7*24*3600) }
        
        var welcome = "Good \(timeOfDay), \(userName)! 👋\n\n"
        welcome += "I'm your RBC AI financial assistant. I've analyzed your complete financial profile and I'm ready to help you optimize your financial health.\n\n"
        
        // Personalized overview
        welcome += "📊 **Your Financial Snapshot:**\n"
        welcome += "• Net Worth: $\(String(format: "%.2f", netWorth))\n"
        welcome += "• Total Accounts: \(dataManager.accounts.count)\n"
        welcome += "• Active Insights: \(recentInsights.count)\n\n"
        
        // Contextual suggestions based on current financial situation
        if netWorth < 0 {
            welcome += "💡 **Priority Focus:** Let's work on improving your net worth through debt reduction and savings strategies.\n\n"
        } else if netWorth < 10000 {
            welcome += "💡 **Growth Opportunity:** You're on the right track! Let's focus on accelerating your wealth building.\n\n"
        } else {
            welcome += "💡 **Optimization:** Great financial foundation! Let's explore investment and tax optimization strategies.\n\n"
        }
        
        welcome += "I can help you with:\n"
        welcome += "🎯 **Deep Analysis:** Spending patterns, investment opportunities, tax optimization\n"
        welcome += "🤖 **Smart Planning:** Budget recommendations, savings goals, retirement planning\n"
        welcome += "📈 **Predictive Insights:** Future cash flow, investment projections, risk assessment\n"
        welcome += "🔍 **Transaction Intelligence:** Categorization, anomaly detection, recurring payments\n"
        welcome += "💬 **Natural Conversation:** Ask me anything in plain language - I understand context!\n\n"
        
        welcome += "What would you like to explore today? You can ask complex questions like:\n"
        welcome += "• \"How can I optimize my tax strategy for my $\(String(format: "%.0f", netWorth)) net worth?\"\n"
        welcome += "• \"What's my ideal emergency fund based on my spending patterns?\"\n"
        welcome += "• \"Show me investments that match my risk profile\"\n\n"
        
        welcome += "I'm learning from our conversations to provide increasingly personalized advice. Let's start! 🚀"
        
        return welcome
    }
    
    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "night"
        }
    }
    
    func sendMessage(_ userInput: String) {
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: userInput,
            isFromUser: true,
            timestamp: Date(),
            messageType: .userQuery,
            confidence: 1.0
        )
        messages.append(userMessage)
        
        // Track user behavior
        behaviorTracker.recordQuery(userInput, timestamp: Date())
        
        isTyping = true
        
        // Process with sophisticated NLP pipeline
        DispatchQueue.global(qos: .userInitiated).async {
            let processedQuery = self.nlpProcessor.processQuery(userInput, context: self.conversationContext)
            let response = self.generateAdvancedResponse(for: processedQuery)
            
            DispatchQueue.main.async {
                let aiMessage = ChatMessage(
                    id: UUID().uuidString,
                    content: response.text,
                    isFromUser: false,
                    timestamp: Date(),
                    messageType: response.type,
                    confidence: response.confidence,
                    relatedData: response.relatedData,
                    followUpQuestions: response.followUpQuestions
                )
                self.messages.append(aiMessage)
                self.isTyping = false
                
                // Update conversation context
                self.conversationContext.addTurn(userInput: userInput, agentResponse: response.text)
                
                // Learn from interaction
                self.longTermMemory.recordInteraction(query: userInput, response: response.text, satisfaction: nil)
            }
        }
    }
    
    private func generateAdvancedResponse(for processedQuery: ProcessedQuery) -> AIResponse {
        // Route to appropriate specialized handler
        switch processedQuery.intent {
        case .financialAnalysis:
            return handleFinancialAnalysis(processedQuery)
        case .transactionQuery:
            return handleTransactionQuery(processedQuery)
        case .budgetPlanning:
            return handleBudgetPlanning(processedQuery)
        case .investmentAdvice:
            return handleInvestmentAdvice(processedQuery)
        case .taxOptimization:
            return handleTaxOptimization(processedQuery)
        case .riskAssessment:
            return handleRiskAssessment(processedQuery)
        case .futurePlanning:
            return handleFuturePlanning(processedQuery)
        case .generalQuery:
            return handleGeneralQuery(processedQuery)
        }
    }
    
    private func handleFinancialAnalysis(_ query: ProcessedQuery) -> AIResponse {
        let analysis = financialAnalyzer.performComprehensiveAnalysis(
            dataManager: dataManager,
            query: query,
            userPreferences: userPreferences
        )
        
        let response = responseGenerator.generateFinancialAnalysisResponse(
            analysis: analysis,
            query: query,
            userProfile: dataManager.userProfile
        )
        
        return AIResponse(
            text: response.text,
            type: .financialAnalysis,
            confidence: response.confidence,
            relatedData: analysis.keyMetrics,
            followUpQuestions: response.suggestedFollowUps
        )
    }
    
    private func handleTransactionQuery(_ query: ProcessedQuery) -> AIResponse {
        let transactionResults = financialAnalyzer.searchTransactions(
            dataManager: dataManager,
            query: query
        )
        
        let response = responseGenerator.generateTransactionResponse(
            results: transactionResults,
            query: query
        )
        
        return AIResponse(
            text: response.text,
            type: .transactionResult,
            confidence: response.confidence,
            relatedData: transactionResults.transactions,
            followUpQuestions: response.suggestedFollowUps
        )
    }
    
    private func handleBudgetPlanning(_ query: ProcessedQuery) -> AIResponse {
        let budgetPlan = financialAnalyzer.createBudgetPlan(
            dataManager: dataManager,
            query: query,
            userPreferences: userPreferences
        )
        
        let response = responseGenerator.generateBudgetResponse(
            plan: budgetPlan,
            query: query
        )
        
        return AIResponse(
            text: response.text,
            type: .budgetRecommendation,
            confidence: response.confidence,
            relatedData: budgetPlan,
            followUpQuestions: response.suggestedFollowUps
        )
    }
    
    private func handleInvestmentAdvice(_ query: ProcessedQuery) -> AIResponse {
        let investmentAdvice = financialAnalyzer.generateInvestmentAdvice(
            dataManager: dataManager,
            query: query,
            riskProfile: userPreferences.riskProfile
        )
        
        let response = responseGenerator.generateInvestmentResponse(
            advice: investmentAdvice,
            query: query
        )
        
        return AIResponse(
            text: response.text,
            type: .investmentAdvice,
            confidence: response.confidence,
            relatedData: investmentAdvice,
            followUpQuestions: response.suggestedFollowUps
        )
    }
    
    private func handleTaxOptimization(_ query: ProcessedQuery) -> AIResponse {
        let taxStrategies = financialAnalyzer.generateTaxOptimization(
            dataManager: dataManager,
            query: query,
            userProfile: dataManager.userProfile
        )
        
        let response = responseGenerator.generateTaxResponse(
            strategies: taxStrategies,
            query: query
        )
        
        return AIResponse(
            text: response.text,
            type: .taxAdvice,
            confidence: response.confidence,
            relatedData: taxStrategies,
            followUpQuestions: response.suggestedFollowUps
        )
    }
    
    private func handleRiskAssessment(_ query: ProcessedQuery) -> AIResponse {
        let riskAnalysis = financialAnalyzer.performRiskAssessment(
            dataManager: dataManager,
            query: query
        )
        
        let response = responseGenerator.generateRiskResponse(
            analysis: riskAnalysis,
            query: query
        )
        
        return AIResponse(
            text: response.text,
            type: .riskAssessment,
            confidence: response.confidence,
            relatedData: riskAnalysis,
            followUpQuestions: response.suggestedFollowUps
        )
    }
    
    private func handleFuturePlanning(_ query: ProcessedQuery) -> AIResponse {
        let futureProjection = financialAnalyzer.generateFutureProjection(
            dataManager: dataManager,
            query: query,
            userPreferences: userPreferences
        )
        
        let response = responseGenerator.generateFuturePlanningResponse(
            projection: futureProjection,
            query: query
        )
        
        return AIResponse(
            text: response.text,
            type: .futureProjection,
            confidence: response.confidence,
            relatedData: futureProjection,
            followUpQuestions: response.suggestedFollowUps
        )
    }
    
    private func handleGeneralQuery(_ query: ProcessedQuery) -> AIResponse {
        let response = responseGenerator.generateGeneralResponse(
            query: query,
            context: conversationContext,
            userProfile: dataManager.userProfile
        )
        
        return AIResponse(
            text: response.text,
            type: .general,
            confidence: response.confidence,
            followUpQuestions: response.suggestedFollowUps
        )
    }
    
    private func initializeFinancialKnowledge() {
        // Initialize extensive financial knowledge base
        insightEngine.loadFinancialKnowledgeBase()
        financialAnalyzer.initializeMarketData()
        responseGenerator.loadResponseTemplates()
    }
    
    // MARK: - Advanced Features
    
    func generateProactiveInsights() {
        let insights = insightEngine.generateProactiveInsights(
            dataManager: dataManager,
            userBehavior: behaviorTracker,
            conversationHistory: conversationContext
        )
        
        for insight in insights {
            let message = ChatMessage(
                id: UUID().uuidString,
                content: insight.content,
                isFromUser: false,
                timestamp: Date(),
                messageType: .proactiveInsight,
                confidence: insight.confidence,
                relatedData: insight.data
            )
            messages.append(message)
        }
    }
    
    func updateUserFeedback(messageId: String, feedback: UserFeedback) {
        longTermMemory.recordFeedback(messageId: messageId, feedback: feedback)
        behaviorTracker.recordFeedback(feedback)
        
        // Adjust future responses based on feedback
        if feedback.type == .helpful {
            responseGenerator.reinforceResponsePattern(for: feedback.queryType)
        } else if feedback.type == .notHelpful {
            responseGenerator.adjustResponsePattern(for: feedback.queryType, reason: feedback.reason)
        }
    }
    
    func exportConversationHistory() -> ConversationExport {
        return ConversationExport(
            messages: messages,
            context: conversationContext,
            insights: dataManager.insights,
            userProfile: dataManager.userProfile,
            exportDate: Date()
        )
    }
}

// MARK: - Supporting Data Structures

struct ProcessedQuery {
    let originalText: String
    let intent: QueryIntent
    let entities: [QueryEntity]
    let sentiment: SentimentAnalysis
    let urgency: UrgencyLevel
    let complexity: ComplexityLevel
    let context: [String: Any]
}

enum QueryIntent {
    case financialAnalysis
    case transactionQuery
    case budgetPlanning
    case investmentAdvice
    case taxOptimization
    case riskAssessment
    case futurePlanning
    case generalQuery
}

struct QueryEntity {
    let type: EntityType
    let value: String
    let confidence: Double
    let startIndex: Int
    let endIndex: Int
}

enum EntityType {
    case accountType, amount, date, category, merchant, timeframe, riskLevel, goal
}

struct SentimentAnalysis {
    let polarity: Double // -1 to 1
    let subjectivity: Double // 0 to 1
    let emotions: [Emotion]
}

struct Emotion {
    let type: String
    let intensity: Double
}

enum UrgencyLevel {
    case low, medium, high, critical
}

enum ComplexityLevel {
    case simple, moderate, complex, expert
}

struct AIResponse {
    let text: String
    let type: MessageType
    let confidence: Double
    let relatedData: Any?
    let followUpQuestions: [String]
}

struct ConversationContext {
    private var turns: [ConversationTurn] = []
    private var currentTopics: [String] = []
    private var userGoals: [UserGoal] = []
    
    mutating func addTurn(userInput: String, agentResponse: String) {
        let turn = ConversationTurn(userInput: userInput, agentResponse: String, timestamp: Date())
        turns.append(turn)
        
        // Keep only last 10 turns in active context
        if turns.count > 10 {
            turns.removeFirst()
        }
        
        updateTopics(from: userInput)
    }
    
    private mutating func updateTopics(from text: String) {
        // Extract and update current topics
        // This would use NLP to identify financial topics
    }
}

struct ConversationTurn {
    let userInput: String
    let agentResponse: String
    let timestamp: Date
}

struct UserGoal {
    let id: String
    let description: String
    let targetAmount: Double?
    let targetDate: Date?
    let priority: GoalPriority
    let category: GoalCategory
}

enum GoalPriority {
    case low, medium, high, critical
}

enum GoalCategory {
    case savings, investment, debtReduction, retirement, education, housing
}

struct UserPreferences {
    var riskProfile: RiskProfile = .moderate
    var communicationStyle: CommunicationStyle = .professional
    var detailLevel: DetailLevel = .comprehensive
    var notificationFrequency: NotificationFrequency = .daily
    var preferredCategories: [TransactionCategory] = []
    var financialGoals: [UserGoal] = []
    var privacySettings: PrivacySettings = PrivacySettings()
    
    static func loadOrDefault() -> UserPreferences {
        // Load from UserDefaults or return defaults
        return UserPreferences()
    }
}

enum RiskProfile {
    case conservative, moderate, aggressive, veryAggressive
}

enum CommunicationStyle {
    case casual, professional, educational, motivational
}

enum DetailLevel {
    case summary, moderate, comprehensive, expert
}

enum NotificationFrequency {
    case never, weekly, daily, realTime
}

struct LongTermMemory {
    private var interactions: [StoredInteraction] = []
    private var userPatterns: UserBehaviorPatterns = UserBehaviorPatterns()
    private var successfulResponses: [String: Int] = [:]
    
    mutating func recordInteraction(query: String, response: String, satisfaction: Double?) {
        let interaction = StoredInteraction(
            query: query,
            response: response,
            timestamp: Date(),
            satisfaction: satisfaction
        )
        interactions.append(interaction)
        
        // Update patterns
        updateUserPatterns(query: query, response: response, satisfaction: satisfaction)
    }
    
    mutating func recordFeedback(messageId: String, feedback: UserFeedback) {
        // Store feedback for learning
    }
    
    private mutating func updateUserPatterns(query: String, response: String, satisfaction: Double?) {
        // Analyze patterns and update user model
    }
}

struct StoredInteraction {
    let query: String
    let response: String
    let timestamp: Date
    let satisfaction: Double?
}

struct UserBehaviorPatterns {
    var preferredQueryTypes: [QueryIntent] = []
    var activeHours: [Int] = []
    var commonTopics: [String] = []
    var responsePreferences: [String: Double] = [:]
}

class UserBehaviorTracker {
    private var queryHistory: [QueryRecord] = []
    private var feedbackHistory: [UserFeedback] = []
    private var sessionMetrics: SessionMetrics = SessionMetrics()
    
    func recordQuery(_ query: String, timestamp: Date) {
        let record = QueryRecord(query: query, timestamp: timestamp)
        queryHistory.append(record)
        sessionMetrics.totalQueries += 1
    }
    
    func recordFeedback(_ feedback: UserFeedback) {
        feedbackHistory.append(feedback)
        sessionMetrics.updateWithFeedback(feedback)
    }
    
    func getBehaviorInsights() -> BehaviorInsights {
        return BehaviorInsights(
            mostActiveHour: calculateMostActiveHour(),
            preferredTopics: calculatePreferredTopics(),
            averageSessionLength: calculateAverageSessionLength(),
            satisfactionRate: calculateSatisfactionRate()
        )
    }
    
    private func calculateMostActiveHour() -> Int {
        // Implementation
        return 14 // Default to 2 PM
    }
    
    private func calculatePreferredTopics() -> [String] {
        // Implementation
        return ["budget", "savings", "investments"]
    }
    
    private func calculateAverageSessionLength() -> TimeInterval {
        // Implementation
        return 300 // 5 minutes
    }
    
    private func calculateSatisfactionRate() -> Double {
        // Implementation
        return 0.85 // 85%
    }
}

struct QueryRecord {
    let query: String
    let timestamp: Date
}

struct UserFeedback {
    let messageId: String
    let type: FeedbackType
    let reason: String?
    let queryType: QueryIntent
    let timestamp: Date
}

enum FeedbackType {
    case helpful, notHelpful, neutral
}

struct SessionMetrics {
    var totalQueries: Int = 0
    var averageResponseTime: TimeInterval = 0
    var satisfactionScore: Double = 0
    var topicsDiscussed: [String] = []
    
    mutating func updateWithFeedback(_ feedback: UserFeedback) {
        // Update metrics based on feedback
    }
}

struct BehaviorInsights {
    let mostActiveHour: Int
    let preferredTopics: [String]
    let averageSessionLength: TimeInterval
    let satisfactionRate: Double
}

struct ConversationExport {
    let messages: [ChatMessage]
    let context: ConversationContext
    let insights: [AccountInsight]
    let userProfile: UserProfile
    let exportDate: Date
}

// Enhanced ChatMessage with more metadata
struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let messageType: MessageType
    let confidence: Double
    let relatedData: Any?
    let followUpQuestions: [String]
    
    init(id: String, content: String, isFromUser: Bool, timestamp: Date, 
         messageType: MessageType = .general, confidence: Double = 1.0,
         relatedData: Any? = nil, followUpQuestions: [String] = []) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.messageType = messageType
        self.confidence = confidence
        self.relatedData = relatedData
        self.followUpQuestions = followUpQuestions
    }
}

enum MessageType {
    case welcome, userQuery, financialAnalysis, transactionResult, budgetRecommendation
    case investmentAdvice, taxAdvice, riskAssessment, futureProjection, proactiveInsight, general
}
