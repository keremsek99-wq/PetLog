import Foundation

/// Breed database with health information per breed
struct BreedInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let species: PetSpecies
    let lifespan: String
    let size: String
    let healthRisks: [String]
    let recommendedChecks: [String]
    let careNotes: [String]

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(species)
    }

    static func == (lhs: BreedInfo, rhs: BreedInfo) -> Bool {
        lhs.name == rhs.name && lhs.species == rhs.species
    }
}

enum BreedDatabase {

    static func breeds(for species: PetSpecies) -> [BreedInfo] {
        switch species {
        case .dog: return dogBreeds
        case .cat: return catBreeds
        case .bird: return birdBreeds
        case .rabbit: return rabbitBreeds
        case .fish: return fishBreeds
        case .reptile: return reptileBreeds
        case .unspecified, .other: return []
        }
    }

    static func breedInfo(species: PetSpecies, breedName: String) -> BreedInfo? {
        breeds(for: species).first { $0.name == breedName }
    }

    // MARK: - Dog Breeds

    static let dogBreeds: [BreedInfo] = [
        BreedInfo(
            name: "Golden Retriever",
            species: .dog,
            lifespan: "10-12 yıl",
            size: "Büyük",
            healthRisks: [
                "Kalça displazisi: Büyük ırklarda yaygın eklem sorunu",
                "Kanser: Özellikle lenfoma ve hemanjiosarkoma riski yüksek",
                "Kalp hastalıkları: Subaortik stenoz görülebilir",
                "Obezite: Aşırı yeme eğilimi yüksek"
            ],
            recommendedChecks: [
                "Yıllık kalça/dirsek röntgeni",
                "6 ayda bir kalp kontrolü",
                "Düzenli göz muayenesi (PRA taraması)",
                "Yıllık tiroid kontrolü"
            ],
            careNotes: [
                "Günlük 1-2 saat egzersiz gerekir",
                "Haftada 2-3 kez fırçalama önerilir",
                "Yüzmeyi çok sever, su aktiviteleri idealdir",
                "Sosyal yapısı nedeniyle yalnız bırakılmamalıdır"
            ]
        ),
        BreedInfo(
            name: "Labrador Retriever",
            species: .dog,
            lifespan: "10-14 yıl",
            size: "Büyük",
            healthRisks: [
                "Kalça ve dirsek displazisi",
                "Obezite: Genetik olarak aşırı yeme eğilimi",
                "Egzersiz kaynaklı kollaps (EIC)",
                "Göz hastalıkları: Progresif retina atrofisi"
            ],
            recommendedChecks: [
                "Yıllık kalça ve dirsek değerlendirmesi",
                "Düzenli kilo takibi (ideal kilo korunmalı)",
                "Yıllık göz muayenesi",
                "EIC gen testi"
            ],
            careNotes: [
                "Günlük yoğun egzersiz gerekir",
                "Porsiyon kontrolü çok önemli",
                "Suya çok meraklıdır, kulaklar sonra kurulanmalı",
                "Düzenli tırnak kesimi gerekir"
            ]
        ),
        BreedInfo(
            name: "Alman Çoban Köpeği",
            species: .dog,
            lifespan: "9-13 yıl",
            size: "Büyük",
            healthRisks: [
                "Kalça displazisi: Irka özgü en yaygın sorun",
                "Dejeneratif miyelopati: Yaşlılıkta arka bacak zayıflığı",
                "Mide bükülmesi (GDV): Acil müdahale gerektirir",
                "Egzema ve deri alerjileri"
            ],
            recommendedChecks: [
                "Yıllık kalça röntgeni",
                "2 yaşından sonra DM gen testi",
                "Düzenli deri kontrolü",
                "Yıllık kan paneli"
            ],
            careNotes: [
                "Günlük 2+ saat egzersiz ve zihinsel aktivite",
                "Yoğun tüy dökümü dönemlerinde günlük fırçalama",
                "Mide bükülmesi riskini azaltmak için küçük porsiyonlar",
                "Erken sosyalizasyon çok önemli"
            ]
        ),
        BreedInfo(
            name: "French Bulldog",
            species: .dog,
            lifespan: "10-12 yıl",
            size: "Küçük",
            healthRisks: [
                "Brakisefali: Solunum güçlüğü, horlama",
                "Sıcak çarpması: Aşırı sıcağa toleransı düşük",
                "Omurga sorunları: İntervertebral disk hastalığı",
                "Deri kıvrım enfeksiyonları"
            ],
            recommendedChecks: [
                "Yıllık solunum değerlendirmesi",
                "Düzenli deri kıvrım kontrolü",
                "Omurga röntgeni (belirti varsa)",
                "Göz muayenesi (kuru göz riski)"
            ],
            careNotes: [
                "Sıcak havalarda dışarı çıkarmayın",
                "Yüzme yaptırmayın (boğulma riski yüksek)",
                "Deri kıvrımlarını günlük temizleyin",
                "Kısa yürüyüşler yeterlidir"
            ]
        ),
        BreedInfo(
            name: "Poodle (Kaniş)",
            species: .dog,
            lifespan: "12-15 yıl",
            size: "Küçük-Büyük (çeşidine göre)",
            healthRisks: [
                "Addison hastalığı: Böbrek üstü bezi yetmezliği",
                "Progresif retina atrofisi (PRA)",
                "Epilepsi",
                "Kalça displazisi (standart boyut)"
            ],
            recommendedChecks: [
                "Yıllık göz muayenesi",
                "Düzenli kan paneli (Addison taraması)",
                "Kalça değerlendirmesi (standart boyut)",
                "Diş kontrolü (diş taşı eğilimi)"
            ],
            careNotes: [
                "6-8 haftada bir profesyonel tıraş",
                "Tüy dökmeyen yapısı alerji hastalarına uygun",
                "Zihinsel stimülasyon çok önemli",
                "Kulak enfeksiyonuna yatkın, düzenli temizlik şart"
            ]
        ),
        BreedInfo(
            name: "Beagle",
            species: .dog,
            lifespan: "12-15 yıl",
            size: "Küçük-Orta",
            healthRisks: [
                "Obezite: Yeme dürtüsü çok güçlü",
                "Kulak enfeksiyonları: Sarkık kulak yapısı",
                "Epilepsi",
                "Hipotiroidi"
            ],
            recommendedChecks: [
                "Haftalık kulak kontrolü ve temizliği",
                "Düzenli kilo takibi",
                "Yıllık tiroid testi",
                "Göz muayenesi"
            ],
            careNotes: [
                "Yemek miktarını kesinlikle kontrol edin",
                "Kaçma eğilimi yüksek, güvenli alan şart",
                "Koklama oyunları zihinsel gelişim için ideal",
                "Sosyal yapısı, yalnız bırakılmayı sevmez"
            ]
        ),
        BreedInfo(
            name: "Siberian Husky",
            species: .dog,
            lifespan: "12-14 yıl",
            size: "Orta-Büyük",
            healthRisks: [
                "Göz hastalıkları: Katarakt, kornea distrofisi",
                "Kalça displazisi",
                "Otoimmün deri hastalıkları",
                "Çinko eksikliği dermatozu"
            ],
            recommendedChecks: [
                "Yıllık göz muayenesi",
                "Kalça röntgeni",
                "Deri kontrolü",
                "Düzenli kan paneli"
            ],
            careNotes: [
                "Çok yoğun egzersiz gerekir (günlük 2+ saat)",
                "Sıcak iklimlere uygun değil",
                "Yoğun tüy dökümü, günlük fırçalama gerekebilir",
                "Kaçma eğilimi yüksek"
            ]
        ),
        BreedInfo(
            name: "Chihuahua",
            species: .dog,
            lifespan: "14-16 yıl",
            size: "Minik",
            healthRisks: [
                "Patella lüksasyonu: Diz kapağı kayması",
                "Kalp hastalıkları: Mitral kapak hastalığı",
                "Hipoglisemi: Küçük yapı nedeniyle kan şekeri düşmesi",
                "Diş sorunları: Küçük çene, kalabalık dişler"
            ],
            recommendedChecks: [
                "6 ayda bir diş kontrolü",
                "Yıllık kalp muayenesi",
                "Diz değerlendirmesi",
                "Düzenli kan şekeri takibi"
            ],
            careNotes: [
                "Soğuk havada giydirin",
                "Düşme ve yaralanma riskine dikkat",
                "Az ama sık öğün (hipoglisemi önlemi)",
                "Erken diş bakımı çok önemli"
            ]
        ),
    ]

    // MARK: - Cat Breeds

    static let catBreeds: [BreedInfo] = [
        BreedInfo(
            name: "British Shorthair",
            species: .cat,
            lifespan: "12-20 yıl",
            size: "Orta-Büyük",
            healthRisks: [
                "Hipertrofik kardiyomiyopati (HCM)",
                "Polikistik böbrek hastalığı (PKD)",
                "Obezite: Sakin yapısı nedeniyle",
                "Hemofili B"
            ],
            recommendedChecks: [
                "Yıllık kalp ultrasonografisi (HCM taraması)",
                "Böbrek ultrasonografisi",
                "Düzenli kilo takibi",
                "Yıllık kan paneli"
            ],
            careNotes: [
                "Porsiyon kontrolü çok önemli",
                "Oyun ile harekete teşvik edin",
                "Haftada bir fırçalama yeterli",
                "Bağımsız yapısına rağmen düzenli ilgi ister"
            ]
        ),
        BreedInfo(
            name: "Scottish Fold",
            species: .cat,
            lifespan: "11-14 yıl",
            size: "Orta",
            healthRisks: [
                "Osteokondrodisplazi: Kıkırdak ve kemik anormallikleri",
                "Eklem sertliği ve ağrısı",
                "Hipertrofik kardiyomiyopati (HCM)",
                "Polikistik böbrek hastalığı"
            ],
            recommendedChecks: [
                "6 ayda bir eklem değerlendirmesi",
                "Yıllık kalp ultrasonografisi",
                "Hareket kısıtlılığı takibi",
                "Böbrek fonksiyon testi"
            ],
            careNotes: [
                "Eklem sağlığı için yumuşak yatak sağlayın",
                "Yüksek yerlere tırmanma zorlaştırabilir",
                "Ağrı belirtilerini (topallama, hareketsizlik) takip edin",
                "Kıkırdak desteği için veteriner takviyesi sorulabilir"
            ]
        ),
        BreedInfo(
            name: "İran Kedisi (Persian)",
            species: .cat,
            lifespan: "12-17 yıl",
            size: "Orta-Büyük",
            healthRisks: [
                "Polikistik böbrek hastalığı (PKD): Irka özgü yüksek risk",
                "Solunum sorunları: Düz yüz yapısı",
                "Göz yaşı lekesi ve enfeksiyonlar",
                "Deri mantar enfeksiyonları"
            ],
            recommendedChecks: [
                "Yıllık böbrek ultrasonografisi ve kan testi",
                "Düzenli göz temizliği kontrolü",
                "Deri ve tüy sağlığı değerlendirmesi",
                "Diş kontrolü"
            ],
            careNotes: [
                "Günlük fırçalama zorunlu (keçeleşme riski)",
                "Göz çevresi günlük temizlenmeli",
                "Sıcak ortamlarda solunum güçlüğü yaşayabilir",
                "Düzenli profesyonel tıraş gerekebilir"
            ]
        ),
        BreedInfo(
            name: "Siyam (Siamese)",
            species: .cat,
            lifespan: "15-20 yıl",
            size: "Orta",
            healthRisks: [
                "Amiloidoz: Karaciğer hastalığı riski",
                "Astım ve solunum yolu duyarlılığı",
                "Progresif retina atrofisi (PRA)",
                "Şaşılık (strabismus)"
            ],
            recommendedChecks: [
                "Yıllık karaciğer fonksiyon testi",
                "Göz muayenesi",
                "Solunum değerlendirmesi",
                "Diş kontrolü"
            ],
            careNotes: [
                "Çok sosyal, yalnız bırakılmayı sevmez",
                "Sesli iletişim kurar, bu normaldir",
                "Zihinsel stimülasyon ve oyun çok önemli",
                "Sıcak ortamları tercih eder"
            ]
        ),
        BreedInfo(
            name: "Maine Coon",
            species: .cat,
            lifespan: "12-15 yıl",
            size: "Büyük",
            healthRisks: [
                "Hipertrofik kardiyomiyopati (HCM): En yaygın risk",
                "Kalça displazisi: Büyük yapı nedeniyle",
                "Spinal musküler atrofi (SMA)",
                "Polikistik böbrek hastalığı"
            ],
            recommendedChecks: [
                "Yıllık kalp ultrasonografisi (HCM gen testi)",
                "Kalça değerlendirmesi",
                "SMA gen testi",
                "Düzenli kilo ve kas takibi"
            ],
            careNotes: [
                "Haftada 2-3 kez fırçalama",
                "Büyük kedi ağacı ve alan gerekir",
                "Suyla oynamayı sevebilir",
                "Yavaş büyür, 3-5 yaşına kadar tam boyuta ulaşır"
            ]
        ),
        BreedInfo(
            name: "Tekir (Tabby)",
            species: .cat,
            lifespan: "15-20 yıl",
            size: "Orta",
            healthRisks: [
                "Obezite: Ev kedilerinde en yaygın sorun",
                "İdrar yolu hastalıkları",
                "Diş hastalıkları: Yaşla birlikte artar",
                "Böbrek yetmezliği (yaşlı dönem)"
            ],
            recommendedChecks: [
                "Yıllık genel kontrol ve kan paneli",
                "7 yaşından sonra 6 ayda bir böbrek testi",
                "Yıllık diş kontrolü",
                "Düzenli kilo takibi"
            ],
            careNotes: [
                "Porsiyon kontrolü ile obeziteyi önleyin",
                "Bol su içmesi için çeşme tipi su kabı önerilebilir",
                "İç mekan zenginleştirme (oyuncak, tırmalama tahtası)",
                "Düzenli veteriner kontrolleri"
            ]
        ),
    ]

    // MARK: - Bird Breeds

    static let birdBreeds: [BreedInfo] = [
        BreedInfo(
            name: "Muhabbet Kuşu",
            species: .bird,
            lifespan: "5-10 yıl",
            size: "Küçük",
            healthRisks: [
                "Tümörler: Özellikle yağ tümörleri (lipom)",
                "Burun akıntısı ve solunum enfeksiyonları",
                "Karaciğer hastalıkları",
                "Guatr (iyot eksikliği)"
            ],
            recommendedChecks: [
                "Yıllık genel kontrol",
                "Dışkı analizi",
                "Gaga ve tırnak kontrolü",
                "Tüy sağlığı değerlendirmesi"
            ],
            careNotes: [
                "Çeşitli tohum karışımı + taze sebze/meyve",
                "Günlük kafes dışı uçuş zamanı",
                "Gece 12 saat karanlık ve sessizlik",
                "Teflon tavalar zehirli, mutfaktan uzak tutun"
            ]
        ),
        BreedInfo(
            name: "Sultan Papağanı",
            species: .bird,
            lifespan: "15-25 yıl",
            size: "Küçük-Orta",
            healthRisks: [
                "Yağ karaciğer hastalığı: Yüksek yağlı diyet",
                "Kronik yumurtlama (dişilerde)",
                "Solunum enfeksiyonları",
                "Tüy yolma (stres kaynaklı)"
            ],
            recommendedChecks: [
                "Yıllık genel ve kan kontrolü",
                "Tüy ve deri değerlendirmesi",
                "Dışkı parazit analizi",
                "Kilo takibi"
            ],
            careNotes: [
                "Tohum yanında pellet ve taze gıda verin",
                "Sosyal etkileşim çok önemli",
                "Toz banyosu ihtiyacı vardır",
                "Islık ve melodi öğrenmeye yatkındır"
            ]
        ),
    ]

    // MARK: - Rabbit Breeds

    static let rabbitBreeds: [BreedInfo] = [
        BreedInfo(
            name: "Hollanda Lop",
            species: .rabbit,
            lifespan: "7-12 yıl",
            size: "Küçük",
            healthRisks: [
                "Diş problemleri: Malocclusion (diş uyumsuzluğu)",
                "GI Staz: Sindirim durması",
                "Kulak enfeksiyonları: Sarkık kulak yapısı",
                "Solunum rahatsızlıkları"
            ],
            recommendedChecks: [
                "6 ayda bir diş kontrolü",
                "Kulak kontrolü (aylık)",
                "Dışkı takibi (boyut ve miktar)",
                "Yıllık genel kontrol"
            ],
            careNotes: [
                "Sınırsız timothy otu sağlayın",
                "Sarkık kulakları düzenli temizleyin",
                "En az 4 saat serbest dolaşma",
                "Kısırlaştırma güçlü önerilir"
            ]
        ),
        BreedInfo(
            name: "Rex Tavşan",
            species: .rabbit,
            lifespan: "7-10 yıl",
            size: "Orta",
            healthRisks: [
                "Sore hocks: Ayak tabanı yaraları",
                "GI Staz",
                "Obezite",
                "Üst solunum yolu enfeksiyonları"
            ],
            recommendedChecks: [
                "Ayak tabanı kontrolü (aylık)",
                "Düzenli kilo takibi",
                "Diş kontrolü",
                "Yıllık genel muayene"
            ],
            careNotes: [
                "Yumuşak zemin sağlayın (sore hocks önlemi)",
                "İnce kadife tüyü özel bakım gerektirmez",
                "Yüksek lifli diyet (saman %80+)",
                "Taze sebze günlük verilmeli"
            ]
        ),
    ]

    // MARK: - Fish Breeds

    static let fishBreeds: [BreedInfo] = [
        BreedInfo(
            name: "Beta (Betta)",
            species: .fish,
            lifespan: "3-5 yıl",
            size: "Küçük",
            healthRisks: [
                "Yüzgeç çürümesi",
                "İç parazitler",
                "Swim bladder bozukluğu",
                "Beyaz nokta hastalığı (Ich)"
            ],
            recommendedChecks: [
                "Haftalık su testi (pH, amonyak, nitrit)",
                "Günlük davranış gözlemi",
                "Yüzgeç durumu takibi",
                "Aylık filtre bakımı"
            ],
            careNotes: [
                "Minimum 20 litre akvaryum",
                "25-28°C su sıcaklığı",
                "Erkekleri asla bir arada tutmayın",
                "Canlı veya dondurulmuş yem idealdir"
            ]
        ),
        BreedInfo(
            name: "Japon Balığı (Goldfish)",
            species: .fish,
            lifespan: "10-15 yıl",
            size: "Orta",
            healthRisks: [
                "Swim bladder hastalığı",
                "Beyaz nokta (Ich)",
                "Bakteriyel enfeksiyonlar",
                "Amonyak zehirlenmesi (küçük tanklarda)"
            ],
            recommendedChecks: [
                "Haftalık su parametresi ölçümü",
                "Haftalık %25 su değişimi",
                "Filtre kapasitesi yeterliliği",
                "Yem miktarı kontrolü"
            ],
            careNotes: [
                "Balık başına minimum 75 litre",
                "Isıtıcıya gerek yok (18-23°C)",
                "Çok kirletirler, güçlü filtrasyon şart",
                "Fan kuyruklu çeşitler daha hassas"
            ]
        ),
    ]

    // MARK: - Reptile Breeds

    static let reptileBreeds: [BreedInfo] = [
        BreedInfo(
            name: "Sakallı Ejderha (Bearded Dragon)",
            species: .reptile,
            lifespan: "8-15 yıl",
            size: "Orta",
            healthRisks: [
                "Metabolik kemik hastalığı (MBD): Kalsiyum/UVB eksikliği",
                "Parazit enfeksiyonları",
                "Organ prolapsusu",
                "Sarı mantar hastalığı"
            ],
            recommendedChecks: [
                "6 ayda bir veteriner kontrolü",
                "Yıllık dışkı parazit analizi",
                "Kalsiyum seviyesi testi",
                "UVB lamba yenileme (her 6 ay)"
            ],
            careNotes: [
                "Basking spot 38-43°C olmalı",
                "UVB ışık 12 saat açık",
                "Canlı böcek + taze sebze diyeti",
                "Kalsiyum tozu takviyesi şart"
            ]
        ),
        BreedInfo(
            name: "Leopar Gecko'su",
            species: .reptile,
            lifespan: "15-20 yıl",
            size: "Küçük",
            healthRisks: [
                "Metabolik kemik hastalığı",
                "Kripto (Cryptosporidiosis)",
                "Deri dökülme sorunları",
                "Kuyruk düşürme (stres)"
            ],
            recommendedChecks: [
                "6 ayda bir genel kontrol",
                "Dışkı parazit analizi",
                "Deri dökülme takibi",
                "Kilo kaydı"
            ],
            careNotes: [
                "Gece aktif, gündüz gizlenme alanı verin",
                "Sıcak bölge 28-32°C, soğuk bölge 24°C",
                "Nemli bir gizlenme alanı (deri dökümü için)",
                "Canlı böcek diyeti (cırcır böceği, solucan)"
            ]
        ),
    ]
}
