import Foundation

/// Shared data service for passing data between app and widget via App Group UserDefaults
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

    // MARK: - Read (from widget)

    struct WidgetData {
        let petName: String
        let petSpeciesIcon: String
        let nextVaccineName: String?
        let nextVaccineDate: Date?
        let foodBrand: String?
        let foodDaysRemaining: Int
        let monthlySpending: Double
        let activeMedsCount: Int
        let latestWeight: Double?

        static let placeholder = WidgetData(
            petName: "Buddy",
            petSpeciesIcon: "dog.fill",
            nextVaccineName: "Karma Asi",
            nextVaccineDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
            foodBrand: "Royal Canin",
            foodDaysRemaining: 12,
            monthlySpending: 2450,
            activeMedsCount: 1,
            latestWeight: 8.5
        )
    }

    static func readWidgetData() -> WidgetData {
        guard let defaults = sharedDefaults else { return .placeholder }

        let petName = defaults.string(forKey: petNameKey) ?? "—"
        let speciesIcon = defaults.string(forKey: petSpeciesIconKey) ?? "pawprint.fill"
        let vaccineName = defaults.string(forKey: nextVaccineNameKey)
        let vaccineTimestamp = defaults.double(forKey: nextVaccineDateKey)
        let vaccineDate: Date? = vaccineTimestamp > 0 ? Date(timeIntervalSince1970: vaccineTimestamp) : nil
        let foodBrand = defaults.string(forKey: foodBrandKey)
        let foodDays = defaults.integer(forKey: foodDaysRemainingKey)
        let spending = defaults.double(forKey: monthlySpendingKey)
        let medsCount = defaults.integer(forKey: activeMedsCountKey)
        let weight = defaults.double(forKey: latestWeightKey)

        return WidgetData(
            petName: petName,
            petSpeciesIcon: speciesIcon,
            nextVaccineName: vaccineName,
            nextVaccineDate: vaccineDate,
            foodBrand: foodBrand,
            foodDaysRemaining: foodDays,
            monthlySpending: spending,
            activeMedsCount: medsCount,
            latestWeight: weight > 0 ? weight : nil
        )
    }
}
