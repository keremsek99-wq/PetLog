import Foundation

// MARK: - Pet Status Model

struct PetStatus {
    let emoji: String
    let headline: String
    let detail: String?
    let level: StatusLevel
    
    enum StatusLevel: Int, Comparable {
        case great = 0
        case attention = 1
        case warning = 2
        case critical = 3
        
        static func < (lhs: StatusLevel, rhs: StatusLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - Status Engine

struct StatusEngine {
    
    /// Generate a single-sentence status summary for the pet's current state.
    /// Priority order: Birthday → Critical health → Overdue vaccine → Behavior trends → Food running out → All good
    static func dailyStatus(for pet: Pet) -> PetStatus {
        let calendar = Calendar.current
        let now = Date()
        
        // Priority 1: Birthday today or this week
        if let birthdayStatus = checkBirthday(pet: pet, calendar: calendar, now: now) {
            return birthdayStatus
        }
        
        // Priority 2: Critical health — active meds + high severity behaviors
        if let criticalStatus = checkCriticalHealth(pet: pet, calendar: calendar, now: now) {
            return criticalStatus
        }
        
        // Priority 3: Overdue vaccine
        if let vaccineStatus = checkOverdueVaccine(pet: pet) {
            return vaccineStatus
        }
        
        // Priority 4: Behavior/activity trend decline
        if let trendStatus = checkBehaviorTrends(pet: pet, calendar: calendar, now: now) {
            return trendStatus
        }
        
        // Priority 5: Food running out soon
        if let foodStatus = checkFoodRunout(pet: pet) {
            return foodStatus
        }
        
        // Priority 6: Medication ending soon
        if let medStatus = checkMedicationEnding(pet: pet, calendar: calendar, now: now) {
            return medStatus
        }
        
        // Priority 7: All good
        return PetStatus(
            emoji: "✅",
            headline: "\(pet.name) bugün harika görünüyor",
            detail: nil,
            level: .great
        )
    }
    
    // MARK: - Priority Checks
    
    private static func checkBirthday(pet: Pet, calendar: Calendar, now: Date) -> PetStatus? {
        let birthdayComponents = calendar.dateComponents([.month, .day], from: pet.birthdate)
        let todayComponents = calendar.dateComponents([.month, .day], from: now)
        
        if birthdayComponents.month == todayComponents.month && birthdayComponents.day == todayComponents.day {
            let years = calendar.dateComponents([.year], from: pet.birthdate, to: now).year ?? 0
            return PetStatus(
                emoji: "🎂",
                headline: "Mutlu Doğum Günü \(pet.name)!",
                detail: "Bugün \(years) yaşına giriyor!",
                level: .great
            )
        }
        
        // Check if birthday is within next 3 days
        for dayOffset in 1...3 {
            guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let futureComponents = calendar.dateComponents([.month, .day], from: futureDate)
            if birthdayComponents.month == futureComponents.month && birthdayComponents.day == futureComponents.day {
                return PetStatus(
                    emoji: "🎂",
                    headline: "\(pet.name)'ın doğum günü \(dayOffset) gün sonra!",
                    detail: nil,
                    level: .great
                )
            }
        }
        
        return nil
    }
    
    private static func checkCriticalHealth(pet: Pet, calendar: Calendar, now: Date) -> PetStatus? {
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let recentHighSeverity = pet.behaviorLogs.filter { $0.date >= sevenDaysAgo && $0.severity >= 4 }
        
        guard pet.isSickMode else { return nil }
        
        if !recentHighSeverity.isEmpty {
            // Group by behavior type and count
            let symptomCounts = Dictionary(grouping: recentHighSeverity, by: { $0.behaviorType })
            let topSymptom = symptomCounts.max(by: { $0.value.count < $1.value.count })
            
            let symptomText = topSymptom.map { "\($0.value.count) kez \($0.key.rawValue.lowercased())" } ?? ""
            let totalCount = recentHighSeverity.count
            
            return PetStatus(
                emoji: "🚨",
                headline: "\(pet.name) takip altında",
                detail: "Son 7 günde \(totalCount) yüksek şiddetli kayıt\(symptomText.isEmpty ? "" : " — \(symptomText)")",
                level: .critical
            )
        }
        
        // Sick mode but no high severity behaviors — just active meds or recent vet
        let activeMedNames = pet.activeMedications.prefix(2).map { $0.name }.joined(separator: ", ")
        return PetStatus(
            emoji: "⚠️",
            headline: "\(pet.name) tedavi sürecinde",
            detail: activeMedNames.isEmpty ? nil : "Aktif ilaç: \(activeMedNames)",
            level: .warning
        )
    }
    
    private static func checkOverdueVaccine(pet: Pet) -> PetStatus? {
        let overdueVaccines = pet.vaccineRecords.filter { $0.isOverdue }
        guard let firstOverdue = overdueVaccines.sorted(by: { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }).first,
              let dueDate = firstOverdue.dueDate else { return nil }
        
        let daysOverdue = Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
        
        return PetStatus(
            emoji: "💉",
            headline: "\(firstOverdue.name) aşısı \(daysOverdue) gün gecikti",
            detail: overdueVaccines.count > 1 ? "Toplam \(overdueVaccines.count) gecikmiş aşı var" : nil,
            level: .warning
        )
    }
    
    private static func checkBehaviorTrends(pet: Pet, calendar: Calendar, now: Date) -> PetStatus? {
        // Check feeding decline
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        
        let thisWeekFeedings = pet.feedingLogs.filter { $0.date >= sevenDaysAgo }.count
        let lastWeekFeedings = pet.feedingLogs.filter { $0.date >= fourteenDaysAgo && $0.date < sevenDaysAgo }.count
        
        if lastWeekFeedings > 0 {
            let feedingChangePercent = Double(thisWeekFeedings - lastWeekFeedings) / Double(lastWeekFeedings) * 100
            if feedingChangePercent <= -30 {
                return PetStatus(
                    emoji: "⚠️",
                    headline: "\(pet.name) bu hafta normalden az yedi",
                    detail: "Beslenme kaydı geçen haftaya göre %\(Int(abs(feedingChangePercent))) düştü",
                    level: .attention
                )
            }
        }
        
        // Check activity decline for dogs
        if pet.species == .dog {
            let thisWeekWalks = pet.activityLogs.filter { $0.date >= sevenDaysAgo && $0.activityType == .walk }
            let lastWeekWalks = pet.activityLogs.filter { $0.date >= fourteenDaysAgo && $0.date < sevenDaysAgo && $0.activityType == .walk }
            
            let thisWeekMinutes = thisWeekWalks.reduce(0) { $0 + $1.durationMinutes }
            let lastWeekMinutes = lastWeekWalks.reduce(0) { $0 + $1.durationMinutes }
            
            if lastWeekMinutes > 0 {
                let activityChangePercent = Double(thisWeekMinutes - lastWeekMinutes) / Double(lastWeekMinutes) * 100
                if activityChangePercent <= -40 {
                    return PetStatus(
                        emoji: "⚠️",
                        headline: "\(pet.name)'ın aktivitesi bu hafta düştü",
                        detail: "Yürüyüş süresi geçen haftaya göre %\(Int(abs(activityChangePercent))) azaldı",
                        level: .attention
                    )
                }
            }
        }
        
        return nil
    }
    
    private static func checkFoodRunout(pet: Pet) -> PetStatus? {
        guard let food = pet.currentFood else { return nil }
        let daysLeft = food.daysUntilRunout
        
        if daysLeft <= 3 && daysLeft > 0 {
            return PetStatus(
                emoji: "⚠️",
                headline: "\(food.brand) \(daysLeft) gün sonra bitiyor",
                detail: "Yeni mama siparişi vermenin tam zamanı",
                level: .attention
            )
        } else if daysLeft == 0 {
            return PetStatus(
                emoji: "🚨",
                headline: "\(pet.name)'ın maması bitmek üzere!",
                detail: "\(food.brand) bugün bitiyor",
                level: .warning
            )
        }
        
        return nil
    }
    
    private static func checkMedicationEnding(pet: Pet, calendar: Calendar, now: Date) -> PetStatus? {
        let endingSoon = pet.activeMedications.compactMap { med -> (Medication, Int)? in
            guard let endDate = med.endDate else { return nil }
            let days = calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
            return (days >= 0 && days <= 3) ? (med, days) : nil
        }.sorted { $0.1 < $1.1 }
        
        guard let (med, days) = endingSoon.first else { return nil }
        
        return PetStatus(
            emoji: "💊",
            headline: "\(med.name) ilacı \(days == 0 ? "bugün" : "\(days) gün sonra") bitiyor",
            detail: "Veterinerinize danışarak devam kararı verin",
            level: .attention
        )
    }
}
