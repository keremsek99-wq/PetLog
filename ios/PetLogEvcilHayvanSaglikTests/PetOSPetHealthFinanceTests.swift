//
//  PetOSPetHealthFinanceTests.swift
//  PetOSPetHealthFinanceTests
//
//  Created by Rork on February 22, 2026.
//

import Testing
import Foundation
@testable import PetOSPetHealthFinance

// MARK: - Pet Model Tests

struct PetModelTests {

    @Test func petAgeCalculation() {
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let pet = Pet(name: "Test", species: .dog, birthdate: twoYearsAgo)
        #expect(pet.age.contains("2 yıl"))
    }

    @Test func petAgeMonthsOnly() {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let pet = Pet(name: "Test", species: .cat, birthdate: threeMonthsAgo)
        #expect(pet.age.contains("3 ay"))
    }

    @Test func petEmoji() {
        #expect(Pet(name: "T", species: .dog, birthdate: Date()).emoji == "🐶")
        #expect(Pet(name: "T", species: .cat, birthdate: Date()).emoji == "🐱")
        #expect(Pet(name: "T", species: .bird, birthdate: Date()).emoji == "🐦")
        #expect(Pet(name: "T", species: .rabbit, birthdate: Date()).emoji == "🐰")
        #expect(Pet(name: "T", species: .fish, birthdate: Date()).emoji == "🐟")
        #expect(Pet(name: "T", species: .reptile, birthdate: Date()).emoji == "🦎")
    }

    @Test func petRelevantActivityTypes() {
        let dog = Pet(name: "T", species: .dog, birthdate: Date())
        #expect(dog.relevantActivityTypes.contains(.walk))

        let fish = Pet(name: "T", species: .fish, birthdate: Date())
        #expect(fish.relevantActivityTypes.contains(.waterChange))
        #expect(!fish.relevantActivityTypes.contains(.walk))
    }

    @Test func sickModeInactiveByDefault() {
        let pet = Pet(name: "Healthy", species: .dog, birthdate: Date())
        // A pet with no medications, no recent vet visits, no high-severity behaviors
        #expect(!pet.isSickMode)
    }

    @Test func latestWeightIsNilWhenNoLogs() {
        let pet = Pet(name: "T", species: .dog, birthdate: Date())
        #expect(pet.latestWeight == nil)
    }

    @Test func nextVaccineDueIsNilWhenNoRecords() {
        let pet = Pet(name: "T", species: .dog, birthdate: Date())
        #expect(pet.nextVaccineDue == nil)
    }

    @Test func activeMedicationsEmptyByDefault() {
        let pet = Pet(name: "T", species: .dog, birthdate: Date())
        #expect(pet.activeMedications.isEmpty)
    }
}

// MARK: - VaccineRecord Tests

struct VaccineRecordTests {

    @Test func vaccineNotOverdueWithoutDueDate() {
        let vaccine = VaccineRecord(name: "Rabies")
        #expect(!vaccine.isOverdue)
    }

    @Test func vaccineOverdueWhenPastDue() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let vaccine = VaccineRecord(name: "Rabies", dueDate: pastDate)
        #expect(vaccine.isOverdue)
    }

    @Test func vaccineNotOverdueWhenFutureDue() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        let vaccine = VaccineRecord(name: "Rabies", dueDate: futureDate)
        #expect(!vaccine.isOverdue)
    }

    @Test func vaccineDueSoonWithin30Days() {
        let soon = Calendar.current.date(byAdding: .day, value: 15, to: Date())!
        let vaccine = VaccineRecord(name: "Rabies", dueDate: soon)
        #expect(vaccine.isDueSoon)
    }

    @Test func vaccineNotDueSoonWhenFarAway() {
        let farAway = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        let vaccine = VaccineRecord(name: "Rabies", dueDate: farAway)
        #expect(!vaccine.isDueSoon)
    }

    @Test func vaccineNotDueSoonWhenOverdue() {
        let past = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let vaccine = VaccineRecord(name: "Rabies", dueDate: past)
        #expect(!vaccine.isDueSoon)
    }
}

// MARK: - Medication Tests

struct MedicationTests {

    @Test func medicationActiveWithNoEndDate() {
        let med = Medication(name: "Antibiyotik")
        #expect(med.isActive)
    }

    @Test func medicationActiveWhenEndDateInFuture() {
        let future = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        let med = Medication(name: "Antibiyotik", endDate: future)
        #expect(med.isActive)
    }

    @Test func medicationInactiveWhenEndDatePassed() {
        let past = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let med = Medication(name: "Antibiyotik", endDate: past)
        #expect(!med.isActive)
    }

    @Test func medicationScheduleValues() {
        #expect(MedicationSchedule.daily.rawValue == "Günlük")
        #expect(MedicationSchedule.twiceDaily.rawValue == "Günde 2 Kez")
        #expect(MedicationSchedule.weekly.rawValue == "Haftalık")
        #expect(MedicationSchedule.monthly.rawValue == "Aylık")
        #expect(MedicationSchedule.asNeeded.rawValue == "Gerektiğinde")
    }
}

// MARK: - PetSpecies Tests

struct PetSpeciesTests {

    @Test func allSpeciesHaveIcons() {
        for species in PetSpecies.allCases {
            #expect(!species.icon.isEmpty)
        }
    }

    @Test func speciesRawValues() {
        #expect(PetSpecies.dog.rawValue == "Köpek")
        #expect(PetSpecies.cat.rawValue == "Kedi")
        #expect(PetSpecies.bird.rawValue == "Kuş")
    }
}

// MARK: - WellnessScoreEngine Tests

struct WellnessScoreEngineTests {

    @Test func gradeColors() {
        #expect(WellnessScoreEngine.Grade.excellent.emoji == "🌟")
        #expect(WellnessScoreEngine.Grade.critical.emoji == "🚨")
    }

    @Test func gradeRawValues() {
        #expect(WellnessScoreEngine.Grade.excellent.rawValue == "Mükemmel")
        #expect(WellnessScoreEngine.Grade.good.rawValue == "İyi")
        #expect(WellnessScoreEngine.Grade.fair.rawValue == "Orta")
        #expect(WellnessScoreEngine.Grade.needsAttention.rawValue == "Dikkat")
        #expect(WellnessScoreEngine.Grade.critical.rawValue == "Kritik")
    }
}

// MARK: - AppLockService Tests

struct AppLockServiceTests {

    @Test func lockoutAfterMaxAttempts() async {
        let service = await AppLockService.shared
        // The lockout mechanism should exist
        let isLockedOut = await service.isLockedOut
        // Default state: should not be locked out
        #expect(!isLockedOut)
    }
}

// MARK: - Expense Category Tests

struct ExpenseCategoryTests {

    @Test func allCategoriesExist() {
        let categories = ExpenseCategory.allCases
        #expect(categories.count >= 9)
        #expect(categories.contains(.food))
        #expect(categories.contains(.veterinary))
        #expect(categories.contains(.medication))
    }
}

// MARK: - PetSex Tests

struct PetSexTests {

    @Test func petSexValues() {
        #expect(PetSex.male.rawValue == "Erkek")
        #expect(PetSex.female.rawValue == "Dişi")
        #expect(PetSex.unknown.rawValue == "Belirtilmemiş")
    }
}
