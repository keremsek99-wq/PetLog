import SwiftUI

/// Family sharing management — currently a preview of upcoming functionality.
/// CloudKit sharing integration is planned for a future release.
struct FamilySharingView: View {
    let pet: Pet
    let store: PetStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("👨‍👩‍👧‍👦")
                            .font(.system(size: 48))
                        Text("Aile Paylaşımı")
                            .font(.title2.weight(.bold))
                        Text("\(pet.name) profilini ailenizle paylaşın")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Coming Soon Banner
                    VStack(spacing: 12) {
                        Image(systemName: "hammer.fill")
                            .font(.title)
                            .foregroundStyle(.orange)

                        Text("Yakında Geliyor")
                            .font(.headline)

                        Text("Aile paylaşımı özelliği şu anda geliştirme aşamasındadır. Yakında aile üyelerinizle evcil hayvan profillerini paylaşabileceksiniz.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 16))
                    .padding(.horizontal)

                    // Planned features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Planlanan Özellikler")
                            .font(.subheadline.weight(.semibold))

                        plannedFeatureRow(icon: "person.2.fill", color: .blue, title: "Aile Üyesi Davet", subtitle: "Kod veya link ile aile üyelerini davet edin")
                        plannedFeatureRow(icon: "lock.shield.fill", color: .purple, title: "Rol Yönetimi", subtitle: "Sahip, Düzenleyici ve Görüntüleyici rolleri")
                        plannedFeatureRow(icon: "icloud.fill", color: .cyan, title: "iCloud Senkronizasyon", subtitle: "Veriler Apple iCloud üzerinden güvenle paylaşılır")
                        plannedFeatureRow(icon: "bell.badge.fill", color: .red, title: "Paylaşılan Bildirimler", subtitle: "Tüm aile üyeleri önemli hatırlatmaları alır")
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal)

                    // Current alternative
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Şimdilik Ne Yapabilirsiniz?")
                                .font(.subheadline.weight(.semibold))
                        }

                        Text("iCloud senkronizasyonunu açarak aynı Apple hesabındaki tüm cihazlarınızda verilerinize erişebilirsiniz. Ayarlar > iCloud Senkronizasyon bölümünden aktif edin.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Aile Paylaşımı")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func plannedFeatureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
