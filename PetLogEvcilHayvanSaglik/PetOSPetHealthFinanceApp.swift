import SwiftUI
import SwiftData
import WidgetKit

@main
struct PetOSPetHealthFinanceApp: App {

    init() {
        PremiumManager.configure()
    }

    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Pet.self,
            WeightLog.self,
            VaccineRecord.self,
            Medication.self,
            VetVisit.self,
            Expense.self,
            FoodInventory.self,
            PhotoLog.self,
            FeedingLog.self,
            ActivityLog.self,
            PetDocument.self,
            BehaviorLog.self,
        ])

        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        let modelConfiguration: ModelConfiguration
        if iCloudEnabled {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        } else {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var appLock = AppLockService.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .overlay {
                    AppLockOverlay(appLock: appLock)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .background:
                        appLock.lockIfNeeded()
                        updateWidgetData()
                    case .active:
                        scheduleNotificationsIfNeeded()
                    default:
                        break
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func scheduleNotificationsIfNeeded() {
        Task {
            await NotificationService.shared.checkAuthorization()
            guard NotificationService.shared.isAuthorized else { return }

            let context = sharedModelContainer.mainContext
            let descriptor = FetchDescriptor<Pet>(sortBy: [SortDescriptor(\.createdAt)])
            guard let pets = try? context.fetch(descriptor), !pets.isEmpty else { return }

            NotificationService.shared.scheduleAllReminders(for: pets)
        }
    }

    private func updateWidgetData() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Pet>(sortBy: [SortDescriptor(\.createdAt)])
        guard let pets = try? context.fetch(descriptor), let selectedPet = pets.first else { return }

        let now = Date()
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        let monthlySpending = selectedPet.expenses
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }

        WidgetDataService.updateWidgetData(for: selectedPet, monthlySpending: monthlySpending)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
