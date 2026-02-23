import SwiftUI

struct PrivacyView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                    Text("Verileriniz Güvende")
                        .font(.headline)
                    Text("PetLog, verilerinizi cihazınızda saklar. Verileriniz sunucularımıza gönderilmez ve üçüncü taraflarla paylaşılmaz.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Veri Saklama") {
                InfoRow(title: "Yerel Depolama", detail: "Tüm veriler cihazınızda saklanır", icon: "iphone", color: .blue)
                InfoRow(title: "Şifreleme", detail: "iOS veri koruma ile şifrelenir", icon: "lock.fill", color: .green)
                InfoRow(title: "Biyometrik Kilit", detail: "Face ID/Touch ID ile koruma", icon: "faceid", color: .purple)
            }

            Section("KVKK Uyumu") {
                InfoRow(title: "Veri Taşınabilirliği", detail: "Verilerinizi JSON olarak dışa aktarın", icon: "square.and.arrow.up", color: .orange)
                InfoRow(title: "Veri Silme", detail: "Tüm verilerinizi kalıcı olarak silin", icon: "trash", color: .red)
                InfoRow(title: "Reklam Yok", detail: "Kişisel verileriniz reklam için kullanılmaz", icon: "nosign", color: .green)
            }

            Section("Tıbbi Sorumluluk Reddi") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PetLog tıbbi teşhis veya tedavi önerisi vermez. Uygulama içindeki tüm öneriler yalnızca bilgilendirme amaçlıdır.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Evcil hayvanınızın sağlığıyla ilgili endişeleriniz için her zaman lisanslı bir veterinere başvurun.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Gizlilik & Veriler")
        .navigationBarTitleDisplayMode(.inline)
    }
}
