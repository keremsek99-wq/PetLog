import SwiftUI

struct TurkeyResourcesView: View {
    var body: some View {
        List {
            Section("Acil Veteriner Hatları") {
                InfoRow(title: "Tarım ve Orman Bakanlığı", detail: "ALO 174", icon: "phone.fill", color: .red)
                InfoRow(title: "HAYTAP Hayvan Hakları", detail: "0212 244 26 14", icon: "phone.fill", color: .green)
            }

            Section("Faydalı Bilgiler") {
                InfoRow(title: "Evcil Hayvan Pasaportu", detail: "Yurt dışı seyahat için veterinerinizden alın", icon: "doc.text.fill", color: .blue)
                InfoRow(title: "Çip Zorunluluğu", detail: "Tüm kedi ve köpekler için zorunlu", icon: "sensor.fill", color: .purple)
                InfoRow(title: "Kuduz Aşısı", detail: "Yılda bir kez zorunlu", icon: "syringe.fill", color: .orange)
            }

            Section("Popüler Mama Markaları") {
                InfoRow(title: "ProPlan", detail: "Veteriner önerili premium mama", icon: "fork.knife", color: .orange)
                InfoRow(title: "Royal Canin", detail: "Irka özel mama seçenekleri", icon: "fork.knife", color: .red)
                InfoRow(title: "Acana / Orijen", detail: "Doğal içerikli premium mama", icon: "fork.knife", color: .green)
                InfoRow(title: "Bonacibo", detail: "Türk üretimi kaliteli mama", icon: "fork.knife", color: .teal)
                InfoRow(title: "Jungle", detail: "Türk üretimi ekonomik mama", icon: "fork.knife", color: .brown)
            }

            Section("Online Alışveriş") {
                InfoRow(title: "PetCity", detail: "petcity.com.tr", icon: "cart.fill", color: .blue)
                InfoRow(title: "PetBurada", detail: "petburada.com", icon: "cart.fill", color: .green)
                InfoRow(title: "Zooplus TR", detail: "zooplus.com.tr", icon: "cart.fill", color: .orange)
            }
        }
        .navigationTitle("Faydalı Bilgiler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let title: String
    let detail: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(.rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
