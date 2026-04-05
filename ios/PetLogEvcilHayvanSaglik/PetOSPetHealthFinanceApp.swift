import SwiftUI
import SwiftData
import WidgetKit
import os.log

private let logger = Logger(subsystem: "com.petlog.app", category: "App")

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

        // Try with user's preferred configuration first
        if let container = Self.createContainer(schema: schema, iCloudEnabled: iCloudEnabled) {
            return container
        }

        // Fallback: try without iCloud if iCloud was enabled
        if iCloudEnabled {
            logger.warning("iCloud ModelContainer failed, falling back to local-only storage")
            if let container = Self.createContainer(schema: schema, iCloudEnabled: false) {
                return container
            }
        }

        // Last resort: in-memory container so the app doesn't crash
        logger.error("All ModelContainer attempts failed, using in-memory storage")
        let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [fallbackConfig])
        } catch {
            fatalError("Could not create even in-memory ModelContainer: \(error)")
        }
    }()

    private static func createContainer(schema: Schema, iCloudEnabled: Bool) -> ModelContainer? {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: iCloudEnabled ? .automatic : .none
        )
        return try? ModelContainer(for: schema, configurations: [config])
    }

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
        guard let pets = try? context.fetch(descriptor), !pets.isEmpty else { return }

        // Use persisted selected pet, fall back to first
        let selectedPet: Pet
        if let savedID = UserDefaults.standard.string(forKey: "selectedPetID"),
           let uuid = UUID(uuidString: savedID),
           let saved = pets.first(where: { $0.id == uuid }) {
            selectedPet = saved
        } else if let first = pets.first {
            selectedPet = first
        } else {
            return
        }

        let now = Date()
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        let monthlySpending = selectedPet.expenses
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }

        WidgetDataService.updateWidgetData(for: selectedPet, monthlySpending: monthlySpending)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
