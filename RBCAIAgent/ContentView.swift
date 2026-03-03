import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = RBCDataManager()
    @StateObject private var aiAgent = RBCAIAgent(dataManager: RBCDataManager())
    
    var body: some View {
        TabView {
            ChatView()
                .environmentObject(aiAgent)
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
            
            DashboardView()
                .environmentObject(dataManager)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Dashboard")
                }
        }
    }
}

#Preview {
    ContentView()
}
