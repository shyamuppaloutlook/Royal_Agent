import SwiftUI

struct CallInitiationView: View {
    @StateObject private var voiceCallService = VoiceCallService()
    @State private var showingActiveCall = false
    @State private var showingContacts = false
    @State private var showingRecentCalls = false
    @State private var searchText = ""
    @State private var selectedQuickAction: QuickCallAction? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search Bar
                searchBarView
                
                // Quick Actions
                quickActionsView
                
                // Recent Calls
                recentCallsView
                
                Spacer()
                
                // Quick Dial Pad
                quickDialPadView
                
                // Bottom Navigation
                bottomNavigationView
            }
            .background(Color(.systemBackground))
            .sheet(isPresented: $showingActiveCall) {
                ActiveCallView(voiceCallService: voiceCallService)
            }
            .sheet(isPresented: $showingContacts) {
                ContactsView()
            }
            .sheet(isPresented: $showingRecentCalls) {
                RecentCallsView(voiceCallService: voiceCallService)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Voice Assistant")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Talk to your AI assistant")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                showingContacts = true
            }) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    // MARK: - Search Bar View
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search assistant or commands...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Quick Actions View
    
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(QuickCallAction.allCases) { action in
                        QuickActionCard(action: action) {
                            handleQuickAction(action)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Recent Calls View
    
    private var recentCallsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Calls")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    showingRecentCalls = true
                }) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if voiceCallService.getCallHistory().isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "phone.arrow.up.right.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No recent calls")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Start your first voice conversation")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(voiceCallService.getCallHistory().prefix(3))) { call in
                        RecentCallRow(call: call) {
                            startNewCall()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Quick Dial Pad View
    
    private var quickDialPadView: some View {
        VStack(spacing: 20) {
            // Main Call Button
            Button(action: {
                startNewCall()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "phone.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: voiceCallService.isCallActive)
            
            Text("Start Voice Call")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Bottom Navigation View
    
    private var bottomNavigationView: some View {
        HStack {
            NavigationButton(
                icon: "clock",
                title: "History",
                isSelected: false
            ) {
                showingRecentCalls = true
            }
            
            Spacer()
            
            NavigationButton(
                icon: "person.2",
                title: "Contacts",
                isSelected: false
            ) {
                showingContacts = true
            }
            
            Spacer()
            
            NavigationButton(
                icon: "gear",
                title: "Settings",
                isSelected: false
            ) {
                // Show settings
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Helper Methods
    
    private func handleQuickAction(_ action: QuickCallAction) {
        selectedQuickAction = action
        startNewCall()
    }
    
    private func startNewCall() {
        voiceCallService.startCall()
        showingActiveCall = true
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let action: QuickCallAction
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: action.icon)
                        .font(.title2)
                        .foregroundColor(action.color)
                }
                
                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Call Row

struct RecentCallRow: View {
    let call: VoiceCallRecord
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(call.wasSuccessful ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: call.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(call.wasSuccessful ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(call.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(call.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(call.callQuality.rawValue)
                        .font(.caption)
                        .foregroundColor(call.callQuality.color)
                }
            }
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "phone.arrow.up.right.circle")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Navigation Button

struct NavigationButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Call Actions

enum QuickCallAction: String, CaseIterable, Identifiable {
    case checkBalance = "Check Balance"
    case transferMoney = "Transfer Money"
    case payBills = "Pay Bills"
    case getHelp = "Get Help"
    case recentTransactions = "Recent Transactions"
    case investmentInfo = "Investment Info"
    
    var id: String { return rawValue }
    
    var icon: String {
        switch self {
        case .checkBalance: return "dollarsign.circle"
        case .transferMoney: return "arrow.left.arrow.right"
        case .payBills: return "doc.text"
        case .getHelp: return "questionmark.circle"
        case .recentTransactions: return "list.bullet"
        case .investmentInfo: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .checkBalance: return .blue
        case .transferMoney: return .green
        case .payBills: return .orange
        case .getHelp: return .purple
        case .recentTransactions: return .teal
        case .investmentInfo: return .red
        }
    }
    
    var initialMessage: String {
        switch self {
        case .checkBalance: return "I'd like to check my account balance"
        case .transferMoney: return "I want to transfer money to someone"
        case .payBills: return "I need to pay my bills"
        case .getHelp: return "I need help with my banking"
        case .recentTransactions: return "Show me my recent transactions"
        case .investmentInfo: return "I want information about my investments"
        }
    }
}

// MARK: - Contacts View

struct ContactsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Contacts feature coming soon")
                    .foregroundColor(.gray)
                    .padding()
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Recent Calls View

struct RecentCallsView: View {
    @ObservedObject var voiceCallService: VoiceCallService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if voiceCallService.getCallHistory().isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "phone.arrow.up.right.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No call history")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Your voice call history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else {
                    ForEach(voiceCallService.getCallHistory()) { call in
                        RecentCallDetailRow(call: call) {
                            // Start new call with context
                        }
                    }
                }
            }
            .navigationTitle("Call History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        voiceCallService.clearCallHistory()
                    }
                    .disabled(voiceCallService.getCallHistory().isEmpty)
                }
            }
        }
    }
}

// MARK: - Recent Call Detail Row

struct RecentCallDetailRow: View {
    let call: VoiceCallRecord
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(call.formattedDate)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Duration: \(call.formattedDuration)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack {
                        Image(systemName: call.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(call.wasSuccessful ? .green : .red)
                        
                        Text(call.wasSuccessful ? "Success" : "Failed")
                            .font(.caption)
                            .foregroundColor(call.wasSuccessful ? .green : .red)
                    }
                    
                    Text(call.callQuality.rawValue)
                        .font(.caption)
                        .foregroundColor(call.callQuality.color)
                }
            }
            
            if !call.transcription.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You said:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    Text(call.transcription)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
            }
            
            if !call.agentResponse.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Agent responded:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    Text(call.agentResponse)
                        .font(.body)
                        .foregroundColor(.blue)
                        .lineLimit(3)
                }
            }
            
            HStack {
                Button(action: action) {
                    HStack {
                        Image(systemName: "phone.arrow.up.right")
                        Text("Call Again")
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                }
                
                Spacer()
                
                Button(action: {
                    // Share call details
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct CallInitiationView_Previews: PreviewProvider {
    static var previews: some View {
        CallInitiationView()
    }
}
