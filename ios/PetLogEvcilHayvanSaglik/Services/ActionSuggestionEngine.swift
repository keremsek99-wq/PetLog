import Foundation

// MARK: - Action Suggestion Model

struct ActionSuggestion: Identifiable {
    let id = UUID()
    let emoji: String
    let message: String
    let actionLabel: String
    let actionType: SuggestedAction
    let priority: Int // lower = higher priority
    
    enum SuggestedAction {
        case addVaccine
        case addActivity(ActivityType)
        case addFeeding
        case orderFood
        case addWeight
        case addPhoto
        case addVetVisit
        case addBehavior
        case none
    }
}

// MARK: - Action Suggestion Engine

struct ActionSuggestionEngine {
    
    /// Returns the single most important action the user should take today.
    static func dailySuggestion(for pet: Pet) -> ActionSuggestion {
        let suggestions = allSuggestions(for: pet)
        return suggestions.min(by: { $0.priority < $1.priority }) ?? defaultSuggestion(for: pet)
    }
    
    /// Returns all applicable suggestions sorted by priority.
    static func allSuggestions(for pet: Pet) -> [ActionSuggestion] {
        var suggestions: [ActionSuggestion] = []
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Overdue vaccine (highest priority)
        let overdueVaccines = pet.vaccineRecords.filter { $0.isOverdue }
        if let vaccine = overdueVaccines.first {
            let daysOverdue = calendar.dateComponents([.day], from: vaccine.dueDate ?? now, to: now).day ?? 0
            suggestions.append(ActionSuggestion(
                emoji: "💉",
                message: "\(vaccine.name) aşısı \(daysOverdue) gün gecikti",
                actionLabel: "Aşı Kaydı Güncelle",
                actionType: .addVaccine,
                priority: 1
            ))
        }
        
        // 2. No walk in 3+ days (dogs only)
        if pet.species == .dog {
            let walkLogs = pet.activityLogs
                .filter { $0.activityType == .walk }
                .sorted { $0.date > $1.date }
            
            let daysSinceLastWalk: Int
            if let lastWalk = walkLogs.first {
                daysSinceLastWalk = calendar.dateComponents([.day], from: lastWalk.date, to: now).day ?? 0
            } else {
                daysSinceLastWalk = walkLogs.isEmpty ? 999 : 0
            }
            
            if daysSinceLastWalk >= 3 && !walkLogs.isEmpty {
                suggestions.append(ActionSuggestion(
                    emoji: "🚶",
                    message: "\(daysSinceLastWalk) gündür yürüyüş kaydı yok",
                    actionLabel: "Yürüyüş Ekle",
                    actionType: .addActivity(.walk),
                    priority: 2
                ))
            } else if walkLogs.isEmpty && !pet.activityLogs.isEmpty {
                suggestions.append(ActionSuggestion(
                    emoji: "🚶",
                    message: "Henüz yürüyüş kaydı yok",
                    actionLabel: "İlk Yürüyüşü Kaydet",
                    actionType: .addActivity(.walk),
                    priority: 5
                ))
            }
        }
        
        // 3. No feeding log in 2+ days
        let lastFeedingDate = pet.feedingLogs.sorted { $0.date > $1.date }.first?.date
        if let lastFeeding = lastFeedingDate {
            let daysSince = calendar.dateComponents([.day], from: lastFeeding, to: now).day ?? 0
            if daysSince >= 2 {
                suggestions.append(ActionSuggestion(
                    emoji: "🍽",
                    message: "\(daysSince) gündür beslenme kaydı girilmemiş",
                    actionLabel: "Mama Kaydı Ekle",
                    actionType: .addFeeding,
                    priority: 3
                ))
            }
        } else if pet.feedingLogs.isEmpty {
            suggestions.append(ActionSuggestion(
                emoji: "🍽",
                message: "Henüz beslenme kaydı yok",
                actionLabel: "İlk Kaydı Ekle",
                actionType: .addFeeding,
                priority: 6
            ))
        }
        
        // 4. Food running out in 5 days
        if let food = pet.currentFood {
            let daysLeft = food.daysUntilRunout
            if daysLeft <= 5 && daysLeft > 0 {
                suggestions.append(ActionSuggestion(
                    emoji: "📦",
                    message: "\(food.brand) \(daysLeft) gün sonra bitiyor",
                    actionLabel: "Mama Siparişi Ver",
                    actionType: .orderFood,
                    priority: 3
                ))
            }
        }
        
        // 5. Weight not recorded in 30+ days
        let lastWeightDate = pet.weightLogs.sorted { $0.date > $1.date }.first?.date
        if let lastWeight = lastWeightDate {
            let daysSince = calendar.dateComponents([.day], from: lastWeight, to: now).day ?? 0
            if daysSince >= 30 {
                suggestions.append(ActionSuggestion(
                    emoji: "⚖️",
                    message: "\(daysSince) gündür kilo ölçülmemiş",
                    actionLabel: "Kilo Ölç",
                    actionType: .addWeight,
                    priority: 4
                ))
            }
        }
        
        // 6. No vet visit in 6+ months
        let lastVetDate = pet.vetVisits.sorted { $0.date > $1.date }.first?.date
        if let lastVet = lastVetDate {
            let monthsSince = calendar.dateComponents([.month], from: lastVet, to: now).month ?? 0
            if monthsSince >= 6 {
                suggestions.append(ActionSuggestion(
                    emoji: "🏥",
                    message: "\(monthsSince) aydır veteriner kontrolü yok",
                    actionLabel: "Randevu Al",
                    actionType: .addVetVisit,
                    priority: 4
                ))
            }
        }
        
        // 7. No photo in 30+ days
        let lastPhotoDate = pet.photoLogs.sorted { $0.date > $1.date }.first?.date
        if let lastPhoto = lastPhotoDate {
            let daysSince = calendar.dateComponents([.day], from: lastPhoto, to: now).day ?? 0
            if daysSince >= 30 {
                suggestions.append(ActionSuggestion(
                    emoji: "📸",
                    message: "\(daysSince) gündür fotoğraf çekilmemiş",
                    actionLabel: "Fotoğraf Çek",
                    actionType: .addPhoto,
                    priority: 7
                ))
            }
        }
        
        return suggestions.sorted { $0.priority < $1.priority }
    }
    
    // MARK: - Default
    
    private static func defaultSuggestion(for pet: Pet) -> ActionSuggestion {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour < 12 {
            return ActionSuggestion(
                emoji: "☀️",
                message: "Günaydın! \(pet.name)'ın sabah rutinini kaydet",
                actionLabel: "Mama Kaydı Ekle",
                actionType: .addFeeding,
                priority: 10
            )
        } else if hour < 18 {
            return ActionSuggestion(
                emoji: "📸",
                message: "Bugün \(pet.name)'ın bir fotoğrafını çek!",
                actionLabel: "Fotoğraf Ekle",
                actionType: .addPhoto,
                priority: 10
            )
        } else {
            return ActionSuggestion(
                emoji: "🌙",
                message: "\(pet.name)'ın günlük özetini tamamla",
                actionLabel: "Kayıt Ekle",
                actionType: .addFeeding,
                priority: 10
            )
        }
    }
}
