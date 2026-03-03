import Foundation
import SwiftUI
import Combine

class RBCKnowledgeBase: ObservableObject {
    @Published var isKnowledgeBaseEnabled: Bool = true
    @Published var knowledgeCategories: [KnowledgeCategory] = []
    @Published var knowledgeArticles: [KnowledgeArticle] = []
    @Published var faqItems: [FAQItem] = []
    @Published var productInformation: [ProductInfo] = []
    @Published var policies: [RBCPolicy] = []
    @Published var procedures: [RBCProcedure] = []
    @Published var knowledgeSettings: KnowledgeSettings = KnowledgeSettings()
    @Published var searchResults: [KnowledgeSearchResult] = []
    @Published var isUpdating: Bool = false
    @Published var updateProgress: Double = 0.0
    @Published var lastSyncTime: Date?
    
    private var knowledgeEngine: RBCKnowledgeEngine
    private var searchEngine: KnowledgeSearchEngine
    private var syncEngine: RBCSyncEngine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Knowledge Categories
    
    enum KnowledgeCategoryType: String, CaseIterable, Identifiable {
        case banking = "Banking"
        case accounts = "Accounts"
        case creditCards = "Credit Cards"
        case loans = "Loans"
        case mortgages = "Mortgages"
        case investments = "Investments"
        case insurance = "Insurance"
        case wealth = "Wealth Management"
        case digital = "Digital Banking"
        case security = "Security"
        case support = "Customer Support"
        case compliance = "Compliance"
        case fees = "Fees and Charges"
        case mobile = "Mobile Banking"
        case online = "Online Banking"
        case business = "Business Banking"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .banking: return "building.columns"
            case .accounts: return "person.crop.circle"
            case .creditCards: return "creditcard"
            case .loans: return "dollarsign.circle"
            case .mortgages: return "house"
            case .investments: return "chart.line.uptrend.xyaxis"
            case .insurance: return "shield"
            case .wealth: return "chart.pie"
            case .digital: return "iphone"
            case .security: return "lock.shield"
            case .support: return "headphones"
            case .compliance: return "gavel"
            case .fees: return "dollarsign.square"
            case .mobile: return "iphone"
            case .online: return "globe"
            case .business: return "briefcase"
            }
        }
        
        var color: Color {
            switch self {
            case .banking: return .blue
            case .accounts: return .green
            case .creditCards: return .purple
            case .loans: return .orange
            case .mortgages: return .teal
            case .investments: return .indigo
            case .insurance: return .pink
            case .wealth: return .yellow
            case .digital: return .cyan
            case .security: return .red
            case .support: return .mint
            case .compliance: return .gray
            case .fees: return .red
            case .mobile: return .blue
            case .online: return .green
            case .business: return .purple
            }
        }
    }
    
    // MARK: - Content Types
    
    enum ContentType: String, CaseIterable, Identifiable {
        case article = "Article"
        case faq = "FAQ"
        case policy = "Policy"
        case procedure = "Procedure"
        case tutorial = "Tutorial"
        case guide = "Guide"
        case reference = "Reference"
        case news = "News"
        case update = "Update"
        case alert = "Alert"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .article: return "doc.text"
            case .faq: return "questionmark.circle"
            case .policy: return "doc.text.fill"
            case .procedure: return "list.number"
            case .tutorial: return "play.circle"
            case .guide: return "book"
            case .reference: return "book.closed"
            case .news: return "newspaper"
            case .update: return "arrow.up.circle"
            case .alert: return "bell"
            }
        }
        
        var color: Color {
            switch self {
            case .article: return .blue
            case .faq: return .green
            case .policy: return .red
            case .procedure: return .orange
            case .tutorial: return .purple
            case .guide: return .indigo
            case .reference: return .teal
            case .news: return .pink
            case .update: return .yellow
            case .alert: return .red
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        knowledgeEngine = RBCKnowledgeEngine()
        searchEngine = KnowledgeSearchEngine()
        syncEngine = RBCSyncEngine()
        setupKnowledgeBase()
        loadKnowledgeSettings()
        loadKnowledgeCategories()
        loadKnowledgeArticles()
        loadFAQItems()
        loadProductInformation()
        loadPolicies()
        loadProcedures()
        setupSearchEngine()
        setupPeriodicSync()
    }
    
    private func setupKnowledgeBase() {
        // Initialize knowledge base components
    }
    
    private func loadKnowledgeSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "knowledge_settings"),
           let settings = try? JSONDecoder().decode(KnowledgeSettings.self, from: data) {
            knowledgeSettings = settings
            isKnowledgeBaseEnabled = settings.isEnabled
        }
        
        if let timestamp = defaults.object(forKey: "last_knowledge_sync") as? Date {
            lastSyncTime = timestamp
        }
    }
    
    private func saveKnowledgeSettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(knowledgeSettings) {
            defaults.set(data, forKey: "knowledge_settings")
        }
        
        if let lastSync = lastSyncTime {
            defaults.set(lastSync, forKey: "last_knowledge_sync")
        }
    }
    
    private func loadKnowledgeCategories() {
        knowledgeCategories = [
            KnowledgeCategory(
                id: "personal-banking",
                name: "Personal Banking",
                description: "Personal banking products and services",
                type: .banking,
                articleCount: 150,
                lastUpdated: Date(),
                isActive: true
            ),
            KnowledgeCategory(
                id: "credit-cards",
                name: "Credit Cards",
                description: "RBC credit card products and features",
                type: .creditCards,
                articleCount: 85,
                lastUpdated: Date(),
                isActive: true
            ),
            KnowledgeCategory(
                id: "investments",
                name: "Investments",
                description: "Investment products and wealth management",
                type: .investments,
                articleCount: 120,
                lastUpdated: Date(),
                isActive: true
            ),
            KnowledgeCategory(
                id: "digital-banking",
                name: "Digital Banking",
                description: "Online and mobile banking services",
                type: .digital,
                articleCount: 95,
                lastUpdated: Date(),
                isActive: true
            ),
            KnowledgeCategory(
                id: "security",
                name: "Security",
                description: "Security features and fraud prevention",
                type: .security,
                articleCount: 65,
                lastUpdated: Date(),
                isActive: true
            ),
            KnowledgeCategory(
                id: "support",
                name: "Customer Support",
                description: "Help and support resources",
                type: .support,
                articleCount: 45,
                lastUpdated: Date(),
                isActive: true
            )
        ]
    }
    
    private func loadKnowledgeArticles() {
        knowledgeArticles = [
            KnowledgeArticle(
                id: "how-to-check-balance",
                title: "How to Check Your Account Balance",
                content: "To check your RBC account balance, you can use several methods...",
                category: .banking,
                contentType: .guide,
                author: "RBC Support",
                publishDate: Date().addingTimeInterval(-86400 * 30),
                lastUpdated: Date().addingTimeInterval(-86400 * 7),
                tags: ["balance", "account", "checking"],
                views: 15420,
                helpful: 1420,
                notHelpful: 85
            ),
            KnowledgeArticle(
                id: "credit-card-benefits",
                title: "Understanding RBC Credit Card Benefits",
                content: "RBC credit cards offer numerous benefits including cashback...",
                category: .creditCards,
                contentType: .article,
                author: "RBC Product Team",
                publishDate: Date().addingTimeInterval(-86400 * 14),
                lastUpdated: Date().addingTimeInterval(-86400 * 3),
                tags: ["credit card", "benefits", "rewards"],
                views: 8930,
                helpful: 892,
                notHelpful: 45
            ),
            KnowledgeArticle(
                id: "mobile-app-features",
                title: "RBC Mobile App Features and Functions",
                content: "The RBC mobile app provides comprehensive banking functionality...",
                category: .mobile,
                contentType: .tutorial,
                author: "RBC Digital Team",
                publishDate: Date().addingTimeInterval(-86400 * 21),
                lastUpdated: Date().addingTimeInterval(-86400 * 5),
                tags: ["mobile", "app", "features"],
                views: 12350,
                helpful: 1150,
                notHelpful: 67
            ),
            KnowledgeArticle(
                id: "mortgage-application-process",
                title: "Complete Guide to Mortgage Applications",
                content: "Applying for an RBC mortgage involves several key steps...",
                category: .mortgages,
                contentType: .guide,
                author: "RBC Mortgage Team",
                publishDate: Date().addingTimeInterval(-86400 * 45),
                lastUpdated: Date().addingTimeInterval(-86400 * 10),
                tags: ["mortgage", "application", "home"],
                views: 6780,
                helpful: 623,
                notHelpful: 38
            ),
            KnowledgeArticle(
                id: "fraud-protection",
                title: "RBC Fraud Protection and Security Measures",
                content: "RBC employs multiple layers of security to protect your accounts...",
                category: .security,
                contentType: .article,
                author: "RBC Security Team",
                publishDate: Date().addingTimeInterval(-86400 * 10),
                lastUpdated: Date().addingTimeInterval(-86400 * 2),
                tags: ["fraud", "security", "protection"],
                views: 9870,
                helpful: 945,
                notHelpful: 52
            )
        ]
    }
    
    private func loadFAQItems() {
        faqItems = [
            FAQItem(
                id: "faq-minimum-balance",
                question: "What is the minimum balance requirement for RBC accounts?",
                answer: "The minimum balance requirement varies by account type. For RBC No Limit Banking, there's no minimum balance. For RBC Advantage Banking, the minimum balance is $3,000 to waive the monthly fee.",
                category: .accounts,
                views: 15420,
                helpful: 892,
                lastUpdated: Date().addingTimeInterval(-86400 * 15)
            ),
            FAQItem(
                id: "faq-credit-card-limit",
                question: "How can I increase my RBC credit card limit?",
                answer: "You can request a credit limit increase through your RBC Online Banking account, mobile app, or by calling customer service. RBC will review your credit history, income, and payment history to determine eligibility.",
                category: .creditCards,
                views: 8930,
                helpful: 756,
                lastUpdated: Date().addingTimeInterval(-86400 * 8)
            ),
            FAQItem(
                id: "faq-interac-e-transfer",
                question: "How do I send an Interac e-Transfer?",
                answer: "To send an Interac e-Transfer: 1) Sign in to RBC Online Banking or the mobile app, 2) Select 'Send Interac e-Transfer', 3) Enter the recipient's email or phone number, 4) Enter the amount and add a security question, 5) Confirm and send.",
                category: .digital,
                views: 12350,
                helpful: 1120,
                lastUpdated: Date().addingTimeInterval(-86400 * 5)
            ),
            FAQItem(
                id: "faq-mortgage-prepayment",
                question: "Can I make extra payments on my RBC mortgage?",
                answer: "Yes, RBC allows mortgage prepayments. You can typically increase your regular payment by up to 100% and make lump-sum payments up to 25% of your original mortgage amount each year.",
                category: .mortgages,
                views: 6780,
                helpful: 623,
                lastUpdated: Date().addingTimeInterval(-86400 * 12)
            ),
            FAQItem(
                id: "faq-lost-card",
                question: "What should I do if my RBC card is lost or stolen?",
                answer: "If your RBC card is lost or stolen: 1) Immediately lock your card through the RBC mobile app or online banking, 2) Call RBC at 1-800-769-2511 to report it, 3) Request a replacement card, which typically arrives within 5-7 business days.",
                category: .security,
                views: 9870,
                helpful: 945,
                lastUpdated: Date().addingTimeInterval(-86400 * 3)
            )
        ]
    }
    
    private func loadProductInformation() {
        productInformation = [
            ProductInfo(
                id: "rbc-no-limit-banking",
                name: "RBC No Limit Banking",
                description: "Everyday banking with no monthly fees and unlimited transactions",
                category: .accounts,
                type: "Chequing Account",
                features: [
                    "No monthly fee",
                    "Unlimited debit transactions",
                    "Free Interac e-Transfers",
                    "Mobile and online banking",
                    "RBC Rewards points"
                ],
                fees: [
                    "Monthly Fee: $0",
                    "Overdraft Fee: $5 per use",
                    "NSF Fee: $45",
                    "Wire Transfer: $16.95 (in Canada)"
                ],
                requirements: [
                    "Must be 18 years or older",
                    "Valid Canadian ID required",
                    "Social Insurance Number"
                ],
                lastUpdated: Date().addingTimeInterval(-86400 * 7)
            ),
            ProductInfo(
                id: "rbc-avion-visa",
                name: "RBC Avion Visa Infinite",
                description: "Premium travel rewards credit card with comprehensive travel benefits",
                category: .creditCards,
                type: "Credit Card",
                features: [
                    "Earn 1.25 Avion points per $1 spent",
                    "No foreign transaction fees",
                    "Comprehensive travel insurance",
                    "Airport lounge access",
                    "Concierge service",
                    "RBC Avion Rewards redemption"
                ],
                fees: [
                    "Annual Fee: $120",
                    "Interest Rate: 19.99% (p.a.)",
                    "Cash Advance Fee: $3.50 or 3.5%",
                    "Balance Transfer Fee: $3.50 or 3.5%"
                ],
                requirements: [
                    "Minimum personal income of $60,000",
                    "Minimum household income of $100,000",
                    "Good credit history required"
                ],
                lastUpdated: Date().addingTimeInterval(-86400 * 14)
            ),
            ProductInfo(
                id: "rbc-mobile-app",
                name: "RBC Mobile Banking App",
                description: "Comprehensive mobile banking solution for iOS and Android",
                category: .mobile,
                type: "Mobile Application",
                features: [
                    "Check account balances",
                    "Transfer money",
                    "Pay bills",
                    "Deposit cheques",
                    "Send Interac e-Transfers",
                    "Find nearby branches and ATMs",
                    "Investment management",
                    "Card management"
                ],
                fees: [
                    "Free to download and use",
                    "Data charges may apply from carrier",
                    "No transaction fees for standard banking"
                ],
                requirements: [
                    "iOS 12.0+ or Android 6.0+",
                    "RBC Online Banking account",
                    "Internet connection"
                ],
                lastUpdated: Date().addingTimeInterval(-86400 * 5)
            )
        ]
    }
    
    private func loadPolicies() {
        policies = [
            RBCPolicy(
                id: "privacy-policy",
                title: "RBC Privacy Policy",
                description: "How RBC collects, uses, and protects your personal information",
                category: .compliance,
                effectiveDate: Date().addingTimeInterval(-86400 * 365),
                lastUpdated: Date().addingTimeInterval(-86400 * 30),
                content: "RBC is committed to protecting your privacy and safeguarding your personal information...",
                version: "2.1"
            ),
            RBCPolicy(
                id: "terms-of-service",
                title: "RBC Online Banking Terms of Service",
                description: "Terms and conditions for using RBC Online Banking services",
                category: .compliance,
                effectiveDate: Date().addingTimeInterval(-86400 * 180),
                lastUpdated: Date().addingTimeInterval(-86400 * 15),
                content: "By using RBC Online Banking, you agree to these terms and conditions...",
                version: "3.0"
            ),
            RBCPolicy(
                id: "fraud-policy",
                title: "RBC Fraud Prevention Policy",
                description: "RBC's approach to fraud prevention and customer protection",
                category: .security,
                effectiveDate: Date().addingTimeInterval(-86400 * 90),
                lastUpdated: Date().addingTimeInterval(-86400 * 10),
                content: "RBC maintains comprehensive fraud detection and prevention systems...",
                version: "1.5"
            )
        ]
    }
    
    private func loadProcedures() {
        procedures = [
            RBCProcedure(
                id: "dispute-transaction",
                title: "How to Dispute a Transaction",
                description: "Step-by-step process for disputing unauthorized or incorrect transactions",
                category: .support,
                steps: [
                    "Review your transaction history carefully",
                    "Contact the merchant first if possible",
                    "Sign in to RBC Online Banking",
                    "Select the transaction and choose 'Dispute'",
                    "Provide details about the dispute",
                    "Submit supporting documentation",
                    "Wait for investigation results"
                ],
                estimatedTime: "5-10 business days",
                lastUpdated: Date().addingTimeInterval(-86400 * 20)
            ),
            RBCProcedure(
                id: "close-account",
                title: "How to Close an RBC Account",
                description: "Process for closing RBC banking accounts",
                category: .accounts,
                steps: [
                    "Ensure all transactions are complete",
                    "Transfer remaining balance to another account",
                    "Cancel any pre-authorized payments",
                    "Destroy your debit card and cheques",
                    "Visit a branch or call customer service",
                    "Provide identification and account details",
                    "Confirm account closure"
                ],
                estimatedTime: "Same day (in branch) or 3-5 business days (phone)",
                lastUpdated: Date().addingTimeInterval(-86400 * 25)
            ),
            RBCProcedure(
                id: "report-fraud",
                title: "How to Report Fraudulent Activity",
                description: "Steps to take if you suspect fraudulent activity on your account",
                category: .security,
                steps: [
                    "Immediately lock your card in the mobile app",
                    "Review recent transactions for unauthorized charges",
                    "Call RBC immediately at 1-800-769-2511",
                    "Change your online banking password",
                    "File a police report if necessary",
                    "Follow up with RBC fraud department",
                    "Monitor your accounts regularly"
                ],
                estimatedTime: "Immediate action required",
                lastUpdated: Date().addingTimeInterval(-86400 * 7)
            )
        ]
    }
    
    private func setupSearchEngine() {
        // Index all knowledge content for search
        let allContent: [SearchableKnowledgeContent] = knowledgeArticles + faqItems + productInformation + policies + procedures
        searchEngine.indexContent(allContent)
    }
    
    private func setupPeriodicSync() {
        // Set up periodic knowledge base synchronization
        Timer.scheduledTimer(withTimeInterval: knowledgeSettings.syncInterval, repeats: true) { [weak self] _ in
            if self?.knowledgeSettings.enableAutoSync == true {
                Task {
                    await self?.syncKnowledgeBase()
                }
            }
        }
    }
    
    // MARK: - Search Functionality
    
    func searchKnowledge(_ query: String, filters: [SearchFilter] = []) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchResults = searchEngine.search(query: query, filters: filters)
    }
    
    func searchByCategory(_ category: KnowledgeCategoryType) -> [KnowledgeSearchResult] {
        return searchEngine.searchByCategory(category)
    }
    
    func searchByContentType(_ contentType: ContentType) -> [KnowledgeSearchResult] {
        return searchEngine.searchByContentType(contentType)
    }
    
    func getPopularArticles(_ limit: Int = 10) -> [KnowledgeArticle] {
        return knowledgeArticles
            .sorted { $0.views > $1.views }
            .prefix(limit)
            .map { $0 }
    }
    
    func getRecentUpdates(_ limit: Int = 10) -> [KnowledgeArticle] {
        return knowledgeArticles
            .sorted { $0.lastUpdated > $1.lastUpdated }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Content Management
    
    func addKnowledgeArticle(_ article: KnowledgeArticle) {
        knowledgeArticles.append(article)
        searchEngine.indexContent([article])
        updateCategoryArticleCount(category: article.category)
    }
    
    func updateKnowledgeArticle(_ article: KnowledgeArticle) {
        if let index = knowledgeArticles.firstIndex(where: { $0.id == article.id }) {
            knowledgeArticles[index] = article
            searchEngine.reindexContent([article])
        }
    }
    
    func removeKnowledgeArticle(_ articleId: String) {
        if let article = knowledgeArticles.first(where: { $0.id == articleId }) {
            knowledgeArticles.removeAll { $0.id == articleId }
            searchEngine.removeFromIndex(articleId)
            updateCategoryArticleCount(category: article.category, delta: -1)
        }
    }
    
    private func updateCategoryArticleCount(category: KnowledgeCategoryType, delta: Int = 1) {
        if let index = knowledgeCategories.firstIndex(where: { $0.type == category }) {
            knowledgeCategories[index].articleCount += delta
        }
    }
    
    // MARK: - Synchronization
    
    func syncKnowledgeBase() async -> Bool {
        guard isKnowledgeBaseEnabled && !isUpdating else { return false }
        
        isUpdating = true
        updateProgress = 0.0
        
        let syncSteps = [
            "Connecting to RBC knowledge servers...",
            "Downloading latest updates...",
            "Validating content integrity...",
            "Updating local knowledge base...",
            "Rebuilding search index..."
        ]
        
        for (index, step) in syncSteps.enumerated() {
            DispatchQueue.main.async {
                self.updateProgress = Double(index + 1) / Double(syncSteps.count)
            }
            
            // Simulate sync step
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        // Update knowledge content with latest from RBC
        await updateKnowledgeContent()
        
        isUpdating = false
        updateProgress = 0.0
        lastSyncTime = Date()
        
        saveKnowledgeSettings()
        
        return true
    }
    
    private func updateKnowledgeContent() async {
        // Simulate updating content from RBC servers
        for index in knowledgeArticles.indices {
            knowledgeArticles[index].lastUpdated = Date()
        }
        
        for index in faqItems.indices {
            faqItems[index].lastUpdated = Date()
        }
        
        for index in productInformation.indices {
            productInformation[index].lastUpdated = Date()
        }
    }
    
    // MARK: - Analytics and Feedback
    
    func recordArticleView(_ articleId: String) {
        if let index = knowledgeArticles.firstIndex(where: { $0.id == articleId }) {
            knowledgeArticles[index].views += 1
        }
    }
    
    func recordFeedback(_ articleId: String, helpful: Bool) {
        if let index = knowledgeArticles.firstIndex(where: { $0.id == articleId }) {
            if helpful {
                knowledgeArticles[index].helpful += 1
            } else {
                knowledgeArticles[index].notHelpful += 1
            }
        }
    }
    
    func recordFAQView(_ faqId: String) {
        if let index = faqItems.firstIndex(where: { $0.id == faqId }) {
            faqItems[index].views += 1
        }
    }
    
    func recordFAQFeedback(_ faqId: String, helpful: Bool) {
        if let index = faqItems.firstIndex(where: { $0.id == faqId }) {
            if helpful {
                faqItems[index].helpful += 1
            }
        }
    }
    
    // MARK: - Settings Management
    
    func updateKnowledgeSettings(_ settings: KnowledgeSettings) {
        knowledgeSettings = settings
        isKnowledgeBaseEnabled = settings.isEnabled
        saveKnowledgeSettings()
    }
    
    func enableKnowledgeBase() {
        isKnowledgeBaseEnabled = true
        knowledgeSettings.isEnabled = true
        saveKnowledgeSettings()
    }
    
    func disableKnowledgeBase() {
        isKnowledgeBaseEnabled = false
        knowledgeSettings.isEnabled = false
        saveKnowledgeSettings()
    }
    
    // MARK: - Analytics and Reporting
    
    func getKnowledgeBaseReport() -> KnowledgeBaseReport {
        let totalArticles = knowledgeArticles.count
        let totalFAQs = faqItems.count
        let totalProducts = productInformation.count
        let totalPolicies = policies.count
        let totalProcedures = procedures.count
        
        let totalViews = knowledgeArticles.map { $0.views }.reduce(0, +) + faqItems.map { $0.views }.reduce(0, +)
        let totalHelpful = knowledgeArticles.map { $0.helpful }.reduce(0, +) + faqItems.map { $0.helpful }.reduce(0, +)
        let totalNotHelpful = knowledgeArticles.map { $0.notHelpful }.reduce(0, +) + faqItems.map { $0.notHelpful }.reduce(0, +)
        
        let categoryBreakdown = KnowledgeCategoryType.allCases.map { category in
            CategoryKnowledgeStatistics(
                category: category,
                articleCount: knowledgeCategories.filter { $0.type == category }.first?.articleCount ?? 0,
                totalViews: knowledgeArticles.filter { $0.category == category }.map { $0.views }.reduce(0, +)
            )
        }
        
        let contentTypeBreakdown = ContentType.allCases.map { contentType in
            ContentTypeStatistics(
                type: contentType,
                articleCount: knowledgeArticles.filter { $0.contentType == contentType }.count,
                faqCount: faqItems.count // All FAQs are the same type
            )
        }
        
        return KnowledgeBaseReport(
            totalArticles: totalArticles,
            totalFAQs: totalFAQs,
            totalProducts: totalProducts,
            totalPolicies: totalPolicies,
            totalProcedures: totalProcedures,
            totalViews: totalViews,
            totalHelpful: totalHelpful,
            totalNotHelpful: totalNotHelpful,
            categoryBreakdown: categoryBreakdown,
            contentTypeBreakdown: contentTypeBreakdown,
            lastSyncTime: lastSyncTime,
            generatedAt: Date()
        )
    }
    
    deinit {
        // Clean up resources
    }
}

// MARK: - Supporting Classes

class RBCKnowledgeEngine {
    func processQuery(_ query: String) -> [KnowledgeSearchResult] {
        // Process natural language queries
        return []
    }
}

class KnowledgeSearchEngine {
    private var indexedContent: [String: SearchableKnowledgeContent] = [:]
    
    func indexContent(_ content: [SearchableKnowledgeContent]) {
        for item in content {
            indexedContent[item.id] = item
        }
    }
    
    func reindexContent(_ content: [SearchableKnowledgeContent]) {
        for item in content {
            indexedContent[item.id] = item
        }
    }
    
    func removeFromIndex(_ id: String) {
        indexedContent.removeValue(forKey: id)
    }
    
    func search(query: String, filters: [SearchFilter]) -> [KnowledgeSearchResult] {
        let lowercaseQuery = query.lowercased()
        
        return indexedContent.values.compactMap { content in
            var matches = content.title.lowercased().contains(lowercaseQuery) ||
                       content.description.lowercased().contains(lowercaseQuery)
            
            // Apply filters
            for filter in filters {
                switch filter {
                case .category(let category):
                    matches = matches && content.category == category
                case .contentType(let contentType):
                    matches = matches && content.contentType == contentType
                }
            }
            
            if matches {
                return KnowledgeSearchResult(
                    id: content.id,
                    title: content.title,
                    description: content.description,
                    category: content.category,
                    contentType: content.contentType,
                    relevance: calculateRelevance(content: content, query: lowercaseQuery)
                )
            }
            return nil
        }.sorted { $0.relevance > $1.relevance }
    }
    
    func searchByCategory(_ category: RBCKnowledgeBase.KnowledgeCategoryType) -> [KnowledgeSearchResult] {
        return indexedContent.values
            .filter { $0.category == category }
            .map { content in
                KnowledgeSearchResult(
                    id: content.id,
                    title: content.title,
                    description: content.description,
                    category: content.category,
                    contentType: content.contentType,
                    relevance: 1.0
                )
            }
    }
    
    func searchByContentType(_ contentType: RBCKnowledgeBase.ContentType) -> [KnowledgeSearchResult] {
        return indexedContent.values
            .filter { $0.contentType == contentType }
            .map { content in
                KnowledgeSearchResult(
                    id: content.id,
                    title: content.title,
                    description: content.description,
                    category: content.category,
                    contentType: content.contentType,
                    relevance: 1.0
                )
            }
    }
    
    private func calculateRelevance(content: SearchableKnowledgeContent, query: String) -> Double {
        let titleMatch = content.title.lowercased().contains(query) ? 1.0 : 0.0
        let descriptionMatch = content.description.lowercased().contains(query) ? 0.5 : 0.0
        
        return titleMatch + descriptionMatch
    }
}

class RBCSyncEngine {
    func syncFromRBC() async -> Bool {
        // Sync knowledge base from RBC servers
        return Bool.random()
    }
}

// MARK: - Protocols

protocol SearchableKnowledgeContent {
    var id: String { get }
    var title: String { get }
    var description: String { get }
    var category: RBCKnowledgeBase.KnowledgeCategoryType { get }
    var contentType: RBCKnowledgeBase.ContentType { get }
}

// MARK: - Data Structures

struct KnowledgeCategory: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let type: RBCKnowledgeBase.KnowledgeCategoryType
    var articleCount: Int
    var lastUpdated: Date
    var isActive: Bool
}

struct KnowledgeArticle: Identifiable, Codable, SearchableKnowledgeContent {
    let id: String
    let title: String
    let content: String
    let category: RBCKnowledgeBase.KnowledgeCategoryType
    let contentType: RBCKnowledgeBase.ContentType
    let author: String
    let publishDate: Date
    var lastUpdated: Date
    let tags: [String]
    var views: Int
    var helpful: Int
    var notHelpful: Int
    
    var description: String { return String(content.prefix(200)) }
}

struct FAQItem: Identifiable, Codable, SearchableKnowledgeContent {
    let id: String
    let question: String
    let answer: String
    let category: RBCKnowledgeBase.KnowledgeCategoryType
    var views: Int
    var helpful: Int
    var lastUpdated: Date
    
    var title: String { return question }
    var description: String { return String(answer.prefix(200)) }
    var contentType: RBCKnowledgeBase.ContentType { return .faq }
}

struct ProductInfo: Identifiable, Codable, SearchableKnowledgeContent {
    let id: String
    let name: String
    let description: String
    let category: RBCKnowledgeBase.KnowledgeCategoryType
    let type: String
    let features: [String]
    let fees: [String]
    let requirements: [String]
    var lastUpdated: Date
    
    var title: String { return name }
    var contentType: RBCKnowledgeBase.ContentType { return .reference }
}

struct RBCPolicy: Identifiable, Codable, SearchableKnowledgeContent {
    let id: String
    let title: String
    let description: String
    let category: RBCKnowledgeBase.KnowledgeCategoryType
    let effectiveDate: Date
    var lastUpdated: Date
    let content: String
    let version: String
    
    var contentType: RBCKnowledgeBase.ContentType { return .policy }
}

struct RBCProcedure: Identifiable, Codable, SearchableKnowledgeContent {
    let id: String
    let title: String
    let description: String
    let category: RBCKnowledgeBase.KnowledgeCategoryType
    let steps: [String]
    let estimatedTime: String
    var lastUpdated: Date
    
    var contentType: RBCKnowledgeBase.ContentType { return .procedure }
}

struct KnowledgeSearchResult: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: RBCKnowledgeBase.KnowledgeCategoryType
    let contentType: RBCKnowledgeBase.ContentType
    let relevance: Double
}

enum SearchFilter {
    case category(RBCKnowledgeBase.KnowledgeCategoryType)
    case contentType(RBCKnowledgeBase.ContentType)
}

struct KnowledgeSettings: Codable {
    var isEnabled: Bool = true
    var enableAutoSync: Bool = true
    var syncInterval: TimeInterval = 86400 // 24 hours
    var enableSearchIndexing: Bool = true
    var enableAnalytics: Bool = true
    var enableFeedback: Bool = true
    var maxSearchResults: Int = 50
    var enableContentCaching: Bool = true
    var cacheExpiryTime: TimeInterval = 3600 // 1 hour
}

struct CategoryKnowledgeStatistics: Identifiable, Codable {
    let id = UUID()
    let category: RBCKnowledgeBase.KnowledgeCategoryType
    let articleCount: Int
    let totalViews: Int
}

struct ContentTypeStatistics: Identifiable, Codable {
    let id = UUID()
    let type: RBCKnowledgeBase.ContentType
    let articleCount: Int
    let faqCount: Int
}

struct KnowledgeBaseReport {
    let totalArticles: Int
    let totalFAQs: Int
    let totalProducts: Int
    let totalPolicies: Int
    let totalProcedures: Int
    let totalViews: Int
    let totalHelpful: Int
    let totalNotHelpful: Int
    let categoryBreakdown: [CategoryKnowledgeStatistics]
    let contentTypeBreakdown: [ContentTypeStatistics]
    let lastSyncTime: Date?
    let generatedAt: Date
}
