import SwiftUI

// MARK: - SOLID Chat View
// Follows Single Responsibility Principle - only handles UI logic

struct SOLIDChatView: View {
    @StateObject private var chatService: SOLIDChatService
    @State private var messageText = ""
    @State private var showingError = false
    
    // Dependency Inversion Principle - inject service
    init(chatService: SOLIDChatService = ChatServiceFactory.createChatService()) {
        self._chatService = StateObject(wrappedValue: chatService)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Messages
            messagesView
            
            // Input area
            inputView
        }
        .navigationTitle("RBC Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            if let error = chatService.lastError {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("RBC AI Assistant")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Your personal banking assistant")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                chatService.clearChat()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Messages View
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(chatService.messages) { message in
                    MessageBubbleView(message: message)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Input View
    
    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(chatService.isTyping)
                
                Button(action: sendMessage) {
                    if chatService.isTyping {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatService.isTyping)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        chatService.sendMessage(trimmedMessage)
        messageText = ""
        
        if chatService.lastError != nil {
            showingError = true
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userMessageView
            } else {
                assistantMessageView
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private var userMessageView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private var assistantMessageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.content)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(16)
            
            if let intent = message.intent {
                Text("Intent: \(String(describing: intent))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct SOLIDChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SOLIDChatView()
        }
    }
}
