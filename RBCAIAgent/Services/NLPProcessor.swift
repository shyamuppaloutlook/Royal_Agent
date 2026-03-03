import Foundation
import NaturalLanguage

class NLPProcessor {
    private let tokenizer = NLTokenizer(unit: .word)
    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .sentimentScore])
    private let entityRecognizer = NLEntityRecognizer()
    
    // Financial vocabulary and patterns
    private let financialVocabulary = FinancialVocabulary()
    private let intentPatterns = IntentPatterns()
    private let contextAnalyzer = ContextAnalyzer()
    
    func processQuery(_ text: String, context: ConversationContext) -> ProcessedQuery {
        // Step 1: Basic tokenization and cleaning
        let cleanedText = cleanAndNormalize(text)
        
        // Step 2: Intent classification
        let intent = classifyIntent(cleanedText, context: context)
        
        // Step 3: Entity extraction
        let entities = extractEntities(cleanedText)
        
        // Step 4: Sentiment analysis
        let sentiment = analyzeSentiment(cleanedText)
        
        // Step 5: Urgency detection
        let urgency = detectUrgency(cleanedText, sentiment: sentiment)
        
        // Step 6: Complexity assessment
        let complexity = assessComplexity(cleanedText, entities: entities)
        
        // Step 7: Context extraction
        let contextData = extractContext(cleanedText, entities: entities, conversationContext: context)
        
        return ProcessedQuery(
            originalText: text,
            intent: intent,
            entities: entities,
            sentiment: sentiment,
            urgency: urgency,
            complexity: complexity,
            context: contextData
        )
    }
    
    private func cleanAndNormalize(_ text: String) -> String {
        var cleaned = text.lowercased()
        
        // Remove extra whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Expand common contractions
        cleaned = expandContractions(cleaned)
        
        // Normalize financial terms
        cleaned = normalizeFinancialTerms(cleaned)
        
        return cleaned
    }
    
    private func expandContractions(_ text: String) -> String {
        let contractions: [String: String] = [
            "don't": "do not",
            "won't": "will not",
            "can't": "cannot",
            "i'm": "i am",
            "it's": "it is",
            "that's": "that is",
            "what's": "what is",
            "how's": "how is",
            "when's": "when is",
            "where's": "where is",
            "why's": "why is",
            "who's": "who is",
            "i've": "i have",
            "you've": "you have",
            "we've": "we have",
            "they've": "they have",
            "i'll": "i will",
            "you'll": "you will",
            "we'll": "we will",
            "they'll": "they will",
            "i'd": "i would",
            "you'd": "you would",
            "we'd": "we would",
            "they'd": "they would"
        ]
        
        var expanded = text
        for (contraction, expansion) in contractions {
            expanded = expanded.replacingOccurrences(of: "\\b\(contraction)\\b", with: expansion, options: .regularExpression)
        }
        return expanded
    }
    
    private func normalizeFinancialTerms(_ text: String) -> String {
        let normalizations: [String: String] = [
            // Currency terms
            "\\$\\s*(\\d+)": "$1",
            "(\\d+)\\s*dollars?": "$1",
            "(\\d+)\\s*bucks?": "$1",
            
            // Time expressions
            "last month": "previous month",
            "this month": "current month",
            "next month": "following month",
            "last week": "previous week",
            "this week": "current week",
            "next week": "following week",
            "last year": "previous year",
            "this year": "current year",
            "next year": "following year",
            
            // Account types
            "checking": "chequing",
            "savings account": "savings",
            "credit card": "creditcard",
            "visa": "creditcard",
            "mastercard": "creditcard",
            "tfsa": "tax free savings",
            "rrsp": "registered retirement savings",
            
            // Transaction categories
            "restaurant": "dining",
            "restaurants": "dining",
            "food": "groceries",
            "grocery": "groceries",
            "gas": "transportation",
            "gasoline": "transportation",
            "fuel": "transportation",
            "uber": "transportation",
            "taxi": "transportation",
            "movies": "entertainment",
            "netflix": "entertainment",
            "spotify": "entertainment",
            "subscription": "bills",
            "utilities": "bills",
            "hydro": "bills",
            "internet": "bills",
            "phone": "bills",
            "rent": "bills",
            "mortgage": "bills"
        ]
        
        var normalized = text
        for (pattern, replacement) in normalizations {
            normalized = normalized.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        return normalized
    }
    
    private func classifyIntent(_ text: String, context: ConversationContext) -> QueryIntent {
        // Use pattern matching and machine learning for intent classification
        
        // Financial Analysis Intent
        if matchesFinancialAnalysisPatterns(text) {
            return .financialAnalysis
        }
        
        // Transaction Query Intent
        if matchesTransactionPatterns(text) {
            return .transactionQuery
        }
        
        // Budget Planning Intent
        if matchesBudgetPatterns(text) {
            return .budgetPlanning
        }
        
        // Investment Advice Intent
        if matchesInvestmentPatterns(text) {
            return .investmentAdvice
        }
        
        // Tax Optimization Intent
        if matchesTaxPatterns(text) {
            return .taxOptimization
        }
        
        // Risk Assessment Intent
        if matchesRiskPatterns(text) {
            return .riskAssessment
        }
        
        // Future Planning Intent
        if matchesFuturePlanningPatterns(text) {
            return .futurePlanning
        }
        
        return .generalQuery
    }
    
    private func matchesFinancialAnalysisPatterns(_ text: String) -> Bool {
        let patterns = [
            "\\b(analyze|analysis|review|summary|overview|breakdown)\\b.*\\b(financial|spending|expenses|income|budget)\\b",
            "\\b(how much|what is|show me|tell me)\\b.*\\b(spending|expenses|income|cash flow)\\b",
            "\\b(financial health|financial situation|money management|wealth)\\b",
            "\\b(net worth|total assets|total debt|financial position)\\b",
            "\\b(spending pattern|expense pattern|financial pattern)\\b"
        ]
        
        return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }
    
    private func matchesTransactionPatterns(_ text: String) -> Bool {
        let patterns = [
            "\\b(transaction|purchase|payment|charge|debit|credit)\\b",
            "\\b(show me|find|search|look for|what was)\\b.*\\b(transaction|purchase|payment)\\b",
            "\\b(recent|latest|yesterday|last week|last month)\\b.*\\b(spent|paid|bought)\\b",
            "\\b(how much|what)\\b.*\\b(cost|charge|pay)\\b",
            "\\b(merchant|store|restaurant|company)\\b.*\\b(transaction|purchase)\\b"
        ]
        
        return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }
    
    private func matchesBudgetPatterns(_ text: String) -> Bool {
        let patterns = [
            "\\b(budget|budgeting|budget plan|budget advice)\\b",
            "\\b(create|make|set up|plan)\\b.*\\b(budget)\\b",
            "\\b(how much should i|recommend|suggest)\\b.*\\b(budget|spend)\\b",
            "\\b(budget category|budget limit|spending limit)\\b",
            "\\b(save money|reduce expenses|cut costs)\\b",
            "\\b(monthly budget|weekly budget|daily budget)\\b"
        ]
        
        return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }
    
    private func matchesInvestmentPatterns(_ text: String) -> Bool {
        let patterns = [
            "\\b(invest|investment|investing|portfolio)\\b",
            "\\b(stock|bond|etf|mutual fund|index fund)\\b",
            "\\b(where should i|how should i|recommend)\\b.*\\b(invest)\\b",
            "\\b(risk tolerance|risk profile|investment risk)\\b",
            "\\b(diversification|asset allocation|rebalancing)\\b",
            "\\b(retirement|rrsp|tfsa|401k)\\b.*\\b(invest)\\b",
            "\\b(long term|short term)\\b.*\\b(investment)\\b"
        ]
        
        return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }
    
    private func matchesTaxPatterns(_ text: String) -> Bool {
        let patterns = [
            "\\b(tax|taxes|taxation|tax planning)\\b",
            "\\b(tax deduction|tax credit|tax saving)\\b",
            "\\b(how to reduce|optimize|minimize)\\b.*\\b(tax)\\b",
            "\\b(income tax|capital gains tax|property tax)\\b",
            "\\b(tax return|tax refund|tax filing)\\b",
            "\\b(tax efficient|tax optimization)\\b"
        ]
        
        return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }
    
    private func matchesRiskPatterns(_ text: String) -> Bool {
        let patterns = [
            "\\b(risk|risky|risk assessment|risk management)\\b",
            "\\b(financial risk|investment risk|market risk)\\b",
            "\\b(how risky|what is the risk|risk level)\\b",
            "\\b(conservative|aggressive|moderate)\\b.*\\b(risk)\\b",
            "\\b(risk tolerance|risk capacity)\\b",
            "\\b(emergency fund|financial security)\\b"
        ]
        
        return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }
    
    private func matchesFuturePlanningPatterns(_ text: String) -> Bool {
        let patterns = [
            "\\b(future|planning|forecast|projection)\\b",
            "\\b(next year|in 5 years|in 10 years|retirement)\\b",
            "\\b(financial goals|future goals|life goals)\\b",
            "\\b(save for|plan for|prepare for)\\b",
            "\\b(house|home|car|education|wedding|vacation)\\b.*\\b(save|plan)\\b",
            "\\b(early retirement|financial independence|fire)\\b"
        ]
        
        return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }
    
    private func extractEntities(_ text: String) -> [QueryEntity] {
        var entities: [QueryEntity] = []
        
        // Extract monetary amounts
        entities.append(contentsOf: extractMonetaryEntities(text))
        
        // Extract dates and timeframes
        entities.append(contentsOf: extractDateEntities(text))
        
        // Extract account types
        entities.append(contentsOf: extractAccountEntities(text))
        
        // Extract transaction categories
        entities.append(contentsOf: extractCategoryEntities(text))
        
        // Extract merchants
        entities.append(contentsOf: extractMerchantEntities(text))
        
        // Extract risk levels
        entities.append(contentsOf: extractRiskEntities(text))
        
        return entities
    }
    
    private func extractMonetaryEntities(_ text: String) -> [QueryEntity] {
        var entities: [QueryEntity] = []
        
        // Pattern for monetary amounts
        let amountPattern = "\\$?(\\d+(?:,\\d{3})*(?:\\.\\d{2})?)\\s*(dollars?|bucks?|cad|usd)?"
        
        let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let match = match,
               let valueRange = Range(match.range(at: 1), in: text) {
                let value = String(text[valueRange])
                let confidence = calculateEntityConfidence(for: value, type: .amount)
                
                entities.append(QueryEntity(
                    type: .amount,
                    value: value,
                    confidence: confidence,
                    startIndex: match.range.location,
                    endIndex: match.range.location + match.range.length
                ))
            }
        }
        
        return entities
    }
    
    private func extractDateEntities(_ text: String) -> [QueryEntity] {
        var entities: [QueryEntity] = []
        
        // Common date patterns
        let datePatterns = [
            "\\b(today|yesterday|tomorrow)\\b",
            "\\b(last|this|next)\\s*(week|month|year)\\b",
            "\\b(january|february|march|april|may|june|july|august|september|october|november|december)\\b",
            "\\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\\b",
            "\\b(\\d{1,2})\\s*(st|nd|rd|th)?\\s*(of)?\\s*(january|february|march|april|may|june|july|august|september|october|november|december)\\b",
            "\\b(\\d{4}|'\\d{2})\\b"
        ]
        
        for (index, pattern) in datePatterns.enumerated() {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let match = match,
                   let valueRange = Range(match.range, in: text) {
                    let value = String(text[valueRange])
                    let confidence = calculateEntityConfidence(for: value, type: .date)
                    
                    entities.append(QueryEntity(
                        type: .date,
                        value: value,
                        confidence: confidence,
                        startIndex: match.range.location,
                        endIndex: match.range.location + match.range.length
                    ))
                }
            }
        }
        
        return entities
    }
    
    private func extractAccountEntities(_ text: String) -> [QueryEntity] {
        var entities: [QueryEntity] = []
        
        let accountTypes = [
            "chequing", "checking", "savings", "credit card", "creditcard",
            "investment", "tfsa", "rrsp", "visa", "mastercard", "amex"
        ]
        
        for accountType in accountTypes {
            let pattern = "\\b\(accountType)\\b"
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let match = match,
                   let valueRange = Range(match.range, in: text) {
                    let value = String(text[valueRange])
                    let confidence = calculateEntityConfidence(for: value, type: .accountType)
                    
                    entities.append(QueryEntity(
                        type: .accountType,
                        value: value,
                        confidence: confidence,
                        startIndex: match.range.location,
                        endIndex: match.range.location + match.range.length
                    ))
                }
            }
        }
        
        return entities
    }
    
    private func extractCategoryEntities(_ text: String) -> [QueryEntity] {
        var entities: [QueryEntity] = []
        
        let categories = [
            "groceries", "dining", "shopping", "transportation", "entertainment",
            "bills", "healthcare", "education", "food", "restaurant", "gas",
            "uber", "netflix", "subscription", "utilities", "rent", "mortgage"
        ]
        
        for category in categories {
            let pattern = "\\b\(category)\\b"
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let match = match,
                   let valueRange = Range(match.range, in: text) {
                    let value = String(text[valueRange])
                    let confidence = calculateEntityConfidence(for: value, type: .category)
                    
                    entities.append(QueryEntity(
                        type: .category,
                        value: value,
                        confidence: confidence,
                        startIndex: match.range.location,
                        endIndex: match.range.location + match.range.length
                    ))
                }
            }
        }
        
        return entities
    }
    
    private func extractMerchantEntities(_ text: String) -> [QueryEntity] {
        var entities: [QueryEntity] = []
        
        // Common merchants (would be expanded in production)
        let merchants = [
            "amazon", "walmart", "target", "costco", "loblaws", "sobeys",
            "starbucks", "tim hortons", "mcdonalds", "subway", "the keg",
            "netflix", "spotify", "apple", "google", "microsoft",
            "uber", "lyft", "airbnb", "expedia"
        ]
        
        for merchant in merchants {
            let pattern = "\\b\(merchant)\\b"
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let match = match,
                   let valueRange = Range(match.range, in: text) {
                    let value = String(text[valueRange])
                    let confidence = calculateEntityConfidence(for: value, type: .merchant)
                    
                    entities.append(QueryEntity(
                        type: .merchant,
                        value: value,
                        confidence: confidence,
                        startIndex: match.range.location,
                        endIndex: match.range.location + match.range.length
                    ))
                }
            }
        }
        
        return entities
    }
    
    private func extractRiskEntities(_ text: String) -> [QueryEntity] {
        var entities: [QueryEntity] = []
        
        let riskLevels = [
            "conservative", "moderate", "aggressive", "very aggressive",
            "low risk", "medium risk", "high risk", "no risk"
        ]
        
        for riskLevel in riskLevels {
            let pattern = "\\b\(riskLevel)\\b"
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let match = match,
                   let valueRange = Range(match.range, in: text) {
                    let value = String(text[valueRange])
                    let confidence = calculateEntityConfidence(for: value, type: .riskLevel)
                    
                    entities.append(QueryEntity(
                        type: .riskLevel,
                        value: value,
                        confidence: confidence,
                        startIndex: match.range.location,
                        endIndex: match.range.location + match.range.length
                    ))
                }
            }
        }
        
        return entities
    }
    
    private func calculateEntityConfidence(for value: String, type: EntityType) -> Double {
        // Base confidence
        var confidence = 0.8
        
        // Adjust based on entity type and value characteristics
        switch type {
        case .amount:
            confidence = value.contains("$") ? 0.95 : 0.85
        case .date:
            confidence = value.contains("today") || value.contains("yesterday") ? 0.95 : 0.80
        case .accountType:
            confidence = 0.90
        case .category:
            confidence = 0.85
        case .merchant:
            confidence = 0.75
        case .riskLevel:
            confidence = 0.90
        }
        
        return confidence
    }
    
    private func analyzeSentiment(_ text: String) -> SentimentAnalysis {
        tagger.string = text
        
        var sentimentScore: Double = 0.0
        var subjectivityScore: Double = 0.0
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        // Get sentiment score
        if let sentiment = tagger.tag(at: range, unit: .paragraph, scheme: .sentimentScore).first {
            let rawScore = Double(sentiment.rawValue) ?? 0.0
            sentimentScore = (rawScore + 1.0) / 2.0 // Convert from -1..1 to 0..1
        }
        
        // Analyze emotions based on keywords
        let emotions = extractEmotions(text)
        
        // Estimate subjectivity based on emotional words and personal pronouns
        subjectivityScore = calculateSubjectivity(text, emotions: emotions)
        
        return SentimentAnalysis(
            polarity: sentimentScore,
            subjectivity: subjectivityScore,
            emotions: emotions
        )
    }
    
    private func extractEmotions(_ text: String) -> [Emotion] {
        var emotions: [Emotion] = []
        
        let emotionKeywords: [String: String] = [
            // Positive emotions
            "happy": "joy", "excited": "joy", "thrilled": "joy", "delighted": "joy",
            "confident": "confidence", "optimistic": "confidence", "hopeful": "confidence",
            "grateful": "gratitude", "thankful": "gratitude", "appreciative": "gratitude",
            
            // Negative emotions
            "worried": "anxiety", "anxious": "anxiety", "concerned": "anxiety", "nervous": "anxiety",
            "frustrated": "frustration", "annoyed": "frustration", "irritated": "frustration",
            "confused": "confusion", "uncertain": "confusion", "unsure": "confusion",
            "disappointed": "disappointment", "let down": "disappointment",
            "stressed": "stress", "overwhelmed": "stress", "pressured": "stress",
            "scared": "fear", "afraid": "fear", "terrified": "fear"
        ]
        
        for (keyword, emotionType) in emotionKeywords {
            if text.lowercased().contains(keyword) {
                let intensity = calculateEmotionIntensity(text, keyword: keyword)
                emotions.append(Emotion(type: emotionType, intensity: intensity))
            }
        }
        
        return emotions
    }
    
    private func calculateEmotionIntensity(_ text: String, keyword: String) -> Double {
        var intensity = 0.5 // Base intensity
        
        // Intensifiers
        let intensifiers = ["very", "extremely", "really", "so", "totally", "absolutely"]
        for intensifier in intensifiers {
            if text.lowercased().contains("\(intensifier) \(keyword)") {
                intensity += 0.3
            }
        }
        
        // Diminishers
        let diminishers = ["slightly", "somewhat", "a little", "kind of", "sort of"]
        for diminisher in diminishers {
            if text.lowercased().contains("\(diminisher) \(keyword)") {
                intensity -= 0.2
            }
        }
        
        return max(0.1, min(1.0, intensity))
    }
    
    private func calculateSubjectivity(_ text: String, emotions: [Emotion]) -> Double {
        var subjectivity = 0.3 // Base subjectivity
        
        // Personal pronouns indicate subjectivity
        let personalPronouns = ["i", "me", "my", "mine", "myself"]
        for pronoun in personalPronouns {
            if text.lowercased().contains(" \(pronoun) ") {
                subjectivity += 0.1
            }
        }
        
        // Emotional words increase subjectivity
        subjectivity += Double(emotions.count) * 0.15
        
        // Question marks indicate subjectivity
        if text.contains("?") {
            subjectivity += 0.1
        }
        
        // Exclamation marks indicate subjectivity
        if text.contains("!") {
            subjectivity += 0.1
        }
        
        return max(0.0, min(1.0, subjectivity))
    }
    
    private func detectUrgency(_ text: String, sentiment: SentimentAnalysis) -> UrgencyLevel {
        // Urgency keywords
        let urgentKeywords = [
            "urgent", "emergency", "immediately", "right now", "asap", "as soon as possible",
            "critical", "crucial", "important", "need help", "problem", "issue"
        ]
        
        let highUrgencyCount = urgentKeywords.filter { text.lowercased().contains($0) }.count
        
        // Check for negative emotions which might indicate urgency
        let negativeEmotions = sentiment.emotions.filter { 
            ["anxiety", "fear", "stress", "frustration"].contains($0.type) 
        }
        
        if highUrgencyCount >= 2 || negativeEmotions.contains(where: { $0.intensity > 0.7 }) {
            return .critical
        } else if highUrgencyCount >= 1 || negativeEmotions.count >= 2 {
            return .high
        } else if text.lowercased().contains("help") || text.lowercased().contains("question") {
            return .medium
        } else {
            return .low
        }
    }
    
    private func assessComplexity(_ text: String, entities: [QueryEntity]) -> ComplexityLevel {
        var complexityScore = 0
        
        // Length factor
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        if wordCount > 20 {
            complexityScore += 2
        } else if wordCount > 10 {
            complexityScore += 1
        }
        
        // Entity count factor
        complexityScore += min(entities.count, 3)
        
        // Complex indicators
        let complexIndicators = [
            "compare", "versus", "vs", "difference", "relationship", "correlation",
            "optimize", "maximize", "minimize", "strategy", "plan", "forecast",
            "projection", "scenario", "simulation", "analysis", "comprehensive"
        ]
        
        for indicator in complexIndicators {
            if text.lowercased().contains(indicator) {
                complexityScore += 1
            }
        }
        
        // Multi-part questions
        let questionMarks = text.components(separatedBy: "?").count - 1
        if questionMarks > 1 {
            complexityScore += 2
        }
        
        // Conditional statements
        if text.lowercased().contains("if") || text.lowercased().contains("when") {
            complexityScore += 1
        }
        
        switch complexityScore {
        case 0...2:
            return .simple
        case 3...5:
            return .moderate
        case 6...8:
            return .complex
        default:
            return .expert
        }
    }
    
    private func extractContext(_ text: String, entities: [QueryEntity], conversationContext: ConversationContext) -> [String: Any] {
        var context: [String: Any] = [:]
        
        // Entity-based context
        context["entities"] = entities.map { [
            "type": $0.type.rawValue,
            "value": $0.value,
            "confidence": $0.confidence
        ]}
        
        // Temporal context
        let dateEntities = entities.filter { $0.type == .date }
        if !dateEntities.isEmpty {
            context["timeframe"] = extractTimeframe(from: dateEntities)
        }
        
        // Financial context
        let amountEntities = entities.filter { $0.type == .amount }
        if !amountEntities.isEmpty {
            context["amountRange"] = extractAmountRange(from: amountEntities)
        }
        
        // Account context
        let accountEntities = entities.filter { $0.type == .accountType }
        if !accountEntities.isEmpty {
            context["accounts"] = accountEntities.map { $0.value }
        }
        
        // Category context
        let categoryEntities = entities.filter { $0.type == .category }
        if !categoryEntities.isEmpty {
            context["categories"] = categoryEntities.map { $0.value }
        }
        
        return context
    }
    
    private func extractTimeframe(from dateEntities: [QueryEntity]) -> String {
        // Extract and normalize timeframe from date entities
        let dateValues = dateEntities.map { $0.value.lowercased() }
        
        if dateValues.contains("today") {
            return "today"
        } else if dateValues.contains("yesterday") {
            return "yesterday"
        } else if dateValues.contains("this week") {
            return "this_week"
        } else if dateValues.contains("last week") {
            return "last_week"
        } else if dateValues.contains("this month") {
            return "this_month"
        } else if dateValues.contains("last month") {
            return "last_month"
        } else if dateValues.contains("this year") {
            return "this_year"
        } else if dateValues.contains("last year") {
            return "last_year"
        }
        
        return "recent"
    }
    
    private func extractAmountRange(from amountEntities: [QueryEntity]) -> [String: Any] {
        let amounts = amountEntities.compactMap { Double($0.value.replacingOccurrences(of: ",", with: "")) }
        
        if amounts.isEmpty {
            return [:]
        }
        
        let minAmount = amounts.min() ?? 0
        let maxAmount = amounts.max() ?? 0
        
        return [
            "min": minAmount,
            "max": maxAmount,
            "average": amounts.reduce(0, +) / Double(amounts.count)
        ]
    }
}

// MARK: - Supporting Classes

class FinancialVocabulary {
    private let terms: [String: [String]] = [
        "balance": ["balance", "available", "current amount", "money in account"],
        "transaction": ["transaction", "purchase", "payment", "charge", "debit", "credit"],
        "investment": ["investment", "invest", "portfolio", "stock", "bond", "etf"],
        "budget": ["budget", "budgeting", "spending plan", "financial plan"],
        "savings": ["savings", "save", "put aside", "emergency fund"],
        "debt": ["debt", "loan", "owe", "credit card", "mortgage"],
        "income": ["income", "salary", "earnings", "revenue", "pay"],
        "expenses": ["expenses", "spending", "costs", "bills", "payments"]
    ]
    
    func getSynonyms(for term: String) -> [String] {
        return terms[term.lowercased()] ?? []
    }
    
    func normalizeTerm(_ term: String) -> String {
        for (key, synonyms) in terms {
            if synonyms.contains(term.lowercased()) {
                return key
            }
        }
        return term.lowercased()
    }
}

class IntentPatterns {
    private let patterns: [QueryIntent: [String]] = [
        .financialAnalysis: [
            "analyze", "analysis", "review", "summary", "overview", "breakdown",
            "how much", "what is", "show me", "tell me", "financial health"
        ],
        .transactionQuery: [
            "transaction", "purchase", "payment", "charge", "find", "search",
            "recent", "latest", "yesterday", "last week"
        ],
        .budgetPlanning: [
            "budget", "budgeting", "create budget", "budget plan", "spending limit",
            "save money", "reduce expenses", "cut costs"
        ],
        .investmentAdvice: [
            "invest", "investment", "portfolio", "stock", "bond", "etf",
            "where should i invest", "investment advice", "risk tolerance"
        ],
        .taxOptimization: [
            "tax", "taxes", "tax planning", "tax deduction", "tax credit",
            "reduce tax", "tax efficient", "tax saving"
        ],
        .riskAssessment: [
            "risk", "risky", "risk assessment", "risk management", "risk tolerance",
            "financial risk", "investment risk", "emergency fund"
        ],
        .futurePlanning: [
            "future", "planning", "forecast", "projection", "goals",
            "retirement", "save for", "plan for", "financial goals"
        ]
    ]
    
    func getPatterns(for intent: QueryIntent) -> [String] {
        return patterns[intent] ?? []
    }
    
    func matchIntent(_ text: String) -> QueryIntent? {
        let lowercasedText = text.lowercased()
        
        for (intent, patterns) in patterns {
            for pattern in patterns {
                if lowercasedText.contains(pattern) {
                    return intent
                }
            }
        }
        
        return nil
    }
}

class ContextAnalyzer {
    func analyzeContext(_ text: String, conversationHistory: [ConversationTurn]) -> [String: Any] {
        var context: [String: Any] = [:]
        
        // Analyze conversation flow
        if !conversationHistory.isEmpty {
            let lastTurn = conversationHistory.last!
            context["previousTopic"] = extractTopic(from: lastTurn.agentResponse)
            context["conversationContinuity"] = calculateContinuity(text, previousResponse: lastTurn.agentResponse)
        }
        
        // Extract current topic
        context["currentTopic"] = extractTopic(from: text)
        
        // Identify follow-up questions
        context["isFollowUp"] = isFollowUpQuestion(text)
        
        return context
    }
    
    private func extractTopic(from text: String) -> String {
        // Simple topic extraction based on keywords
        let topics = ["balance", "transaction", "budget", "investment", "tax", "risk", "future"]
        
        for topic in topics {
            if text.lowercased().contains(topic) {
                return topic
            }
        }
        
        return "general"
    }
    
    private func calculateContinuity(_ current: String, previousResponse: String) -> Double {
        // Simple continuity calculation based on shared keywords
        let currentWords = Set(current.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let previousWords = Set(previousResponse.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = currentWords.intersection(previousWords)
        let union = currentWords.union(previousWords)
        
        return union.isEmpty ? 0 : Double(intersection.count) / Double(union.count)
    }
    
    private func isFollowUpQuestion(_ text: String) -> Bool {
        let followUpIndicators = [
            "what about", "how about", "and", "also", "additionally",
            "what if", "can you also", "tell me more", "explain further"
        ]
        
        return followUpIndicators.contains { text.lowercased().contains($0) }
    }
}
