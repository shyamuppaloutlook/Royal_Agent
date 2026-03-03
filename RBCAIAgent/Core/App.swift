import SwiftUI

// MARK: - SOLID App Entry Point
// Following SOLID: Clean Architecture with Dependency Injection

@main
struct RBCAIAgentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
            
            CallInitiationView()
                .tabItem {
                    Image(systemName: "phone")
                    Text("Voice")
                }
            
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Dashboard")
                }
        }
    }
}

// MARK: - Dependency Injection Container

class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - Repositories
    
    lazy var messageRepository: MessageRepositoryProtocol = {
        InMemoryMessageRepository()
    }()
    
    lazy var intentRepository: IntentRepositoryProtocol = {
        PatternBasedIntentRepository()
    }()
    
    lazy var responseRepository: ResponseRepositoryProtocol = {
        TemplateResponseRepository()
    }()
    
    lazy var contextRepository: ContextRepositoryProtocol = {
        InMemoryContextRepository()
    }()
    
    lazy var dataRepository: DataRepositoryProtocol = {
        MockDataRepository()
    }()
    
    // MARK: - Services
    
    lazy var nlpService: NLPServiceProtocol = {
        AppleNLPService()
    }()
    
    lazy var templateService: TemplateServiceProtocol = {
        MustacheTemplateService()
    }()
    
    lazy var cacheService: CacheServiceProtocol = {
        MemoryCacheService()
    }()
    
    // MARK: - Use Cases
    
    lazy var intentRecognitionUseCase: IntentRecognitionUseCaseProtocol = {
        BankingIntentRecognitionUseCase(
            intentRepository: intentRepository,
            nlpService: nlpService
        )
    }()
    
    lazy var responseGenerationUseCase: ResponseGenerationUseCaseProtocol = {
        BankingResponseGenerationUseCase(
            responseRepository: responseRepository,
            dataRepository: dataRepository,
            templateService: templateService
        )
    }()
    
    lazy var contextManagementUseCase: ContextManagementUseCaseProtocol = {
        ChatContextManagementUseCase(
            contextRepository: contextRepository,
            messageRepository: messageRepository
        )
    }()
    
    lazy var chatUseCase: ChatUseCaseProtocol = {
        ChatUseCase(
            messageRepository: messageRepository,
            intentRecognitionUseCase: intentRecognitionUseCase,
            responseGenerationUseCase: responseGenerationUseCase,
            contextManagementUseCase: contextManagementUseCase
        )
    }()
    
    // MARK: - View Models
    
    lazy var chatViewModel: ChatViewModel = {
        ChatViewModel(chatUseCase: chatUseCase)
    }()
    
    lazy var dashboardViewModel: DashboardViewModel = {
        let dataRepository = MockDataRepository()
        let dashboardUseCase = MockDashboardUseCase(dataRepository: dataRepository)
        return DashboardViewModel(dashboardUseCase: dashboardUseCase)
    }()
}
