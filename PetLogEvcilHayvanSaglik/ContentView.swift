import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @State private var store: PetStore?
    @State private var premiumManager = PremiumManager.shared
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        Group {
            if let store {
                if hasCompletedOnboarding {
                    mainTabView(store)
                } else {
                    OnboardingView(store: store)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if store == nil {
                store = PetStore(modelContext: modelContext)
            }
        }
    }

    private func mainTabView(_ store: PetStore) -> some View {
        TabView(selection: $selectedTab) {
            Tab("Bugün", systemImage: "house.fill", value: .dashboard) {
                DashboardView(store: store, premiumManager: premiumManager)
            }
            Tab("Sağlık", systemImage: "heart.fill", value: .health) {
                HealthView(store: store)
            }
            Tab("Finans", systemImage: "chart.pie.fill", value: .finance) {
                FinanceView(store: store, premiumManager: premiumManager)
            }
            Tab("Öneriler", systemImage: "lightbulb.fill", value: .insights) {
                InsightsView(store: store, premiumManager: premiumManager)
            }
            Tab("Daha Fazla", systemImage: "ellipsis.circle.fill", value: .more) {
                MoreView(store: store, premiumManager: premiumManager)
            }
        }
    }
}

enum AppTab: Hashable {
    case dashboard, health, finance, insights, more
}
