import Foundation

/// Shared data service for passing data between app and widget via App Group UserDefaults.
/// This copy lives in the main app target and mirrors PetLogWidget/WidgetDataService.swift
enum WidgetDataService {
    static let appGroupID = "group.com.petlog.shared"

    // MARK: - Keys
    private static let petNameKey = "widget_pet_name"
    private static let petSpeciesIconKey = "widget_pet_species_icon"
    private static let nextVaccineNameKey = "widget_next_vaccine_name"
    private static let nextVaccineDateKey = "widget_next_vaccine_date"
    private static let foodBrandKey = "widget_food_brand"
    private static let foodDaysRemainingKey = "widget_food_days_remaining"
    private static let monthlySpendingKey = "widget_monthly_spending"
    private static let activeMedsCountKey = "widget_active_meds_count"
    private static let latestWeightKey = "widget_latest_weight"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Write (from main app)

    static func updateWidgetData(petName: String, speciesIcon: String, nextVaccineName: String?, nextVaccineDate: Date?, foodBrand: String?, foodDaysRemaining: Int, monthlySpending: Double, activeMedsCount: Int, latestWeight: Double?) {
        guard let defaults = sharedDefaults else { return }

        defaults.set(petName, forKey: petNameKey)
        defaults.set(speciesIcon, forKey: petSpeciesIconKey)

        if let name = nextVaccineName {
            defaults.set(name, forKey: nextVaccineNameKey)
        } else {
            defaults.removeObject(forKey: nextVaccineNameKey)
        }

        if let date = nextVaccineDate {
            defaults.set(date.timeIntervalSince1970, forKey: nextVaccineDateKey)
        } else {
            defaults.removeObject(forKey: nextVaccineDateKey)
        }

        if let brand = foodBrand {
            defaults.set(brand, forKey: foodBrandKey)
        } else {
            defaults.removeObject(forKey: foodBrandKey)
        }

        defaults.set(foodDaysRemaining, forKey: foodDaysRemainingKey)
        defaults.set(monthlySpending, forKey: monthlySpendingKey)
        defaults.set(activeMedsCount, forKey: activeMedsCountKey)
        defaults.set(latestWeight ?? -1, forKey: latestWeightKey)
    }

    // MARK: - Convenience (main app only — uses Pet model)

    static func updateWidgetData(for pet: Pet, monthlySpending: Double) {
        let nextVaccine = pet.vaccineRecords.filter { $0.dueDate != nil && $0.dueDate! > Date() }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first

        let currentFood = pet.foodInventories.first
        let foodDays = currentFood != nil ? max(0, Calendar.current.dateComponents([.day], from: Date(), to: currentFood!.predictedRunoutDate).day ?? 0) : -1

        updateWidgetData(
            petName: pet.name,
            speciesIcon: pet.species.icon,
            nextVaccineName: nextVaccine?.name,
            nextVaccineDate: nextVaccine?.dueDate,
            foodBrand: currentFood?.brand,
            foodDaysRemaining: foodDays,
            monthlySpending: monthlySpending,
            activeMedsCount: pet.medications.filter { $0.isActive }.count,
            latestWeight: pet.weightLogs.sorted(by: { $0.date > $1.date }).first?.weightKg
        )
    }
}
