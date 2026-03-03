import Foundation
import NaturalLanguage

// MARK: - Data Services
// Following SOLID: Service Layer Pattern

protocol NLPServiceProtocol {
    func analyzeText(_ text: String) async -> NLPResult
    func extractEntities(from text: String) async -> [NLPEntity]
    func analyzeSentiment(_ text: String) async -> SentimentResult
}

class AppleNLPService: NLPServiceProtocol {
    private let sentimentAnalyzer = NLModel(named: "SentimentClassifier")
    private let intentClassifier = NLModel(named: "IntentClassifier")
    
    func analyzeText(_ text: String) async -> NLPResult {
        let entities = await extractEntities(from: text)
        let sentiment = await analyzeSentiment(text)
        let intent = await recognizeIntent(text)
        
        return NLPResult(
            originalText: text,
            entities: entities,
            sentiment: sentiment,
            intent: intent,
            confidence: calculateConfidence(entities: entities, sentiment: sentiment, intent: intent)
        )
    }
    
    func extractEntities(from text: String) async -> [NLPEntity] {
        var entities: [NLPEntity] = []
        
        // Use NLTagger for named entity recognition
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]
        
        tagger.enumerateTags(in: text.start..<text.end, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, tags.contains(tag) {
                let entity = NLPEntity(
                    text: String(text[tokenRange]),
                    type: mapNLTagToEntityType(tag),
                    range: tokenRange,
                    confidence: 0.8
                )
                entities.append(entity)
            }
            return true
        }
        
        // Extract financial entities
        entities.append(contentsOf: extractFinancialEntities(from: text))
        
        return entities
    }
    
    func analyzeSentiment(_ text: String) async -> SentimentResult {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        let score = Double(sentiment?.rawValue ?? "0") ?? 0.0
        
        let sentimentType: SentimentType
        if score > 0.33 {
            sentimentType = .positive
        } else if score < -0.33 {
            sentimentType = .negative
        } else {
            sentimentType = .neutral
        }
        
        return SentimentResult(
            type: sentimentType,
            score: score,
            confidence: abs(score)
        )
    }
    
    private func recognizeIntent(_ text: String) async -> ChatIntent? {
        // Use custom intent classification logic
        let lowercaseText = text.lowercased()
        
        // Priority-based intent recognition
        let intentPatterns: [(ChatIntent, [String])] = [
            (.balanceInquiry, ["balance", "how much", "account balance"]),
            (.spendingAnalysis, ["spend", "spent", "expenses", "spending"]),
            (.transactionSearch, ["transaction", "purchase", "payment"]),
            (.accountInformation, ["account", "accounts"]),
            (.insightsRequest, ["insight", "recommend", "advice"]),
            (.budgetHelp, ["budget", "budgeting"]),
            (.billPayment, ["bill", "payment", "pay"]),
            (.netWorth, ["net worth", "total", "overall"]),
            (.transferMoney, ["transfer", "send money"]),
            (.investmentInfo, ["investment", "portfolio"]),
            (.helpRequest, ["help", "assist"]),
            (.greeting, ["hello", "hi", "hey"]),
            (.farewell, ["bye", "goodbye"])
        ]
        
        for (intent, patterns) in intentPatterns {
            for pattern in patterns {
                if lowercaseText.contains(pattern) {
                    return intent
                }
            }
        }
        
        return .unknown
    }
    
    private func extractFinancialEntities(from text: String) -> [NLPEntity] {
        var entities: [NLPEntity] = []
        
        // Extract amounts
        let amountPattern = #"\$?\d+(?:,\d{3})*(?:\.\d{2})?"#
        if let regex = try? NSRegularExpression(pattern: amountPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let amountText = String(text[range])
                    let entity = NLPEntity(
                        text: amountText,
                        type: .amount,
                        range: match.range,
                        confidence: 0.9
                    )
                    entities.append(entity)
                }
            }
        }
        
        // Extract dates
        let datePattern = #"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b|\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}\b"#
        if let regex = try? NSRegularExpression(pattern: datePattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let dateText = String(text[range])
                    let entity = NLPEntity(
                        text: dateText,
                        type: .date,
                        range: match.range,
                        confidence: 0.8
                    )
                    entities.append(entity)
                }
            }
        }
        
        return entities
    }
    
    private func mapNLTagToEntityType(_ tag: NLTag) -> NLPEntityType {
        switch tag {
        case .personalName:
            return .person
        case .placeName:
            return .location
        case .organizationName:
            return .organization
        default:
            return .unknown
        }
    }
    
    private func calculateConfidence(entities: [NLPEntity], sentiment: SentimentResult, intent: ChatIntent?) -> Double {
        var confidenceScore: Double = 0.0
        
        // Entity confidence
        if !entities.isEmpty {
            confidenceScore += 0.3
        }
        
        // Sentiment confidence
        confidenceScore += sentiment.confidence * 0.2
        
        // Intent confidence
        if intent != nil && intent != .unknown {
            confidenceScore += 0.5
        }
        
        return min(confidenceScore, 1.0)
    }
}

// MARK: - Template Service

protocol TemplateServiceProtocol {
    func render(_ template: String, with variables: [String: String]) -> String
    func validateTemplate(_ template: String) -> ValidationResult
    func extractVariables(from template: String) -> [String]
}

class MustacheTemplateService: TemplateServiceProtocol {
    func render(_ template: String, with variables: [String: String]) -> String {
        var result = template
        
        for (key, value) in variables {
            let placeholder = "{\(key)}"
            result = result.replacingOccurrences(of: placeholder, with: value)
        }
        
        return result
    }
    
    func validateTemplate(_ template: String) -> ValidationResult {
        let variables = extractVariables(from: template)
        let errors: [String] = []
        
        // Check for malformed placeholders
        let malformedPattern = #"\{[^}]*$|^\{[^}]*\}"#
        if let regex = try? NSRegularExpression(pattern: malformedPattern) {
            let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
            if !matches.isEmpty {
                return ValidationResult(isValid: false, errors: ["Malformed placeholders found"])
            }
        }
        
        return ValidationResult(isValid: true, errors: errors)
    }
    
    func extractVariables(from template: String) -> [String] {
        let pattern = #"\{([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        var variables: [String] = []
        
        for match in matches {
            if let range = Range(match.range(at: 1), in: template) {
                variables.append(String(template[range]))
            }
        }
        
        return Array(Set(variables))
    }
}

// MARK: - Cache Service

protocol CacheServiceProtocol {
    func get<T: Codable>(_ key: String, type: T.Type) -> T?
    func set<T: Codable>(_ value: T, for key: String) async
    func remove(_ key: String) async
    func clearAll() async
    func getExpirationTime(for key: String) -> Date?
}

class MemoryCacheService: CacheServiceProtocol {
    private var cache: [String: CacheItem] = [:]
    private let queue = DispatchQueue(label: "cache.queue", attributes: .concurrent)
    
    private struct CacheItem {
        let value: Data
        let expirationTime: Date
    }
    
    func get<T: Codable>(_ key: String, type: T.Type) -> T? {
        return queue.sync {
            guard let item = cache[key] else { return nil }
            
            // Check expiration
            if Date() > item.expirationTime {
                cache.removeValue(forKey: key)
                return nil
            }
            
            return try? JSONDecoder().decode(type, from: item.value)
        }
    }
    
    func set<T: Codable>(_ value: T, for key: String) async {
        let expirationTime = Date().addingTimeInterval(3600) // 1 hour
        guard let data = try? JSONEncoder().encode(value) else { return }
        
        queue.async(flags: .barrier) {
            self.cache[key] = CacheItem(value: data, expirationTime: expirationTime)
        }
    }
    
    func remove(_ key: String) async {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }
    
    func clearAll() async {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    func getExpirationTime(for key: String) -> Date? {
        return queue.sync {
            return cache[key]?.expirationTime
        }
    }
}

// MARK: - Data Models

struct NLPResult {
    let originalText: String
    let entities: [NLPEntity]
    let sentiment: SentimentResult
    let intent: ChatIntent?
    let confidence: Double
}

struct NLPEntity {
    let text: String
    let type: NLPEntityType
    let range: NSRange
    let confidence: Double
}

enum NLPEntityType {
    case person
    case location
    case organization
    case amount
    case date
    case unknown
}

struct SentimentResult {
    let type: SentimentType
    let score: Double
    let confidence: Double
}

enum SentimentType {
    case positive
    case negative
    case neutral
}

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}

// MARK: - Core Data Manager Protocol

protocol CoreDataManagerProtocol {
    func save<T: NSManagedObject>(_ object: T) async throws
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T]
    func fetchAll<T: NSManagedObject>(_ type: T.Type) throws -> [T]
    func delete<T: NSManagedObject>(_ object: T) async throws
    func saveContext() throws
}
