import SwiftUI
import AVFoundation
import CallKit

struct CallSummaryView: View {
    let voiceCallService: VoiceCallService
    let callRecord: VoiceCallRecord
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    @State private var showingSaveOptions = false
    @State private var selectedSaveOption: SaveOption? = nil
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Summary
                    headerSummaryView
                    
                    // Call Metrics
                    callMetricsView
                    
                    // Conversation Summary
                    conversationSummaryView
                    
                    // Key Topics Discussed
                    keyTopicsView
                    
                    // Action Items
                    actionItemsView
                    
                    // AI Insights
                    aiInsightsView
                    
                    // Follow-up Suggestions
                    followUpSuggestionsView
                    
                    // Export Options
                    exportOptionsView
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Call Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        showingShareSheet = true
                    }
                    .disabled(isSaving)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [generateShareText()])
            }
            .actionSheet(isPresented: $showingSaveOptions) {
                ActionSheet(
                    title: Text("Save Summary"),
                    message: Text("Choose where to save this call summary"),
                    buttons: SaveOption.allCases.map { option in
                        .default(Text(option.title)) {
                            selectedSaveOption = option
                            saveSummary(option)
                        }
                    } + [.cancel()]
                )
            }
        }
    }
    
    // MARK: - Header Summary
    
    private var headerSummaryView: some View {
        VStack(spacing: 16) {
            // Success Indicator
            ZStack {
                Circle()
                    .fill(callRecord.wasSuccessful ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: callRecord.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(callRecord.wasSuccessful ? .green : .red)
            }
            
            VStack(spacing: 8) {
                Text(callRecord.wasSuccessful ? "Successful Call" : "Call Incomplete")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(callRecord.wasSuccessful ? .green : .red)
                
                Text(callRecord.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 20) {
                    Label(callRecord.formattedDuration, systemImage: "clock")
                    Label(callRecord.callQuality.rawValue, systemImage: "cellularbars")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Call Metrics
    
    private var callMetricsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Call Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Total Words",
                    value: "\(wordCount(callRecord.transcription))",
                    icon: "textformat",
                    color: .blue
                )
                
                MetricCard(
                    title: "Response Time",
                    value: averageResponseTime(),
                    icon: "clock.arrow.circlepath",
                    color: .green
                )
                
                MetricCard(
                    title: "Topics Covered",
                    value: "\(extractTopics().count)",
                    icon: "tag",
                    color: .orange
                )
                
                MetricCard(
                    title: "Actions Taken",
                    value: "\(extractActionItems().count)",
                    icon: "checkmark.square",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Conversation Summary
    
    private var conversationSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conversation Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                SummaryRow(
                    title: "Main Purpose",
                    content: extractMainPurpose(),
                    icon: "target",
                    color: .blue
                )
                
                SummaryRow(
                    title: "Key Outcome",
                    content: extractKeyOutcome(),
                    icon: "flag",
                    color: .green
                )
                
                SummaryRow(
                    title: "User Sentiment",
                    content: analyzeSentiment(),
                    icon: "face.dashed",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Key Topics
    
    private var keyTopicsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Topics Discussed")
                .font(.headline)
                .fontWeight(.semibold)
            
            let topics = extractTopics()
            
            if topics.isEmpty {
                Text("No specific topics identified")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(topics, id: \.self) { topic in
                        TopicChip(topic: topic)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Items
    
    private var actionItemsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action Items")
                .font(.headline)
                .fontWeight(.semibold)
            
            let actionItems = extractActionItems()
            
            if actionItems.isEmpty {
                Text("No action items identified")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(Array(actionItems.enumerated()), id: \.offset) { index, item in
                    ActionItemRow(index: index + 1, item: item)
                }
            }
        }
    }
    
    // MARK: - AI Insights
    
    private var aiInsightsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InsightRow(
                    title: "Communication Pattern",
                    insight: analyzeCommunicationPattern(),
                    icon: "waveform.path",
                    color: .blue
                )
                
                InsightRow(
                    title: "User Engagement",
                    insight: analyzeUserEngagement(),
                    icon: "person.2",
                    color: .green
                )
                
                InsightRow(
                    title: "Recommendation",
                    insight: generateRecommendation(),
                    icon: "lightbulb",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Follow-up Suggestions
    
    private var followUpSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow-up Suggestions")
                .font(.headline)
                .fontWeight(.semibold)
            
            let suggestions = generateFollowUpSuggestions()
            
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                FollowUpRow(index: index + 1, suggestion: suggestion)
            }
        }
    }
    
    // MARK: - Export Options
    
    private var exportOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(SaveOption.allCases, id: \.self) { option in
                    ExportOptionButton(
                        option: option,
                        isSaving: isSaving && selectedSaveOption == option
                    ) {
                        selectedSaveOption = option
                        saveSummary(option)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func wordCount(_ text: String) -> Int {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    private func averageResponseTime() -> String {
        // Simulate response time calculation
        return "1.2s"
    }
    
    private func extractMainPurpose() -> String {
        let text = callRecord.transcription.lowercased()
        
        if text.contains("balance") {
            return "Account balance inquiry"
        } else if text.contains("transfer") {
            return "Money transfer request"
        } else if text.contains("bill") || text.contains("payment") {
            return "Bill payment inquiry"
        } else if text.contains("help") {
            return "General assistance request"
        } else if text.contains("transaction") {
            return "Transaction history request"
        } else if text.contains("investment") {
            return "Investment information inquiry"
        } else {
            return "General banking consultation"
        }
    }
    
    private func extractKeyOutcome() -> String {
        if callRecord.wasSuccessful {
            return "User received appropriate assistance and information"
        } else {
            return "Call ended without resolution - may require follow-up"
        }
    }
    
    private func analyzeSentiment() -> String {
        let text = callRecord.transcription.lowercased()
        
        if text.contains("thank") || text.contains("great") || text.contains("good") {
            return "Positive - User expressed satisfaction"
        } else if text.contains("problem") || text.contains("issue") || text.contains("frustrated") {
            return "Negative - User expressed concerns"
        } else {
            return "Neutral - Standard interaction"
        }
    }
    
    private func extractTopics() -> [String] {
        let text = callRecord.transcription.lowercased()
        var topics: [String] = []
        
        let topicKeywords = [
            ("balance", "Account Balance"),
            ("transfer", "Money Transfer"),
            ("bill", "Bill Payment"),
            ("transaction", "Transactions"),
            ("investment", "Investments"),
            ("loan", "Loans"),
            ("credit card", "Credit Cards"),
            ("mortgage", "Mortgage"),
            ("insurance", "Insurance"),
            ("help", "Customer Support")
        ]
        
        for (keyword, topic) in topicKeywords {
            if text.contains(keyword) {
                topics.append(topic)
            }
        }
        
        return Array(Set(topics))
    }
    
    private func extractActionItems() -> [String] {
        let text = callRecord.transcription.lowercased()
        var actions: [String] = []
        
        if text.contains("check") && text.contains("balance") {
            actions.append("Check account balance")
        }
        
        if text.contains("transfer") {
            actions.append("Process money transfer")
        }
        
        if text.contains("pay") && (text.contains("bill") || text.contains("payment")) {
            actions.append("Schedule bill payment")
        }
        
        if text.contains("review") && text.contains("transaction") {
            actions.append("Review recent transactions")
        }
        
        if text.contains("update") || text.contains("change") {
            actions.append("Update account information")
        }
        
        return actions
    }
    
    private func analyzeCommunicationPattern() -> String {
        let wordCount = self.wordCount(callRecord.transcription)
        
        if wordCount < 20 {
            return "Brief interaction - user was direct and concise"
        } else if wordCount < 50 {
            return "Standard conversation length with clear communication"
        } else {
            return "Detailed discussion - user provided comprehensive information"
        }
    }
    
    private func analyzeUserEngagement() -> String {
        if callRecord.wasSuccessful && callRecord.duration > 30 {
            return "High engagement - user actively participated throughout the call"
        } else if callRecord.wasSuccessful {
            return "Good engagement - user achieved their objective efficiently"
        } else {
            return "Limited engagement - may need alternative communication method"
        }
    }
    
    private func generateRecommendation() -> String {
        let topics = extractTopics()
        
        if topics.contains("Account Balance") {
            return "Consider setting up balance alerts for proactive account monitoring"
        } else if topics.contains("Money Transfer") {
            return "Set up recurring transfers for regular payments"
        } else if topics.contains("Investments") {
            return "Schedule a portfolio review for comprehensive investment planning"
        } else {
            return "Continue using voice assistant for quick banking tasks"
        }
    }
    
    private func generateFollowUpSuggestions() -> [String] {
        var suggestions: [String] = []
        let topics = extractTopics()
        
        if topics.contains("Account Balance") {
            suggestions.append("Set up daily balance notifications")
        }
        
        if topics.contains("Money Transfer") {
            suggestions.append("Add frequent recipients to transfer list")
        }
        
        if topics.contains("Bill Payment") {
            suggestions.append("Enable automatic bill payments")
        }
        
        if topics.contains("Investments") {
            suggestions.append("Schedule quarterly portfolio review")
        }
        
        if !callRecord.wasSuccessful {
            suggestions.append("Try alternative communication method for complex issues")
        }
        
        if suggestions.isEmpty {
            suggestions.append("Continue regular voice check-ins for account updates")
        }
        
        return Array(suggestions.prefix(3))
    }
    
    private func saveSummary(_ option: SaveOption) {
        isSaving = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSaving = false
            selectedSaveOption = nil
        }
    }
    
    private func generateShareText() -> String {
        return """
        Voice Call Summary - \(callRecord.formattedDate)
        
        Duration: \(callRecord.formattedDuration)
        Status: \(callRecord.wasSuccessful ? "Successful" : "Incomplete")
        Quality: \(callRecord.callQuality.rawValue)
        
        Main Topic: \(extractMainPurpose())
        Key Outcome: \(extractKeyOutcome())
        
        Topics Discussed: \(extractTopics().joined(separator: ", "))
        
        Action Items:
        \(extractActionItems().enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        AI Insights:
        \(analyzeCommunicationPattern())
        \(analyzeUserEngagement())
        \(generateRecommendation())
        
        Follow-up Suggestions:
        \(generateFollowUpSuggestions().enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        """
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SummaryRow: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TopicChip: View {
    let topic: String
    
    var body: some View {
        Text(topic)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(15)
    }
}

struct ActionItemRow: View {
    let index: Int
    let item: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.green)
                .clipShape(Circle())
            
            Text(item)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let title: String
    let insight: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
            Text(insight)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.leading, 20)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FollowUpRow: View {
    let index: Int
    let suggestion: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.right.circle")
                .font(.caption)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(suggestion)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ExportOptionButton: View {
    let option: SaveOption
    let isSaving: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: option.icon)
                    .font(.caption)
                
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(option.title)
                        .font(.caption)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(option.color)
            .cornerRadius(15)
        }
        .disabled(isSaving)
    }
}

// MARK: - Data Models

enum SaveOption: String, CaseIterable, Identifiable {
    case notes = "Notes"
    case files = "Files"
    case email = "Email"
    case messages = "Messages"
    
    var id: String { return rawValue }
    
    var title: String { return rawValue }
    
    var icon: String {
        switch self {
        case .notes: return "note.text"
        case .files: return "folder"
        case .email: return "envelope"
        case .messages: return "message"
        }
    }
    
    var color: Color {
        switch self {
        case .notes: return .orange
        case .files: return .blue
        case .email: return .green
        case .messages: return .purple
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct CallSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        let mockCallRecord = VoiceCallRecord(
            id: "123",
            startTime: Date(),
            endTime: Date().addingTimeInterval(120),
            duration: 120,
            transcription: "I'd like to check my account balance and transfer some money to my savings account.",
            agentResponse: "I can help you check your account balance and process a transfer to your savings account.",
            callQuality: .excellent,
            wasSuccessful: true
        )
        
        CallSummaryView(
            voiceCallService: VoiceCallService(),
            callRecord: mockCallRecord
        )
    }
}
