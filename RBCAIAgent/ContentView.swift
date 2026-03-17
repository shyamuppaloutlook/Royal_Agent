import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SimpleChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
            
            SimpleDashboardView()
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
