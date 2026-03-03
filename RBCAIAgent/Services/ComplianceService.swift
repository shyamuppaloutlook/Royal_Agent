import Foundation
import SwiftUI
import Combine

class ComplianceService: ObservableObject {
    @Published var complianceStatus: ComplianceStatus = .compliant
    @Published var complianceScore: Double = 100.0
    @Published var complianceIssues: [ComplianceIssue] = []
    @Published var complianceReports: [ComplianceReport] = []
    @Published var auditLogs: [AuditLog] = []
    @Published var regulatoryFrameworks: [RegulatoryFramework] = []
    @Published var activePolicies: [CompliancePolicy] = []
    @Published var complianceSettings: ComplianceSettings = ComplianceSettings()
    @Published var isAuditing: Bool = false
    @Published var auditProgress: Double = 0.0
    @Published var lastAuditDate: Date?
    @Published var nextAuditDate: Date?
    @Published var complianceMetrics: ComplianceMetrics = ComplianceMetrics()
    
    private let complianceQueue = DispatchQueue(label: "com.rbc.compliance", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private var auditTimer: Timer?
    
    // MARK: - Compliance Status
    
    enum ComplianceStatus: String, CaseIterable {
        case compliant = "Compliant"
        case nonCompliant = "Non-Compliant"
        case pending = "Pending"
        case underReview = "Under Review"
        case exempt = "Exempt"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .compliant: return .green
            case .nonCompliant: return .red
            case .pending: return .yellow
            case .underReview: return .orange
            case .exempt: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .compliant: return "checkmark.shield"
            case .nonCompliant: return "xmark.shield"
            case .pending: return "clock"
            case .underReview: return "magnifyingglass"
            case .exempt: return "minus.circle"
            }
        }
    }
    
    // MARK: - Compliance Categories
    
    enum ComplianceCategory: String, CaseIterable {
        case dataPrivacy = "Data Privacy"
        case financial = "Financial"
        case security = "Security"
        case operational = "Operational"
        case regulatory = "Regulatory"
        case ethical = "Ethical"
        case environmental = "Environmental"
        case accessibility = "Accessibility"
        
        var id: String { return rawValue }
        
        var displayName: String {
            switch self {
            case .dataPrivacy: return "Data Privacy"
            case .financial: return "Financial"
            case .security: return "Security"
            case .operational: return "Operational"
            case .regulatory: return "Regulatory"
            case .ethical: return "Ethical"
            case .environmental: return "Environmental"
            case .accessibility: return "Accessibility"
            }
        }
        
        var icon: String {
            switch self {
            case .dataPrivacy: return "lock.shield"
            case .financial: return "banknote"
            case .security: return "shield.leopard.up"
            case .operational: return "gear"
            case .regulatory: return "doc.text"
            case .ethical: return "heart"
            case .environmental: return "leaf"
            case .accessibility: return "person.wave"
            }
        }
    }
    
    // MARK: - Issue Severity
    
    enum IssueSeverity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var score: Double {
            switch self {
            case .low: return 5.0
            case .medium: return 15.0
            case .high: return 25.0
            case .critical: return 40.0
            }
        }
    }
    
    // MARK: - Regulatory Frameworks
    
    enum RegulatoryFramework: String, CaseIterable, Identifiable {
        case gdpr = "GDPR"
        case ccpa = "CCPA"
        case hipaa = "HIPAA"
        case sox = "SOX"
        case pciDss = "PCI DSS"
        case baselIII = "Basel III"
        case doddFrank = "Dodd-Frank"
        case miFIDII = "MiFID II"
        case aml = "AML"
        case kyc = "KYC"
        
        var id: String { return rawValue }
        
        var fullName: String {
            switch self {
            case .gdpr: return "General Data Protection Regulation"
            case .ccpa: return "California Consumer Privacy Act"
            case .hipaa: return "Health Insurance Portability and Accountability Act"
            case .sox: return "Sarbanes-Oxley Act"
            case .pciDss: return "Payment Card Industry Data Security Standard"
            case .baselIII: return "Basel III Accord"
            case .doddFrank: return "Dodd-Frank Wall Street Reform"
            case .miFIDII: return "Markets in Financial Instruments Directive II"
            case .aml: return "Anti-Money Laundering"
            case .kyc: return "Know Your Customer"
            }
        }
        
        var description: String {
            switch self {
            case .gdpr: return "EU data protection and privacy regulation"
            case .ccpa: return "California state privacy law"
            case .hipaa: return "US healthcare data protection law"
            case .sox: return "US corporate governance and financial disclosure"
            case .pciDss: return "Payment card security standards"
            case .baselIII: return "International banking regulation"
            case .doddFrank: return "US financial services regulation"
            case .miFIDII: return "EU financial markets regulation"
            case .aml: return "Anti-money laundering regulations"
            case .kyc: return "Customer identification and verification"
            }
        }
        
        var region: String {
            switch self {
            case .gdpr, .miFIDII, .baselIII: return "EU"
            case .ccpa, .hipaa, .sox, .doddFrank, .pciDss, .aml, .kyc: return "US"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupComplianceService()
        loadComplianceSettings()
        loadRegulatoryFrameworks()
        loadCompliancePolicies()
        setupAuditTimer()
        performInitialAudit()
    }
    
    private func setupComplianceService() {
        // Initialize compliance service
        // Set up default settings
    }
    
    private func loadComplianceSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "compliance_settings"),
           let settings = try? JSONDecoder().decode(ComplianceSettings.self, from: data) {
            complianceSettings = settings
        }
        
        if let date = defaults.object(forKey: "last_audit_date") as? Date {
            lastAuditDate = date
        }
        
        if let date = defaults.object(forKey: "next_audit_date") as? Date {
            nextAuditDate = date
        }
    }
    
    private func saveComplianceSettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(complianceSettings) {
            defaults.set(data, forKey: "compliance_settings")
        }
        
        if let date = lastAuditDate {
            defaults.set(date, forKey: "last_audit_date")
        }
        
        if let date = nextAuditDate {
            defaults.set(date, forKey: "next_audit_date")
        }
    }
    
    private func loadRegulatoryFrameworks() {
        regulatoryFrameworks = RegulatoryFramework.allCases.map { framework in
            RegulatoryFrameworkDetails(
                framework: framework,
                isActive: true,
                complianceLevel: 0.8,
                lastReviewed: Date(),
                nextReview: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                requirements: getFrameworkRequirements(framework),
                exemptions: []
            )
        }
    }
    
    private func getFrameworkRequirements(_ framework: RegulatoryFramework) -> [ComplianceRequirement] {
        switch framework {
        case .gdpr:
            return [
                ComplianceRequirement(id: "1", name: "Data Consent", description: "Obtain explicit consent for data processing", mandatory: true),
                ComplianceRequirement(id: "2", name: "Data Portability", description: "Provide data export capabilities", mandatory: true),
                ComplianceRequirement(id: "3", name: "Right to Erasure", description: "Allow users to delete their data", mandatory: true),
                ComplianceRequirement(id: "4", name: "Breach Notification", description: "Notify authorities within 72 hours", mandatory: true)
            ]
        case .ccpa:
            return [
                ComplianceRequirement(id: "1", name: "Right to Know", description: "Disclose data collection practices", mandatory: true),
                ComplianceRequirement(id: "2", name: "Right to Delete", description: "Delete personal data on request", mandatory: true),
                ComplianceRequirement(id: "3", name: "Opt-out Sale", description: "Allow users to opt-out of data sale", mandatory: true),
                ComplianceRequirement(id: "4", name: "Non-discrimination", description: "Don't discriminate for privacy choices", mandatory: true)
            ]
        case .hipaa:
            return [
                ComplianceRequirement(id: "1", name: "Privacy Rule", description: "Protect PHI privacy", mandatory: true),
                ComplianceRequirement(id: "2", name: "Security Rule", description: "Protect PHI security", mandatory: true),
                ComplianceRequirement(id: "3", name: "Breach Notification", description: "Notify breaches within 60 days", mandatory: true),
                ComplianceRequirement(id: "4", name: "Access Controls", description: "Implement access controls", mandatory: true)
            ]
        default:
            return []
        }
    }
    
    private func loadCompliancePolicies() {
        activePolicies = [
            CompliancePolicy(
                id: "data_protection",
                name: "Data Protection Policy",
                category: .dataPrivacy,
                description: "Comprehensive data protection and privacy policy",
                version: "1.0",
                effectiveDate: Date(),
                reviewDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                requirements: [
                    ComplianceRequirement(id: "1", name: "Encryption", description: "Encrypt sensitive data", mandatory: true),
                    ComplianceRequirement(id: "2", name: "Access Control", description: "Implement role-based access", mandatory: true),
                    ComplianceRequirement(id: "3", name: "Data Retention", description: "Define data retention periods", mandatory: true)
                ],
                isActive: true
            ),
            CompliancePolicy(
                id: "financial_compliance",
                name: "Financial Compliance Policy",
                category: .financial,
                description: "Financial regulations and reporting requirements",
                version: "1.0",
                effectiveDate: Date(),
                reviewDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                requirements: [
                    ComplianceRequirement(id: "1", name: "Transaction Monitoring", description: "Monitor all transactions", mandatory: true),
                    ComplianceRequirement(id: "2", name: "Reporting", description: "Generate compliance reports", mandatory: true),
                    ComplianceRequirement(id: "3", name: "Record Keeping", description: "Maintain accurate records", mandatory: true)
                ],
                isActive: true
            )
        ]
    }
    
    private func setupAuditTimer() {
        auditTimer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
            self?.checkScheduledAudit()
        }
    }
    
    private func checkScheduledAudit() {
        guard let nextAudit = nextAuditDate else { return }
        
        if Date() >= nextAudit {
            performComplianceAudit()
        }
    }
    
    private func performInitialAudit() {
        performComplianceAudit()
    }
    
    // MARK: - Compliance Auditing
    
    func performComplianceAudit() {
        isAuditing = true
        auditProgress = 0.0
        
        complianceQueue.async {
            let auditResult = self.performAuditProcess()
            
            DispatchQueue.main.async {
                self.processAuditResult(auditResult)
            }
        }
    }
    
    private func performAuditProcess() -> AuditResult {
        let startTime = Date()
        var issues: [ComplianceIssue] = []
        var categoryResults: [ComplianceCategory: CategoryAuditResult] = [:]
        
        let categories = ComplianceCategory.allCases
        
        for (index, category) in categories.enumerated() {
            DispatchQueue.main.async {
                self.auditProgress = Double(index + 1) / Double(categories.count)
            }
            
            let result = auditCategory(category)
            categoryResults[category] = result
            issues.append(contentsOf: result.issues)
            
            // Add delay between category audits
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let score = calculateComplianceScore(issues: issues)
        
        return AuditResult(
            startTime: startTime,
            endTime: Date(),
            duration: duration,
            score: score,
            issues: issues,
            categoryResults: categoryResults,
            recommendations: generateRecommendations(issues: issues)
        )
    }
    
    private func auditCategory(_ category: ComplianceCategory) -> CategoryAuditResult {
        var issues: [ComplianceIssue] = []
        var score: Double = 100.0
        
        switch category {
        case .dataPrivacy:
            let privacyIssues = auditDataPrivacy()
            issues.append(contentsOf: privacyIssues)
            
        case .financial:
            let financialIssues = auditFinancialCompliance()
            issues.append(contentsOf: financialIssues)
            
        case .security:
            let securityIssues = auditSecurityCompliance()
            issues.append(contentsOf: securityIssues)
            
        case .operational:
            let operationalIssues = auditOperationalCompliance()
            issues.append(contentsOf: operationalIssues)
            
        case .regulatory:
            let regulatoryIssues = auditRegulatoryCompliance()
            issues.append(contentsOf: regulatoryIssues)
            
        case .ethical:
            let ethicalIssues = auditEthicalCompliance()
            issues.append(contentsOf: ethicalIssues)
            
        case .environmental:
            let environmentalIssues = auditEnvironmentalCompliance()
            issues.append(contentsOf: environmentalIssues)
            
        case .accessibility:
            let accessibilityIssues = auditAccessibilityCompliance()
            issues.append(contentsOf: accessibilityIssues)
        }
        
        // Calculate category score
        for issue in issues {
            score -= issue.severity.score
        }
        
        score = max(0.0, score)
        
        return CategoryAuditResult(
            category: category,
            score: score,
            issues: issues,
            auditedAt: Date()
        )
    }
    
    private func auditDataPrivacy() -> [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // Check data consent
        if !checkDataConsent() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .dataPrivacy,
                severity: .high,
                title: "Data Consent Missing",
                description: "Explicit data consent is not obtained from users",
                recommendation: "Implement consent management system",
                framework: .gdpr,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        // Check data encryption
        if !checkDataEncryption() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .dataPrivacy,
                severity: .critical,
                title: "Data Encryption Missing",
                description: "Sensitive data is not properly encrypted",
                recommendation: "Implement end-to-end encryption",
                framework: .gdpr,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        // Check data retention
        if !checkDataRetention() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .dataPrivacy,
                severity: .medium,
                title: "Data Retention Policy Missing",
                description: "No clear data retention policy is defined",
                recommendation: "Define and implement data retention policy",
                framework: .gdpr,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        return issues
    }
    
    private func auditFinancialCompliance() -> [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // Check transaction monitoring
        if !checkTransactionMonitoring() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .financial,
                severity: .high,
                title: "Transaction Monitoring Incomplete",
                description: "Not all transactions are properly monitored",
                recommendation: "Implement comprehensive transaction monitoring",
                framework: .aml,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        // Check reporting requirements
        if !checkReportingRequirements() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .financial,
                severity: .medium,
                title: "Reporting Requirements Not Met",
                description: "Some financial reports are missing or incomplete",
                recommendation: "Ensure all required reports are generated",
                framework: .sox,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        return issues
    }
    
    private func auditSecurityCompliance() -> [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // Check access controls
        if !checkAccessControls() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .security,
                severity: .high,
                title: "Access Controls Weak",
                description: "Access controls are not properly implemented",
                recommendation: "Strengthen access control mechanisms",
                framework: .pciDss,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        // Check security monitoring
        if !checkSecurityMonitoring() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .security,
                severity: .medium,
                title: "Security Monitoring Inadequate",
                description: "Security monitoring is insufficient",
                recommendation: "Implement comprehensive security monitoring",
                framework: .pciDss,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        return issues
    }
    
    private func auditOperationalCompliance() -> [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // Check operational procedures
        if !checkOperationalProcedures() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .operational,
                severity: .low,
                title: "Operational Procedures Outdated",
                description: "Some operational procedures need updating",
                recommendation: "Review and update operational procedures",
                framework: .sox,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        return issues
    }
    
    private func auditRegulatoryCompliance() -> [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // Check regulatory reporting
        if !checkRegulatoryReporting() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .regulatory,
                severity: .high,
                title: "Regulatory Reporting Incomplete",
                description: "Required regulatory reports are missing",
                recommendation: "Complete all required regulatory reports",
                framework: .doddFrank,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        return issues
    }
    
    private func auditEthicalCompliance() -> [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // Check ethical guidelines
        if !checkEthicalGuidelines() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .ethical,
                severity: .medium,
                title: "Ethical Guidelines Not Followed",
                description: "Some practices may not align with ethical guidelines",
                recommendation: "Review and improve ethical practices",
                framework: .sox,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        return issues
    }
    
    private func auditEnvironmentalCompliance() -> [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // Check environmental impact
        if !checkEnvironmentalImpact() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .environmental,
                severity: .low,
                title: "Environmental Impact Assessment Needed",
                description: "Environmental impact assessment is outdated",
                recommendation: "Conduct new environmental impact assessment",
                framework: .sox,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        return issues
    }
    
    private func auditAccessibilityCompliance() -> [ComplianceIssue] {
        var issues: [ComplianceIssue] = []
        
        // Check accessibility features
        if !checkAccessibilityFeatures() {
            issues.append(ComplianceIssue(
                id: UUID().uuidString,
                category: .accessibility,
                severity: .medium,
                title: "Accessibility Features Incomplete",
                description: "Some accessibility features are missing",
                recommendation: "Implement missing accessibility features",
                framework: .sox,
                detectedAt: Date(),
                resolved: false
            ))
        }
        
        return issues
    }
    
    // MARK: - Compliance Check Methods
    
    private func checkDataConsent() -> Bool {
        // Simulate data consent check
        return Bool.random()
    }
    
    private func checkDataEncryption() -> Bool {
        // Simulate data encryption check
        return Bool.random()
    }
    
    private func checkDataRetention() -> Bool {
        // Simulate data retention check
        return Bool.random()
    }
    
    private func checkTransactionMonitoring() -> Bool {
        // Simulate transaction monitoring check
        return Bool.random()
    }
    
    private func checkReportingRequirements() -> Bool {
        // Simulate reporting requirements check
        return Bool.random()
    }
    
    private func checkAccessControls() -> Bool {
        // Simulate access controls check
        return Bool.random()
    }
    
    private func checkSecurityMonitoring() -> Bool {
        // Simulate security monitoring check
        return Bool.random()
    }
    
    private func checkOperationalProcedures() -> Bool {
        // Simulate operational procedures check
        return Bool.random()
    }
    
    private func checkRegulatoryReporting() -> Bool {
        // Simulate regulatory reporting check
        return Bool.random()
    }
    
    private func checkEthicalGuidelines() -> Bool {
        // Simulate ethical guidelines check
        return Bool.random()
    }
    
    private func checkEnvironmentalImpact() -> Bool {
        // Simulate environmental impact check
        return Bool.random()
    }
    
    private func checkAccessibilityFeatures() -> Bool {
        // Simulate accessibility features check
        return Bool.random()
    }
    
    private func calculateComplianceScore(issues: [ComplianceIssue]) -> Double {
        var score = 100.0
        
        for issue in issues {
            score -= issue.severity.score
        }
        
        return max(0.0, score)
    }
    
    private func generateRecommendations(issues: [ComplianceIssue]) -> [ComplianceRecommendation] {
        return issues.map { issue in
            ComplianceRecommendation(
                id: UUID().uuidString,
                title: "Fix \(issue.title)",
                description: issue.description,
                priority: issue.severity,
                action: issue.recommendation,
                estimatedCost: estimateCost(issue),
                estimatedTime: estimateTime(issue),
                framework: issue.framework
            )
        }
    }
    
    private func estimateCost(_ issue: ComplianceIssue) -> String {
        switch issue.severity {
        case .low: return "$1,000 - $5,000"
        case .medium: return "$5,000 - $20,000"
        case .high: return "$20,000 - $100,000"
        case .critical: return "$100,000+"
        }
    }
    
    private func estimateTime(_ issue: ComplianceIssue) -> String {
        switch issue.severity {
        case .low: return "1-2 weeks"
        case .medium: return "2-4 weeks"
        case .high: return "1-3 months"
        case .critical: return "3+ months"
        }
    }
    
    private func processAuditResult(_ result: AuditResult) {
        isAuditing = false
        auditProgress = 1.0
        lastAuditDate = result.endTime
        
        // Update compliance status and score
        complianceScore = result.score
        complianceIssues = result.issues
        
        if result.score >= 90.0 {
            complianceStatus = .compliant
        } else if result.score >= 70.0 {
            complianceStatus = .pending
        } else {
            complianceStatus = .nonCompliant
        }
        
        // Create compliance report
        let report = ComplianceReport(
            id: UUID().uuidString,
            auditDate: result.startTime,
            score: result.score,
            status: complianceStatus,
            issues: result.issues,
            recommendations: result.recommendations,
            categoryResults: result.categoryResults,
            generatedAt: result.endTime
        )
        
        complianceReports.append(report)
        
        // Log audit
        let log = AuditLog(
            id: UUID().uuidString,
            type: .audit,
            timestamp: result.startTime,
            details: "Compliance audit completed with score: \(result.score)",
            severity: result.score >= 90.0 ? .info : .warning
        )
        
        auditLogs.append(log)
        
        // Update metrics
        updateComplianceMetrics()
        
        // Schedule next audit
        scheduleNextAudit()
        
        saveComplianceSettings()
    }
    
    private func updateComplianceMetrics() {
        let totalAudits = complianceReports.count
        let averageScore = complianceReports.isEmpty ? 0 : complianceReports.map { $0.score }.reduce(0, +) / Double(totalAudits)
        let totalIssues = complianceIssues.count
        let criticalIssues = complianceIssues.filter { $0.severity == .critical }.count
        let highIssues = complianceIssues.filter { $0.severity == .high }.count
        
        complianceMetrics = ComplianceMetrics(
            totalAudits: totalAudits,
            averageScore: averageScore,
            totalIssues: totalIssues,
            criticalIssues: criticalIssues,
            highIssues: highIssues,
            lastAuditDate: lastAuditDate,
            nextAuditDate: nextAuditDate
        )
    }
    
    private func scheduleNextAudit() {
        nextAuditDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
    }
    
    // MARK: - Issue Management
    
    func resolveIssue(_ issueId: String) {
        if let index = complianceIssues.firstIndex(where: { $0.id == issueId }) {
            complianceIssues[index].resolved = true
            complianceIssues[index].resolvedAt = Date()
            
            // Recalculate compliance score
            complianceScore = calculateComplianceScore(issues: complianceIssues.filter { !$0.resolved })
            
            // Update compliance status
            if complianceScore >= 90.0 {
                complianceStatus = .compliant
            } else if complianceScore >= 70.0 {
                complianceStatus = .pending
            } else {
                complianceStatus = .nonCompliant
            }
            
            // Log resolution
            let log = AuditLog(
                id: UUID().uuidString,
                type: .issueResolution,
                timestamp: Date(),
                details: "Compliance issue resolved: \(issueId)",
                severity: .info
            )
            
            auditLogs.append(log)
            
            updateComplianceMetrics()
            saveComplianceSettings()
        }
    }
    
    func createIssue(_ issue: ComplianceIssue) {
        complianceIssues.append(issue)
        
        // Recalculate compliance score
        complianceScore = calculateComplianceScore(issues: complianceIssues.filter { !$0.resolved })
        
        // Update compliance status
        if complianceScore >= 90.0 {
            complianceStatus = .compliant
        } else if complianceScore >= 70.0 {
            complianceStatus = .pending
        } else {
            complianceStatus = .nonCompliant
        }
        
        // Log issue creation
        let log = AuditLog(
            id: UUID().uuidString,
            type: .issueDetection,
            timestamp: Date(),
            details: "Compliance issue detected: \(issue.title)",
            severity: .warning
        )
        
        auditLogs.append(log)
        
        updateComplianceMetrics()
        saveComplianceSettings()
    }
    
    // MARK: - Public Interface
    
    func getIssues(for category: ComplianceCategory) -> [ComplianceIssue] {
        return complianceIssues.filter { $0.category == category && !$0.resolved }
    }
    
    func getIssues(for framework: RegulatoryFramework) -> [ComplianceIssue] {
        return complianceIssues.filter { $0.framework == framework && !$0.resolved }
    }
    
    func getIssues(for severity: IssueSeverity) -> [ComplianceIssue] {
        return complianceIssues.filter { $0.severity == severity && !$0.resolved }
    }
    
    func getFrameworkCompliance(_ framework: RegulatoryFramework) -> Double {
        let frameworkIssues = getIssues(for: framework)
        var score = 100.0
        
        for issue in frameworkIssues {
            score -= issue.severity.score
        }
        
        return max(0.0, score)
    }
    
    func getCategoryCompliance(_ category: ComplianceCategory) -> Double {
        let categoryIssues = getIssues(for: category)
        var score = 100.0
        
        for issue in categoryIssues {
            score -= issue.severity.score
        }
        
        return max(0.0, score)
    }
    
    func generateComplianceReport() -> ComplianceReport {
        return ComplianceReport(
            id: UUID().uuidString,
            auditDate: Date(),
            score: complianceScore,
            status: complianceStatus,
            issues: complianceIssues.filter { !$0.resolved },
            recommendations: generateRecommendations(issues: complianceIssues.filter { !$0.resolved }),
            categoryResults: [:],
            generatedAt: Date()
        )
    }
    
    func exportComplianceData() -> ComplianceExport {
        return ComplianceExport(
            settings: complianceSettings,
            frameworks: regulatoryFrameworks,
            policies: activePolicies,
            issues: complianceIssues,
            reports: complianceReports,
            auditLogs: auditLogs,
            metrics: complianceMetrics,
            exportedAt: Date()
        )
    }
    
    func importComplianceData(_ export: ComplianceExport) {
        complianceSettings = export.settings
        regulatoryFrameworks = export.frameworks
        activePolicies = export.policies
        complianceIssues = export.issues
        complianceReports = export.reports
        auditLogs = export.auditLogs
        complianceMetrics = export.metrics
        
        saveComplianceSettings()
    }
    
    deinit {
        auditTimer?.invalidate()
    }
}

// MARK: - Data Structures

struct ComplianceIssue: Identifiable, Codable {
    let id: String
    let category: ComplianceService.ComplianceCategory
    let severity: ComplianceService.IssueSeverity
    let title: String
    let description: String
    let recommendation: String
    let framework: ComplianceService.RegulatoryFramework
    let detectedAt: Date
    var resolved: Bool
    var resolvedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, category, severity, title, description, recommendation
        case framework, detectedAt, resolved, resolvedAt
    }
}

struct ComplianceRecommendation: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let priority: ComplianceService.IssueSeverity
    let action: String
    let estimatedCost: String
    let estimatedTime: String
    let framework: ComplianceService.RegulatoryFramework
}

struct CompliancePolicy: Identifiable, Codable {
    let id: String
    let name: String
    let category: ComplianceService.ComplianceCategory
    let description: String
    let version: String
    let effectiveDate: Date
    let reviewDate: Date
    let requirements: [ComplianceRequirement]
    var isActive: Bool
}

struct ComplianceRequirement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let mandatory: Bool
}

struct RegulatoryFrameworkDetails: Identifiable, Codable {
    let framework: ComplianceService.RegulatoryFramework
    var isActive: Bool
    var complianceLevel: Double
    var lastReviewed: Date
    var nextReview: Date
    let requirements: [ComplianceRequirement]
    var exemptions: [String]
    
    var id: String { return framework.rawValue }
}

struct ComplianceSettings: Codable {
    var enableAutoAudit: Bool = true
    var auditFrequency: TimeInterval = 2592000.0 // 30 days
    var enableNotifications: Bool = true
    var enableReporting: Bool = true
    var enableLogging: Bool = true
    var maxAuditHistory: Int = 100
    var enableRiskAssessment: Bool = true
    var enableComplianceTraining: Bool = true
    var trainingFrequency: TimeInterval = 7776000.0 // 90 days
}

struct AuditResult {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let score: Double
    let issues: [ComplianceIssue]
    let categoryResults: [ComplianceService.ComplianceCategory: CategoryAuditResult]
    let recommendations: [ComplianceRecommendation]
}

struct CategoryAuditResult {
    let category: ComplianceService.ComplianceCategory
    let score: Double
    let issues: [ComplianceIssue]
    let auditedAt: Date
}

struct ComplianceReport: Identifiable, Codable {
    let id: String
    let auditDate: Date
    let score: Double
    let status: ComplianceService.ComplianceStatus
    let issues: [ComplianceIssue]
    let recommendations: [ComplianceRecommendation]
    let categoryResults: [ComplianceService.ComplianceCategory: CategoryAuditResult]
    let generatedAt: Date
}

struct AuditLog: Identifiable, Codable {
    let id: String
    let type: AuditLogType
    let timestamp: Date
    let details: String
    let severity: LogSeverity
    
    enum AuditLogType: String, CaseIterable, Codable {
        case audit = "Audit"
        case issueDetection = "Issue Detection"
        case issueResolution = "Issue Resolution"
        case policyUpdate = "Policy Update"
        case frameworkUpdate = "Framework Update"
        case reportGeneration = "Report Generation"
    }
    
    enum LogSeverity: String, CaseIterable, Codable {
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
        case critical = "Critical"
    }
}

struct ComplianceMetrics: Codable {
    var totalAudits: Int = 0
    var averageScore: Double = 0.0
    var totalIssues: Int = 0
    var criticalIssues: Int = 0
    var highIssues: Int = 0
    var lastAuditDate: Date?
    var nextAuditDate: Date?
}

struct ComplianceExport: Codable {
    let settings: ComplianceSettings
    let frameworks: [RegulatoryFrameworkDetails]
    let policies: [CompliancePolicy]
    let issues: [ComplianceIssue]
    let reports: [ComplianceReport]
    let auditLogs: [AuditLog]
    let metrics: ComplianceMetrics
    let exportedAt: Date
}
