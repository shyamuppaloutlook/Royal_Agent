import Foundation
import Combine

class MarketDataProvider: ObservableObject {
    @Published var marketData: MarketData = MarketData()
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date = Date()
    
    private let updateInterval: TimeInterval = 300 // 5 minutes
    private var updateTimer: Timer?
    
    // MARK: - Market Data Categories
    
    enum MarketCategory: String, CaseIterable {
        case stocks = "Stocks"
        case bonds = "Bonds"
        case commodities = "Commodities"
        case realEstate = "Real Estate"
        case crypto = "Cryptocurrency"
        case currencies = "Currencies"
    }
    
    enum MarketIndex: String, CaseIterable {
        case sAndP500 = "S&P 500"
        case dowJones = "Dow Jones"
        case nasdaq = "NASDAQ"
        case tsx = "TSX"
        case ftse = "FTSE 100"
        case nikkei = "Nikkei 225"
        case dax = "DAX"
        case shanghai = "Shanghai Composite"
    }
    
    enum MarketSector: String, CaseIterable {
        case technology = "Technology"
        case healthcare = "Healthcare"
        case financial = "Financial"
        case energy = "Energy"
        case consumer = "Consumer"
        case industrial = "Industrial"
        case materials = "Materials"
        case utilities = "Utilities"
        case realestate = "Real Estate"
        case communication = "Communication"
    }
    
    // MARK: - Initialization
    
    init() {
        loadInitialMarketData()
        startAutomaticUpdates()
    }
    
    private func loadInitialMarketData() {
        isLoading = true
        
        // Simulate loading market data
        DispatchQueue.global(qos: .userInitiated).async {
            let initialData = generateMockMarketData()
            
            DispatchQueue.main.async {
                self.marketData = initialData
                self.isLoading = false
                self.lastUpdated = Date()
            }
        }
    }
    
    private func startAutomaticUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            self.updateMarketData()
        }
    }
    
    private func updateMarketData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let updatedData = self.generateUpdatedMarketData()
            
            DispatchQueue.main.async {
                self.marketData = updatedData
                self.lastUpdated = Date()
            }
        }
    }
    
    // MARK: - Public Interface
    
    func getCurrentMarketData() -> MarketData {
        return marketData
    }
    
    func getMarketIndices() -> [MarketIndexData] {
        return marketData.indices.values.sorted { $0.name < $1.name }
    }
    
    func getSectorPerformance() -> [SectorPerformance] {
        return marketData.sectors.values.sorted { $0.name < $1.name }
    }
    
    func getMarketSentiment() -> MarketSentiment {
        return marketData.sentiment
    }
    
    func getEconomicIndicators() -> EconomicIndicators {
        return marketData.economicIndicators
    }
    
    func getInvestmentOpportunities() -> [InvestmentOpportunity] {
        return generateInvestmentOpportunities()
    }
    
    func getMarketAnalysis() -> MarketAnalysis {
        return MarketAnalysis(
            overallTrend: determineOverallTrend(),
            volatility: calculateVolatility(),
            riskLevel: assessRiskLevel(),
            recommendations: generateRecommendations(),
            outlook: generateOutlook()
        )
    }
    
    // MARK: - Data Generation Methods
    
    private func generateMockMarketData() -> MarketData {
        var marketData = MarketData()
        
        // Generate market indices
        for index in MarketIndex.allCases {
            marketData.indices[index] = generateMarketIndexData(for: index)
        }
        
        // Generate sector performance
        for sector in MarketSector.allCases {
            marketData.sectors[sector] = generateSectorPerformance(for: sector)
        }
        
        // Generate market sentiment
        marketData.sentiment = generateMarketSentiment()
        
        // Generate economic indicators
        marketData.economicIndicators = generateEconomicIndicators()
        
        // Generate market news
        marketData.news = generateMarketNews()
        
        return marketData
    }
    
    private func generateUpdatedMarketData() -> MarketData {
        var updatedData = marketData
        
        // Update indices with realistic movements
        for index in MarketIndex.allCases {
            if var indexData = updatedData.indices[index] {
                indexData = updateMarketIndexData(indexData)
                updatedData.indices[index] = indexData
            }
        }
        
        // Update sectors
        for sector in MarketSector.allCases {
            if var sectorData = updatedData.sectors[sector] {
                sectorData = updateSectorPerformance(sectorData)
                updatedData.sectors[sector] = sectorData
            }
        }
        
        // Update sentiment
        updatedData.sentiment = updateMarketSentiment(updatedData.sentiment)
        
        // Update economic indicators
        updatedData.economicIndicators = updateEconomicIndicators(updatedData.economicIndicators)
        
        return updatedData
    }
    
    private func generateMarketIndexData(for index: MarketIndex) -> MarketIndexData {
        let baseValues: [MarketIndex: (value: Double, change: Double)] = [
            .sAndP500: (4500.0, 0.0),
            .dowJones: (35000.0, 0.0),
            .nasdaq: (14000.0, 0.0),
            .tsx: (20000.0, 0.0),
            .ftse: (7500.0, 0.0),
            .nikkei: (28000.0, 0.0),
            .dax: (15000.0, 0.0),
            .shanghai: (3000.0, 0.0)
        ]
        
        let baseValue = baseValues[index]?.value ?? 10000.0
        let randomChange = Double.random(in: -0.05...0.05)
        let currentValue = baseValue * (1 + randomChange)
        
        return MarketIndexData(
            name: index.rawValue,
            value: currentValue,
            change: randomChange,
            changePercent: randomChange * 100,
            volume: Double.random(in: 1000000...10000000),
            high: currentValue * Double.random(in: 1.01...1.03),
            low: currentValue * Double.random(in: 0.97...0.99),
            open: currentValue * Double.random(in: 0.98...1.02),
            previousClose: baseValue,
            timestamp: Date()
        )
    }
    
    private func updateMarketIndexData(_ data: MarketIndexData) -> MarketIndexData {
        let randomChange = Double.random(in: -0.02...0.02)
        let newValue = data.value * (1 + randomChange)
        
        return MarketIndexData(
            name: data.name,
            value: newValue,
            change: newValue - data.previousClose,
            changePercent: ((newValue - data.previousClose) / data.previousClose) * 100,
            volume: data.volume * Double.random(in: 0.8...1.2),
            high: max(data.high, newValue),
            low: min(data.low, newValue),
            open: data.open,
            previousClose: data.previousClose,
            timestamp: Date()
        )
    }
    
    private func generateSectorPerformance(for sector: MarketSector) -> SectorPerformance {
        let basePerformances: [MarketSector: Double] = [
            .technology: 0.02,
            .healthcare: 0.01,
            .financial: 0.00,
            .energy: -0.01,
            .consumer: 0.01,
            .industrial: 0.00,
            .materials: -0.02,
            .utilities: -0.01,
            .realestate: 0.01,
            .communication: 0.02
        ]
        
        let basePerformance = basePerformances[sector] ?? 0.0
        let randomVariation = Double.random(in: -0.01...0.01)
        let performance = basePerformance + randomVariation
        
        return SectorPerformance(
            name: sector.rawValue,
            performance: performance,
            performancePercent: performance * 100,
            marketCap: Double.random(in: 1000000000...100000000000),
            volume: Double.random(in: 100000000...1000000000),
            volatility: Double.random(in: 0.1...0.3),
            peRatio: Double.random(in: 10...30),
            dividendYield: Double.random(in: 0.01...0.05)
        )
    }
    
    private func updateSectorPerformance(_ data: SectorPerformance) -> SectorPerformance {
        let randomChange = Double.random(in: -0.005...0.005)
        let newPerformance = data.performance + randomChange
        
        return SectorPerformance(
            name: data.name,
            performance: newPerformance,
            performancePercent: newPerformance * 100,
            marketCap: data.marketCap * Double.random(in: 0.99...1.01),
            volume: data.volume * Double.random(in: 0.9...1.1),
            volatility: data.volatility * Double.random(in: 0.95...1.05),
            peRatio: data.peRatio * Double.random(in: 0.98...1.02),
            dividendYield: data.dividendYield * Double.random(in: 0.99...1.01)
        )
    }
    
    private func generateMarketSentiment() -> MarketSentiment {
        let sentimentScore = Double.random(in: -1...1)
        let sentiment: Sentiment
        
        if sentimentScore > 0.5 {
            sentiment = .bullish
        } else if sentimentScore < -0.5 {
            sentiment = .bearish
        } else {
            sentiment = .neutral
        }
        
        return MarketSentiment(
            sentiment: sentiment,
            score: sentimentScore,
            fearAndGreedIndex: Int.random(in: 0...100),
            vix: Double.random(in: 10...40),
            putCallRatio: Double.random(in: 0.5...2.0),
            marketBreadth: Double.random(in: 0.3...0.8),
            timestamp: Date()
        )
    }
    
    private func updateMarketSentiment(_ data: MarketSentiment) -> MarketSentiment {
        let randomChange = Double.random(in: -0.1...0.1)
        let newScore = max(-1, min(1, data.score + randomChange))
        
        let newSentiment: Sentiment
        if newScore > 0.5 {
            newSentiment = .bullish
        } else if newScore < -0.5 {
            newSentiment = .bearish
        } else {
            newSentiment = .neutral
        }
        
        return MarketSentiment(
            sentiment: newSentiment,
            score: newScore,
            fearAndGreedIndex: max(0, min(100, data.fearAndGreedIndex + Int.random(in: -5...5))),
            vix: max(10, min(40, data.vix + Double.random(in: -2...2))),
            putCallRatio: max(0.5, min(2.0, data.putCallRatio + Double.random(in: -0.1...0.1))),
            marketBreadth: max(0.3, min(0.8, data.marketBreadth + Double.random(in: -0.05...0.05))),
            timestamp: Date()
        )
    }
    
    private func generateEconomicIndicators() -> EconomicIndicators {
        return EconomicIndicators(
            interestRate: Double.random(in: 0.025...0.055),
            inflationRate: Double.random(in: 0.02...0.04),
            gdpGrowth: Double.random(in: 0.02...0.04),
            unemploymentRate: Double.random(in: 0.03...0.07),
            consumerConfidence: Double.random(in: 80...120),
            manufacturingPMI: Double.random(in: 45...65),
            servicesPMI: Double.random(in: 50...70),
            retailSales: Double.random(in: -0.02...0.02),
            housingStarts: Double.random(in: -0.05...0.05),
            durableGoodsOrders: Double.random(in: -0.03...0.03),
            tradeBalance: Double.random(in: -50000...50000),
            productivity: Double.random(in: 0.01...0.03),
            timestamp: Date()
        )
    }
    
    private func updateEconomicIndicators(_ data: EconomicIndicators) -> EconomicIndicators {
        return EconomicIndicators(
            interestRate: max(0.025, min(0.055, data.interestRate + Double.random(in: -0.001...0.001))),
            inflationRate: max(0.02, min(0.04, data.inflationRate + Double.random(in: -0.001...0.001))),
            gdpGrowth: max(0.02, min(0.04, data.gdpGrowth + Double.random(in: -0.001...0.001))),
            unemploymentRate: max(0.03, min(0.07, data.unemploymentRate + Double.random(in: -0.001...0.001))),
            consumerConfidence: max(80, min(120, data.consumerConfidence + Double.random(in: -2...2))),
            manufacturingPMI: max(45, min(65, data.manufacturingPMI + Double.random(in: -1...1))),
            servicesPMI: max(50, min(70, data.servicesPMI + Double.random(in: -1...1))),
            retailSales: data.retailSales + Double.random(in: -0.005...0.005),
            housingStarts: data.housingStarts + Double.random(in: -0.01...0.01),
            durableGoodsOrders: data.durableGoodsOrders + Double.random(in: -0.008...0.008),
            tradeBalance: data.tradeBalance + Double.random(in: -5000...5000),
            productivity: max(0.01, min(0.03, data.productivity + Double.random(in: -0.001...0.001))),
            timestamp: Date()
        )
    }
    
    private func generateMarketNews() -> [MarketNews] {
        let newsTemplates = [
            "Fed signals potential rate cut as economic data shows slowdown",
            "Tech stocks rally on AI optimism, Nasdaq reaches new highs",
            "Energy sector under pressure as oil prices decline",
            "Banking stocks gain on better-than-expected earnings",
            "Consumer discretionary stocks rise on strong retail sales",
            "Healthcare sector mixed as drug approval news impacts biotech",
            "Industrial stocks gain on infrastructure spending announcement",
            "Real estate investment trusts see yields compress further",
            "Utilities sector considered safe haven amid market volatility",
            "Communication stocks benefit from streaming service growth"
        ]
        
        return newsTemplates.enumerated().map { index, template in
            MarketNews(
                id: UUID().uuidString,
                headline: template,
                summary: generateNewsSummary(for: template),
                source: "Financial News Network",
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                category: determineNewsCategory(for: template),
                sentiment: determineNewsSentiment(for: template),
                impact: determineNewsImpact(for: template)
            )
        }
    }
    
    private func generateNewsSummary(for headline: String) -> String {
        return "Breaking: \(headline). This development could impact market sentiment and investor behavior in the coming days."
    }
    
    private func determineNewsCategory(for headline: String) -> NewsCategory {
        let lowercased = headline.lowercased()
        
        if lowercased.contains("fed") || lowercased.contains("rate") {
            return .monetaryPolicy
        } else if lowercased.contains("tech") || lowercased.contains("ai") {
            return .technology
        } else if lowercased.contains("energy") || lowercased.contains("oil") {
            return .energy
        } else if lowercased.contains("bank") || lowercased.contains("financial") {
            return .financial
        } else if lowercased.contains("retail") || lowercased.contains("consumer") {
            return .consumer
        } else if lowercased.contains("healthcare") || lowercased.contains("drug") {
            return .healthcare
        } else if lowercased.contains("industrial") || lowercased.contains("infrastructure") {
            return .industrial
        } else if lowercased.contains("real estate") || lowercased.contains("reit") {
            return .realEstate
        } else if lowercased.contains("utility") {
            return .utilities
        } else {
            return .general
        }
    }
    
    private func determineNewsSentiment(for headline: String) -> NewsSentiment {
        let lowercased = headline.lowercased()
        
        if lowercased.contains("rally") || lowercased.contains("gain") || lowercased.contains("rise") || lowercased.contains("high") {
            return .positive
        } else if lowercased.contains("decline") || lowercased.contains("fall") || lowercased.contains("pressure") || lowercased.contains("low") {
            return .negative
        } else {
            return .neutral
        }
    }
    
    private func determineNewsImpact(for headline: String) -> NewsImpact {
        let lowercased = headline.lowercased()
        
        if lowercased.contains("fed") || lowercased.contains("rate") {
            return .high
        } else if lowercased.contains("tech") || lowercased.contains("ai") {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Investment Opportunities
    
    private func generateInvestmentOpportunities() -> [InvestmentOpportunity] {
        var opportunities: [InvestmentOpportunity] = []
        
        // Technology sector opportunities
        if marketData.sectors[.technology]?.performance ?? 0 > 0.01 {
            opportunities.append(InvestmentOpportunity(
                id: UUID().uuidString,
                title: "Tech Growth ETF",
                description: "Invest in technology companies showing strong performance",
                category: .technology,
                riskLevel: .high,
                potentialReturn: 0.12,
                timeHorizon: "3-5 years",
                minimumInvestment: 1000.0,
                rationale: "Technology sector showing strong momentum with AI innovation"
            ))
        }
        
        // Healthcare opportunities
        if marketData.sectors[.healthcare]?.performance ?? 0 > 0.005 {
            opportunities.append(InvestmentOpportunity(
                id: UUID().uuidString,
                title: "Healthcare Innovation Fund",
                description: "Invest in innovative healthcare companies",
                category: .healthcare,
                riskLevel: .medium,
                potentialReturn: 0.08,
                timeHorizon: "2-4 years",
                minimumInvestment: 500.0,
                rationale: "Healthcare sector stable with growth potential"
            ))
        }
        
        // Energy sector opportunities
        if marketData.sectors[.energy]?.performance ?? 0 < -0.01 {
            opportunities.append(InvestmentOpportunity(
                id: UUID().uuidString,
                title: "Energy Value Fund",
                description: "Buy undervalued energy companies at attractive prices",
                category: .energy,
                riskLevel: .medium,
                potentialReturn: 0.10,
                timeHorizon: "2-3 years",
                minimumInvestment: 750.0,
                rationale: "Energy sector oversold, potential for rebound"
            ))
        }
        
        // Fixed income opportunities
        if marketData.economicIndicators.interestRate > 0.04 {
            opportunities.append(InvestmentOpportunity(
                id: UUID().uuidString,
                title: "High-Yield Bond Fund",
                description: "Invest in bonds offering attractive yields",
                category: .fixedIncome,
                riskLevel: .low,
                potentialReturn: 0.05,
                timeHorizon: "1-3 years",
                minimumInvestment: 250.0,
                rationale: "Interest rates favorable for bond investments"
            ))
        }
        
        return opportunities.sorted { $0.potentialReturn > $1.potentialReturn }
    }
    
    // MARK: - Market Analysis
    
    private func determineOverallTrend() -> MarketTrend {
        let indexChanges = marketData.indices.values.map { $0.changePercent }
        let avgChange = indexChanges.reduce(0, +) / Double(indexChanges.count)
        
        if avgChange > 1.0 {
            return .strongBullish
        } else if avgChange > 0.5 {
            return .bullish
        } else if avgChange > -0.5 {
            return .neutral
        } else if avgChange > -1.0 {
            return .bearish
        } else {
            return .strongBearish
        }
    }
    
    private func calculateVolatility() -> Double {
        let indexChanges = marketData.indices.values.map { $0.changePercent }
        let mean = indexChanges.reduce(0, +) / Double(indexChanges.count)
        let variance = indexChanges.map { pow($0 - mean, 2) }.reduce(0, +) / Double(indexChanges.count)
        return sqrt(variance)
    }
    
    private func assessRiskLevel() -> RiskLevel {
        let volatility = calculateVolatility()
        let vix = marketData.sentiment.vix
        
        if volatility > 2.0 || vix > 30 {
            return .high
        } else if volatility > 1.5 || vix > 25 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func generateRecommendations() -> [MarketRecommendation] {
        var recommendations: [MarketRecommendation] = []
        
        let trend = determineOverallTrend()
        let risk = assessRiskLevel()
        
        switch trend {
        case .strongBullish, .bullish:
            recommendations.append(MarketRecommendation(
                title: "Consider Equity Investments",
                description: "Market showing strength, good time for equity exposure",
                action: .buy,
                priority: .high
            ))
        case .strongBearish, .bearish:
            recommendations.append(MarketRecommendation(
                title: "Defensive Position Recommended",
                description: "Market weakness, consider defensive assets",
                action: .sell,
                priority: .high
            ))
        case .neutral:
            recommendations.append(MarketRecommendation(
                title: "Maintain Balanced Portfolio",
                description: "Market conditions mixed, maintain diversification",
                action: .hold,
                priority: .medium
            ))
        }
        
        switch risk {
        case .high:
            recommendations.append(MarketRecommendation(
                title: "Reduce Risk Exposure",
                description: "High volatility detected, consider reducing risk",
                action: .reduce,
                priority: .medium
            ))
        case .low:
            recommendations.append(MarketRecommendation(
                title: "Consider Growth Opportunities",
                description: "Low volatility, good time for growth investments",
                action: .increase,
                priority: .medium
            ))
        case .medium:
            break
        }
        
        return recommendations
    }
    
    private func generateOutlook() -> MarketOutlook {
        let trend = determineOverallTrend()
        let sentiment = marketData.sentiment.sentiment
        
        let shortTerm: Outlook
        let mediumTerm: Outlook
        let longTerm: Outlook
        
        switch (trend, sentiment) {
        case (.bullish, .bullish):
            shortTerm = .positive
            mediumTerm = .positive
            longTerm = .positive
        case (.bearish, .bearish):
            shortTerm = .negative
            mediumTerm = .negative
            longTerm = .neutral
        case (.neutral, _):
            shortTerm = .neutral
            mediumTerm = .neutral
            longTerm = .positive
        default:
            shortTerm = .neutral
            mediumTerm = .neutral
            longTerm = .neutral
        }
        
        return MarketOutlook(
            shortTerm: shortTerm,
            mediumTerm: mediumTerm,
            longTerm: longTerm,
            confidence: 0.75,
            keyFactors: determineKeyFactors()
        )
    }
    
    private func determineKeyFactors() -> [String] {
        var factors: [String] = []
        
        if marketData.economicIndicators.interestRate > 0.045 {
            factors.append("High interest rates may impact equity valuations")
        }
        
        if marketData.economicIndicators.inflationRate > 0.03 {
            factors.append("Elevated inflation affecting purchasing power")
        }
        
        if marketData.sentiment.vix > 25 {
            factors.append("Elevated volatility indicating market uncertainty")
        }
        
        if marketData.economicIndicators.gdpGrowth > 0.03 {
            factors.append("Strong GDP growth supporting corporate earnings")
        }
        
        return factors
    }
}

// MARK: - Data Structures

struct MarketData {
    var indices: [MarketIndex: MarketIndexData] = [:]
    var sectors: [MarketSector: SectorPerformance] = [:]
    var sentiment: MarketSentiment = MarketSentiment()
    var economicIndicators: EconomicIndicators = EconomicIndicators()
    var news: [MarketNews] = []
}

struct MarketIndexData {
    let name: String
    let value: Double
    let change: Double
    let changePercent: Double
    let volume: Double
    let high: Double
    let low: Double
    let open: Double
    let previousClose: Double
    let timestamp: Date
}

struct SectorPerformance {
    let name: String
    let performance: Double
    let performancePercent: Double
    let marketCap: Double
    let volume: Double
    let volatility: Double
    let peRatio: Double
    let dividendYield: Double
}

struct MarketSentiment {
    let sentiment: Sentiment
    let score: Double
    let fearAndGreedIndex: Int
    let vix: Double
    let putCallRatio: Double
    let marketBreadth: Double
    let timestamp: Date
}

struct EconomicIndicators {
    let interestRate: Double
    let inflationRate: Double
    let gdpGrowth: Double
    let unemploymentRate: Double
    let consumerConfidence: Double
    let manufacturingPMI: Double
    let servicesPMI: Double
    let retailSales: Double
    let housingStarts: Double
    let durableGoodsOrders: Double
    let tradeBalance: Double
    let productivity: Double
    let timestamp: Date
}

struct MarketNews {
    let id: String
    let headline: String
    let summary: String
    let source: String
    let timestamp: Date
    let category: NewsCategory
    let sentiment: NewsSentiment
    let impact: NewsImpact
}

struct InvestmentOpportunity {
    let id: String
    let title: String
    let description: String
    let category: InvestmentCategory
    let riskLevel: RiskLevel
    let potentialReturn: Double
    let timeHorizon: String
    let minimumInvestment: Double
    let rationale: String
}

struct MarketAnalysis {
    let overallTrend: MarketTrend
    let volatility: Double
    let riskLevel: RiskLevel
    let recommendations: [MarketRecommendation]
    let outlook: MarketOutlook
}

struct MarketRecommendation {
    let title: String
    let description: String
    let action: RecommendationAction
    let priority: Priority
}

struct MarketOutlook {
    let shortTerm: Outlook
    let mediumTerm: Outlook
    let longTerm: Outlook
    let confidence: Double
    let keyFactors: [String]
}

// MARK: - Enums

enum Sentiment {
    case bullish, bearish, neutral
}

enum NewsCategory {
    case monetaryPolicy, technology, energy, financial, consumer, healthcare, industrial, realEstate, utilities, general
}

enum NewsSentiment {
    case positive, negative, neutral
}

enum NewsImpact {
    case low, medium, high
}

enum InvestmentCategory {
    case technology, healthcare, energy, financial, consumer, industrial, materials, utilities, realestate, communication, fixedIncome
}

enum MarketTrend {
    case strongBullish, bullish, neutral, bearish, strongBearish
}

enum RiskLevel {
    case low, medium, high
}

enum RecommendationAction {
    case buy, sell, hold, increase, reduce
}

enum Outlook {
    case positive, negative, neutral
}
