import Foundation

/// Daily tips database keyed by species + breed
enum BreedTipsDatabase {

    /// Returns a random daily tip for the given species and breed
    static func dailyTip(species: PetSpecies, breed: String) -> BreedTip {
        let tips = allTips(for: species, breed: breed)
        guard !tips.isEmpty else {
            return BreedTip(emoji: "🐾", title: "Günlük Bakım", body: "Evcil hayvanınıza sevgi ve ilgi göstermeyi unutmayın!", category: .care)
        }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % tips.count
        return tips[index]
    }

    static func allTips(for species: PetSpecies, breed: String) -> [BreedTip] {
        var tips = generalTips(for: species)

        // Add breed-specific tips if available
        if let breedInfo = BreedDatabase.breedInfo(species: species, breedName: breed) {
            tips += breedSpecificTips(from: breedInfo)
        }

        // Add seasonal tips
        tips += seasonalTips(for: species)

        return tips.isEmpty ? fallbackTips : tips
    }

    // MARK: - General Species Tips

    private static func generalTips(for species: PetSpecies) -> [BreedTip] {
        switch species {
        case .dog:
            return [
                BreedTip(emoji: "🦷", title: "Diş Bakımı", body: "Köpeğinizin dişlerini haftada 2-3 kez fırçalayın. Diş hastalıkları organ sorunlarına yol açabilir.", category: .health),
                BreedTip(emoji: "🚶", title: "Yürüyüş Rutini", body: "Sabah ve akşam düzenli yürüyüşler hem fiziksel hem zihinsel sağlık için önemlidir.", category: .activity),
                BreedTip(emoji: "💧", title: "Su Tüketimi", body: "Köpeğiniz kilo başına günde yaklaşık 50ml su içmelidir. Su kabını her gün yenileyin.", category: .nutrition),
                BreedTip(emoji: "🧴", title: "Tırnak Bakımı", body: "Tırnaklar yere değiyorsa kesmek gerekir. Uzun tırnaklar yürüyüş sorunlarına yol açar.", category: .grooming),
                BreedTip(emoji: "🎾", title: "Oyun Zamanı", body: "Günde en az 15-30 dakika interaktif oyun, köpeğinizin mutluluğunu artırır.", category: .activity),
                BreedTip(emoji: "🛁", title: "Banyo Sıklığı", body: "Çoğu köpek için ayda 1-2 banyo yeterlidir. Fazla banyo cildi kurutabilir.", category: .grooming),
                BreedTip(emoji: "🍖", title: "Zararlı Gıdalar", body: "Çikolata, üzüm, soğan, sarımsak ve ksilitol köpekler için zehirlidir!", category: .nutrition),
                BreedTip(emoji: "🌡️", title: "Sıcaklık Kontrolü", body: "Sıcak havalarda asfaltta yürütmeyin — elinizi 5sn asfalta tutun, yakıyorsa patiyi de yakar.", category: .health),
                BreedTip(emoji: "😴", title: "Uyku İhtiyacı", body: "Yetişkin köpekler günde 12-14 saat uyur. Sakin bir dinlenme alanı sağlayın.", category: .health),
                BreedTip(emoji: "🧠", title: "Zihinsel Aktivite", body: "Puzzle oyuncakları ve koklama oyunları, köpeğinizin beyin gelişimini destekler.", category: .activity),
            ]
        case .cat:
            return [
                BreedTip(emoji: "🧶", title: "Oyun Zamanı", body: "Günde en az 15 dakika interaktif oyun, kedinizin av içgüdüsünü tatmin eder.", category: .activity),
                BreedTip(emoji: "💧", title: "Su Tüketimi", body: "Kediler çeşme tipi su kaplarını tercih eder. Akan su, böbrek sağlığını destekler.", category: .nutrition),
                BreedTip(emoji: "🪥", title: "Tırmalama Tahtası", body: "Her odada en az bir tırmalama tahtası olmalı. Tırnakları ve kasları sağlıklı tutar.", category: .grooming),
                BreedTip(emoji: "🏠", title: "Dikey Alan", body: "Kediler yüksek yerleri sever. Kedi ağacı veya raf sistemleri ile dikey alan sağlayın.", category: .activity),
                BreedTip(emoji: "🥩", title: "Protein İhtiyacı", body: "Kediler zorunlu etçildir. Yüksek proteinli, az karbonhidratlı diyetler idealdir.", category: .nutrition),
                BreedTip(emoji: "🧹", title: "Kum Kabı Temizliği", body: "Kum kabını günde 1 kez temizleyin. Kedi başına +1 kum kabı kuralını uygulayın.", category: .grooming),
                BreedTip(emoji: "🌿", title: "Zehirli Bitkiler", body: "Zambak, aloe vera ve pothoslar kediler için zehirlidir. Ev bitkilerinizi kontrol edin!", category: .health),
                BreedTip(emoji: "😺", title: "Stres Belirtileri", body: "Aşırı tırmık, idrar dışı tuvalet, iştahsızlık stres belirtisi olabilir.", category: .health),
                BreedTip(emoji: "🦷", title: "Diş Sağlığı", body: "3 yaş üstü kedilerin %70'inde diş hastalığı var. Yıllık diş kontrolü yaptırın.", category: .health),
                BreedTip(emoji: "🌙", title: "Gece Aktivitesi", body: "Yatmadan önce yoğun oyun + küçük bir yemek, gece uyanmalarını azaltır.", category: .activity),
            ]
        case .bird:
            return [
                BreedTip(emoji: "🎵", title: "Sesli İletişim", body: "Kuşlar sesle iletişim kurar. Ani sessizlik hastalık belirtisi olabilir.", category: .health),
                BreedTip(emoji: "🥬", title: "Taze Beslenme", body: "Sadece tohum yeterli değil! Taze sebze ve meyve ile beslenmeyi zenginleştirin.", category: .nutrition),
                BreedTip(emoji: "🌅", title: "Uyku Düzeni", body: "Kuşlar 10-12 saat karanlık ve sessiz uyku ortamına ihtiyaç duyar.", category: .health),
                BreedTip(emoji: "✈️", title: "Uçuş Zamanı", body: "Günlük kafes dışı uçuş zamanı kas gelişimi ve mutluluk için önemlidir.", category: .activity),
                BreedTip(emoji: "⚠️", title: "Teflon Tehlikesi", body: "Teflon tavalar ısındığında kuşlar için ölümcül gaz yayar. Mutfaktan uzak tutun!", category: .health),
            ]
        case .rabbit:
            return [
                BreedTip(emoji: "🥕", title: "Saman Diyeti", body: "Diyetin ≥%80'i timothy otu olmalı. Saman sindirim sağlığı ve diş aşınması için kritiktir.", category: .nutrition),
                BreedTip(emoji: "🏃", title: "Egzersiz Alanı", body: "Günde en az 4 saat serbest dolaşma alanı sağlayın.", category: .activity),
                BreedTip(emoji: "🐰", title: "GI Staz Uyarısı", body: "12 saatten fazla yemek yememe veya dışkılama acil durumdur, hemen veterinere gidin!", category: .health),
                BreedTip(emoji: "🧹", title: "Temizlik", body: "Tavşanlar kendilerini temizler, banyo yapılmamalıdır. Sadece spot temizlik yapın.", category: .grooming),
            ]
        case .fish:
            return [
                BreedTip(emoji: "🌊", title: "Su Değişimi", body: "Haftalık %25 su değişimi sağlıklı akvaryum için zorunludur.", category: .health),
                BreedTip(emoji: "🌡️", title: "Sıcaklık Kontrolü", body: "Ani sıcaklık değişimleri balıklar için streslidir. Termometre ile takip edin.", category: .health),
                BreedTip(emoji: "🍽️", title: "Aşırı Besleme", body: "Günde 1-2 kez, 2 dakikada yiyeceği kadar yem verin. Fazla yem suyu kirletir.", category: .nutrition),
            ]
        case .reptile:
            return [
                BreedTip(emoji: "☀️", title: "UVB Işık", body: "UVB lambayı 6 ayda bir değiştirin. Görünür ışık verse bile UV üretimi azalır.", category: .health),
                BreedTip(emoji: "🦴", title: "Kalsiyum Takviyesi", body: "Metabolik kemik hastalığını önlemek için canlı yemleri kalsiyum tozuyla kaplayın.", category: .nutrition),
                BreedTip(emoji: "💦", title: "Nem Kontrolü", body: "Deri dökümü sorunları genellikle düşük nem kaynaklıdır. Nemli gizlenme alanı sağlayın.", category: .grooming),
            ]
        case .unspecified, .other:
            return fallbackTips
        }
    }

    // MARK: - Breed-Specific Tips (from BreedInfo)

    private static func breedSpecificTips(from info: BreedInfo) -> [BreedTip] {
        var tips: [BreedTip] = []

        for risk in info.healthRisks {
            tips.append(BreedTip(emoji: "⚠️", title: "\(info.name) Sağlık", body: risk, category: .health))
        }
        for note in info.careNotes {
            tips.append(BreedTip(emoji: "💡", title: "\(info.name) Bakım", body: note, category: .care))
        }

        return tips
    }

    // MARK: - Seasonal Tips

    private static func seasonalTips(for species: PetSpecies) -> [BreedTip] {
        let month = Calendar.current.component(.month, from: Date())

        switch month {
        case 3...5: // İlkbahar
            return [
                BreedTip(emoji: "🌸", title: "İlkbahar Alerjileri", body: "İlkbahar alerjileri hayvanları da etkiler. Kaşıntı, hapşırma belirtilerini izleyin.", category: .health),
                BreedTip(emoji: "🐛", title: "Parazit Sezonu", body: "Hava ısınıyor! İç ve dış parazit koruma programını kontrol edin.", category: .health),
            ]
        case 6...8: // Yaz
            return [
                BreedTip(emoji: "🥵", title: "Sıcak Çarpması", body: "Aşırı soluma, salya ve halsizlik sıcak çarpması belirtisidir. Serinletin ve veterinere gidin!", category: .health),
                BreedTip(emoji: "💧", title: "Hidrasyon", body: "Sıcak havalarda su tüketimini iki katına çıkarın. Her yürüyüşe su götürün.", category: .nutrition),
            ]
        case 9...11: // Sonbahar
            return [
                BreedTip(emoji: "🍂", title: "Tüy Dönüşümü", body: "Sonbahar tüy dökümü normaldir. Fırçalama sıklığını artırın.", category: .grooming),
                BreedTip(emoji: "🏥", title: "Yıllık Kontrol", body: "Kış öncesi yıllık veteriner kontrolü yaptırmak için ideal zaman!", category: .health),
            ]
        case 12, 1, 2: // Kış
            return [
                BreedTip(emoji: "❄️", title: "Soğuk Koruma", body: "Küçük ve kısa tüylü hayvanlar soğuktan etkilenir. Kısa dış çıkışlar ve giysi kullanın.", category: .health),
                BreedTip(emoji: "🧂", title: "Tuz Tehlikesi", body: "Kaldırımlardaki buz eritici tuzlar patileri tahriş eder. Yürüyüşten sonra patileri silin.", category: .health),
            ]
        default:
            return []
        }
    }

    // MARK: - Fallback

    private static let fallbackTips: [BreedTip] = [
        BreedTip(emoji: "❤️", title: "Düzenli Kontrol", body: "Yılda en az bir kez veteriner kontrolü hayvanınızın sağlığı için çok önemlidir.", category: .health),
        BreedTip(emoji: "📸", title: "Anıları Kaydedin", body: "Düzenli fotoğraf çekmek, büyüme sürecini ve değişimleri takip etmenizi sağlar.", category: .care),
    ]
}

// MARK: - BreedTip Model

struct BreedTip: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let body: String
    let category: TipCategory

    enum TipCategory: String {
        case health = "Sağlık"
        case nutrition = "Beslenme"
        case activity = "Aktivite"
        case grooming = "Bakım"
        case care = "Genel"
    }
}
