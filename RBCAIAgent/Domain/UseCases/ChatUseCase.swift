import Foundation
import Combine

// MARK: - Domain Use Cases
// Following SOLID: Single Responsibility and Dependency Inversion Principles

protocol ChatUseCaseProtocol {
    func sendMessage(_ content: String) async -> Result<ChatMessage, ChatError>
    func getMessages() -> [ChatMessage]
    func clearChat() -> Result<Void, ChatError>
    func updateContext(with message: ChatMessage) -> Result<Void, ChatError>
}

class ChatUseCase: ChatUseCaseProtocol {
    private let messageRepository: MessageRepositoryProtocol
    private let intentRecognitionUseCase: IntentRecognitionUseCaseProtocol
    private let responseGenerationUseCase: ResponseGenerationUseCaseProtocol
    private let contextManagementUseCase: ContextManagementUseCaseProtocol
    
    // Dependency Inversion Principle
    init(
        messageRepository: MessageRepositoryProtocol,
        intentRecognitionUseCase: IntentRecognitionUseCaseProtocol,
        responseGenerationUseCase: ResponseGenerationUseCaseProtocol,
        contextManagementUseCase: ContextManagementUseCaseProtocol
    ) {
        self.messageRepository = messageRepository
        self.intentRecognitionUseCase = intentRecognitionUseCase
        self.responseGenerationUseCase = responseGenerationUseCase
        self.contextManagementUseCase = contextManagementUseCase
    }
    
    func sendMessage(_ content: String) async -> Result<ChatMessage, ChatError> {
        do {
            // Create user message
            let intent = await intentRecognitionUseCase.recognizeIntent(from: content)
            let userMessage = ChatMessage(
                content: content,
                isFromUser: true,
                intent: intent
            )
            
            // Save user message
            try await messageRepository.saveMessage(userMessage)
            
            // Update context
            try await contextManagementUseCase.updateContext(with: userMessage)
            
            // Generate response
            let context = await contextManagementUseCase.getCurrentContext()
            let responseResult = await responseGenerationUseCase.generateResponse(
                for: content,
                intent: intent,
                context: context
            )
            
            switch responseResult {
            case .success(let responseContent):
                let aiMessage = ChatMessage(
                    content: responseContent,
                    isFromUser: false,
                    intent: nil,
                    metadata: MessageMetadata(
                        processingTime: nil,
                        confidence: nil,
                        source: .api
                    )
                )
                
                // Save AI message
                try await messageRepository.saveMessage(aiMessage)
                
                return .success(aiMessage)
                
            case .failure(let error):
                return .failure(error)
            }
            
        } catch {
            return .failure(.messageProcessingFailed(error))
        }
    }
    
    func getMessages() -> [ChatMessage] {
        return messageRepository.getMessages()
    }
    
    func clearChat() -> Result<Void, ChatError> {
        do {
            try messageRepository.clearMessages()
            try contextManagementUseCase.clearContext()
            return .success(())
        } catch {
            return .failure(.clearChatFailed(error))
        }
    }
    
    func updateContext(with message: ChatMessage) -> Result<Void, ChatError> {
        do {
            try contextManagementUseCase.updateContext(with: message)
            return .success(())
        } catch {
            return .failure(.contextUpdateFailed(error))
        }
    }
}

// MARK: - Intent Recognition Use Case

protocol IntentRecognitionUseCaseProtocol {
    func recognizeIntent(from message: String) async -> ChatIntent
    func isBankingRelated(_ message: String) -> Bool
}

class BankingIntentRecognitionUseCase: IntentRecognitionUseCaseProtocol {
    private let intentRepository: IntentRepositoryProtocol
    private let nlpService: NLPServiceProtocol
    
    init(intentRepository: IntentRepositoryProtocol, nlpService: NLPServiceProtocol) {
        self.intentRepository = intentRepository
        self.nlpService = nlpService
    }
    
    func recognizeIntent(from message: String) async -> ChatIntent {
        // Use NLP service for advanced recognition
        let nlpResult = await nlpService.analyzeText(message)
        
        // Fall back to pattern matching if NLP is inconclusive
        if let intent = nlpResult.intent, nlpResult.confidence > 0.7 {
            return intent
        }
        
        return await intentRepository.getIntentFromPatterns(message)
    }
    
    func isBankingRelated(_ message: String) -> Bool {
        let keywords = ["balance", "account", "transaction", "transfer", "bill", "payment", "investment", "loan", "mortgage"]
        return keywords.contains { message.lowercased().contains($0) }
    }
}

// MARK: - Response Generation Use Case

protocol ResponseGenerationUseCaseProtocol {
    func generateResponse(for message: String, intent: ChatIntent, context: ChatContext) async -> Result<String, ChatError>
}

class BankingResponseGenerationUseCase: ResponseGenerationUseCaseProtocol {
    private let responseRepository: ResponseRepositoryProtocol
    private let dataRepository: DataRepositoryProtocol
    private let templateService: TemplateServiceProtocol
    
    init(
        responseRepository: ResponseRepositoryProtocol,
        dataRepository: DataRepositoryProtocol,
        templateService: TemplateServiceProtocol
    ) {
        self.responseRepository = responseRepository
        self.dataRepository = dataRepository
        self.templateService = templateService
    }
    
    func generateResponse(for message: String, intent: ChatIntent, context: ChatContext) async -> Result<String, ChatError> {
        do {
            switch intent {
            case .balanceInquiry:
                return await generateBalanceResponse()
                
            case .spendingAnalysis:
                return await generateSpendingResponse()
                
            case .transactionSearch:
                return await generateTransactionResponse(for: message)
                
            case .accountInformation:
                return await generateAccountResponse()
                
            case .insightsRequest:
                return await generateInsightsResponse()
                
            case .budgetHelp:
                return await generateBudgetResponse()
                
            case .billPayment:
                return await generateBillResponse()
                
            case .netWorth:
                return await generateNetWorthResponse()
                
            case .transferMoney:
                return await generateTransferResponse()
                
            case .investmentInfo:
                return await generateInvestmentResponse()
                
            case .helpRequest:
                return await generateHelpResponse()
                
            case .greeting:
                return .success(generateGreetingResponse())
                
            case .farewell:
                return .success(generateFarewellResponse())
                
            case .unknown:
                return await generateGeneralResponse()
            }
        } catch {
            return .failure(.responseGenerationFailed(error))
        }
    }
    
    private func generateBalanceResponse() async -> Result<String, ChatError> {
        do {
            let accounts = try dataRepository.getAccounts()
            let totalBalance = accounts.reduce(0) { $0 + $1.balance }
            
            let template = try responseRepository.getTemplate(for: .balanceInquiry)
            let response = templateService.render(template, with: [
                "total_balance": String(format: "$%.2f", totalBalance),
                "account_count": "\(accounts.count)"
            ])
            
            return .success(response)
        } catch {
            return .failure(.dataRetrievalFailed(error))
        }
    }
    
    private func generateSpendingResponse() async -> Result<String, ChatError> {
        do {
            let spending = try dataRepository.getSpendingByCategory()
            let topCategory = spending.max { $0.amount < $1.amount }
            
            let template = try responseRepository.getTemplate(for: .spendingAnalysis)
            let response = templateService.render(template, with: [
                "top_category": topCategory?.category.displayName ?? "N/A",
                "top_amount": String(format: "$%.2f", topCategory?.amount ?? 0),
                "total_categories": "\(spending.count)"
            ])
            
            return .success(response)
        } catch {
            return .failure(.dataRetrievalFailed(error))
        }
    }
    
    private func generateTransactionResponse(for message: String) async -> Result<String, ChatError> {
        do {
            let transactions = try dataRepository.getRecentTransactions(limit: 5)
            
            if transactions.isEmpty {
                return .success("I don't see any recent transactions in your account.")
            }
            
            let template = try responseRepository.getTemplate(for: .transactionSearch)
            let transactionList = transactions.prefix(3).map { transaction in
                "• \(transaction.description): \(String(format: "$%.2f", transaction.amount))"
            }.joined(separator: "\n")
            
            let response = templateService.render(template, with: [
                "transaction_list": transactionList,
                "transaction_count": "\(transactions.count)"
            ])
            
            return .success(response)
        } catch {
            return .failure(.dataRetrievalFailed(error))
        }
    }
    
    private func generateAccountResponse() async -> Result<String, ChatError> {
        do {
            let accounts = try dataRepository.getAccounts()
            let template = try responseRepository.getTemplate(for: .accountInformation)
            
            let accountList = accounts.map { account in
                "\(account.name): \(String(format: "$%.2f", account.balance))"
            }.joined(separator: "\n")
            
            let response = templateService.render(template, with: [
                "account_list": accountList,
                "total_accounts": "\(accounts.count)"
            ])
            
            return .success(response)
        } catch {
            return .failure(.dataRetrievalFailed(error))
        }
    }
    
    private func generateInsightsResponse() async -> Result<String, ChatError> {
        let template = try? responseRepository.getTemplate(for: .insightsRequest)
        let response = templateService.render(template ?? "I can provide insights on spending patterns, savings opportunities, and investment recommendations.", with: [:])
        return .success(response)
    }
    
    private func generateBudgetResponse() async -> Result<String, ChatError> {
        let template = try? responseRepository.getTemplate(for: .budgetHelp)
        let response = templateService.render(template ?? "I can help you with budget management by analyzing your spending and setting realistic goals.", with: [:])
        return .success(response)
    }
    
    private func generateBillResponse() async -> Result<String, ChatError> {
        let template = try? responseRepository.getTemplate(for: .billPayment)
        let response = templateService.render(template ?? "I can help you manage bill payments, set up reminders, and track due dates.", with: [:])
        return .success(response)
    }
    
    private func generateNetWorthResponse() async -> Result<String, ChatError> {
        do {
            let accounts = try dataRepository.getAccounts()
            let assets = accounts.filter { $0.type == .checking || $0.type == .savings || $0.type == .investment }
            let debts = accounts.filter { $0.type == .credit || $0.type == .loan || $0.type == .mortgage }
            
            let totalAssets = assets.reduce(0) { $0 + $1.balance }
            let totalDebts = debts.reduce(0) { $0 + abs($1.balance) }
            let netWorth = totalAssets - totalDebts
            
            let template = try responseRepository.getTemplate(for: .netWorth)
            let response = templateService.render(template, with: [
                "net_worth": String(format: "$%.2f", netWorth),
                "total_assets": String(format: "$%.2f", totalAssets),
                "total_debts": String(format: "$%.2f", totalDebts)
            ])
            
            return .success(response)
        } catch {
            return .failure(.dataRetrievalFailed(error))
        }
    }
    
    private func generateTransferResponse() async -> Result<String, ChatError> {
        let template = try? responseRepository.getTemplate(for: .transferMoney)
        let response = templateService.render(template ?? "I can help you transfer money between accounts. Please specify the amount and destination.", with: [:])
        return .success(response)
    }
    
    private func generateInvestmentResponse() async -> Result<String, ChatError> {
        let template = try? responseRepository.getTemplate(for: .investmentInfo)
        let response = templateService.render(template ?? "I can provide information about your investment portfolio and market insights.", with: [:])
        return .success(response)
    }
    
    private func generateHelpResponse() async -> Result<String, ChatError> {
        let template = try? responseRepository.getTemplate(for: .helpRequest)
        let response = templateService.render(template ?? "I'm your RBC AI assistant. I can help with balances, transactions, transfers, investments, and more.", with: [:])
        return .success(response)
    }
    
    private func generateGreetingResponse() -> String {
        let greetings = [
            "Hello! How can I assist you today?",
            "Hi there! What can I help you with?",
            "Good day! How may I help you with your banking needs?"
        ]
        return greetings.randomElement() ?? "Hello! How can I assist you today?"
    }
    
    private func generateFarewellResponse() -> String {
        let farewells = [
            "Goodbye! Have a great day!",
            "Thank you for chatting. Have a wonderful day!",
            "Goodbye! Feel free to come back anytime you need assistance."
        ]
        return farewells.randomElement() ?? "Goodbye! Have a great day!"
    }
    
    private func generateGeneralResponse() async -> Result<String, ChatError> {
        let template = try? responseRepository.getTemplate(for: .unknown)
        let response = templateService.render(template ?? "I'm here to help with your banking needs. Could you please rephrase your question?", with: [:])
        return .success(response)
    }
}

// MARK: - Context Management Use Case

protocol ContextManagementUseCaseProtocol {
    func updateContext(with message: ChatMessage) throws
    func getCurrentContext() async -> ChatContext
    func clearContext() throws
    func getSessionHistory() -> [ChatMessage]
}

class ChatContextManagementUseCase: ContextManagementUseCaseProtocol {
    private let contextRepository: ContextRepositoryProtocol
    private let messageRepository: MessageRepositoryProtocol
    
    init(contextRepository: ContextRepositoryProtocol, messageRepository: MessageRepositoryProtocol) {
        self.contextRepository = contextRepository
        self.messageRepository = messageRepository
    }
    
    func updateContext(with message: ChatMessage) throws {
        var context = try contextRepository.getCurrentContext()
        
        context.lastIntent = message.intent
        context.messageCount += 1
        context.lastMessageTime = message.timestamp
        context.conversationHistory.append(message.content)
        
        // Keep only recent history
        if context.conversationHistory.count > 20 {
            context.conversationHistory.removeFirst(context.conversationHistory.count - 20)
        }
        
        try contextRepository.saveContext(context)
    }
    
    func getCurrentContext() async -> ChatContext {
        do {
            return try contextRepository.getCurrentContext()
        } catch {
            // Return default context if none exists
            return ChatContext()
        }
    }
    
    func clearContext() throws {
        try contextRepository.clearContext()
    }
    
    func getSessionHistory() -> [ChatMessage] {
        return messageRepository.getMessages()
    }
}

// MARK: - Domain Errors

enum ChatError: LocalizedError {
    case messageProcessingFailed(Error)
    case responseGenerationFailed(Error)
    case dataRetrievalFailed(Error)
    case contextUpdateFailed(Error)
    case clearChatFailed(Error)
    case invalidInput
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .messageProcessingFailed(let error):
            return "Failed to process message: \(error.localizedDescription)"
        case .responseGenerationFailed(let error):
            return "Failed to generate response: \(error.localizedDescription)"
        case .dataRetrievalFailed(let error):
            return "Failed to retrieve data: \(error.localizedDescription)"
        case .contextUpdateFailed(let error):
            return "Failed to update context: \(error.localizedDescription)"
        case .clearChatFailed(let error):
            return "Failed to clear chat: \(error.localizedDescription)"
        case .invalidInput:
            return "Invalid input provided"
        case .serviceUnavailable:
            return "Service is currently unavailable"
        }
    }
}
