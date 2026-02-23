import SwiftUI
import SwiftData

@main
struct PetOSPetHealthFinanceApp: App {

    init() {
        PremiumManager.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Pet.self,
            WeightLog.self,
            VaccineRecord.self,
            Medication.self,
            VetVisit.self,
            Expense.self,
            FoodInventory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
}
