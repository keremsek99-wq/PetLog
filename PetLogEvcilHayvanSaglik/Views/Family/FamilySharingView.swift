import SwiftUI
import CloudKit

/// Family sharing management — invite family members to co-manage a pet profile
struct FamilySharingView: View {
    let pet: Pet
    let store: PetStore

    @State private var members: [FamilyMember] = []
    @State private var showInviteSheet = false
    @State private var inviteEmail = ""
    @State private var inviteRole: MemberRole = .editor
    @State private var shareURL: URL?
    @State private var isLoading = true
    @State private var shareError: String?
    @State private var showShareLink = false
    @State private var generatedCode = ""

    enum MemberRole: String, CaseIterable, Identifiable {
        case owner = "Sahip"
        case editor = "Düzenleyici"
        case viewer = "Görüntüleyici"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .owner: return "crown.fill"
            case .editor: return "pencil.circle.fill"
            case .viewer: return "eye.fill"
            }
        }

        var description: String {
            switch self {
            case .owner: return "Tüm yetkilere sahip"
            case .editor: return "Kayıt ekleyebilir, düzenleyebilir"
            case .viewer: return "Sadece görüntüleyebilir"
            }
        }

        var color: Color {
            switch self {
            case .owner: return .orange
            case .editor: return .blue
            case .viewer: return .green
            }
        }
    }

    struct FamilyMember: Identifiable {
        let id = UUID()
        let name: String
        let email: String
        let role: MemberRole
        let joinDate: Date
        let avatarEmoji: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Text("👨‍👩‍👧‍👦")
                            .font(.system(size: 48))
                        Text("Aile Paylaşımı")
                            .font(.title2.weight(.bold))
                        Text("\(pet.name) profilini ailenizle paylaşın")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Current sharing status
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.blue)
                            Text("Üyeler (\(members.count + 1))")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }

                        // Owner (you)
                        memberRow(
                            emoji: "👑",
                            name: "Ben (Profil Sahibi)",
                            role: .owner,
                            isYou: true
                        )

                        ForEach(members) { member in
                            memberRow(
                                emoji: member.avatarEmoji,
                                name: member.name,
                                role: member.role,
                                isYou: false
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal)

                    // Invite methods
                    VStack(alignment: .leading, spacing: 12) {
                        Text("✉️ Davet Et")
                            .font(.subheadline.weight(.semibold))

                        // Invite via code
                        Button {
                            generateInviteCode()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "number.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Davet Kodu Oluştur")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Aile üyeniz kodu girerek katılsın")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        // Invite via link
                        Button {
                            generateShareLink()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "link.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Davet Linki Paylaş")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Paylaşılabilir link ile davet edin")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        // Join via code
                        Button {
                            showInviteSheet = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "rectangle.and.hand.point.up.left.filled")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Davet Koduna Katıl")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Başka birinin paylaştığı koda katıl")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // Invite code display
                    if !generatedCode.isEmpty {
                        VStack(spacing: 8) {
                            Text("Davet Kodunuz")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(generatedCode)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .kerning(8)
                                .foregroundStyle(.purple)

                            Text("Bu kodu aile üyenizle paylaşın, PetLog uygulamasından \"Davet Koduna Katıl\" ile katılabilir.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Button {
                                UIPasteboard.general.string = generatedCode
                            } label: {
                                Label("Kodu Kopyala", systemImage: "doc.on.doc")
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.08))
                        .clipShape(.rect(cornerRadius: 14))
                        .padding(.horizontal)
                    }

                    // Info card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Nasıl Çalışır?")
                                .font(.subheadline.weight(.semibold))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            howItWorksRow("1", "Bir davet kodu veya link oluşturun")
                            howItWorksRow("2", "Aile üyeniz kodu girerek katılır")
                            howItWorksRow("3", "\(pet.name)'in profilini birlikte yönetin")
                            howItWorksRow("4", "Herkes kayıt ekleyebilir, görebilir")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal)

                    // CloudKit status
                    VStack(spacing: 8) {
                        Image(systemName: "icloud.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        Text("iCloud ile Senkronize")
                            .font(.caption.weight(.semibold))
                        Text("Veriler Apple iCloud üzerinden güvenle paylaşılır. Apple hesabı giriş yapmış olmalıdır.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Aile Paylaşımı")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showInviteSheet) {
                joinWithCodeSheet
            }
            .alert("Hata", isPresented: .constant(shareError != nil)) {
                Button("Tamam") { shareError = nil }
            } message: {
                Text(shareError ?? "")
            }
        }
    }

    // MARK: - Components

    private func memberRow(emoji: String, name: String, role: MemberRole, isYou: Bool) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(role.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                    if isYou {
                        Text("(Siz)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: role.icon)
                        .font(.caption2)
                    Text(role.rawValue)
                        .font(.caption)
                }
                .foregroundStyle(role.color)
            }

            Spacer()

            if !isYou {
                Menu {
                    Button("Düzenleyici Yap") {}
                    Button("Görüntüleyici Yap") {}
                    Divider()
                    Button("Üyeyi Çıkar", role: .destructive) {}
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func howItWorksRow(_ number: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Text(number)
                .font(.caption.weight(.bold))
                .frame(width: 20, height: 20)
                .background(Color.blue.opacity(0.15))
                .foregroundStyle(.blue)
                .clipShape(Circle())
            Text(text)
                .font(.caption)
        }
    }

    private var joinWithCodeSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "rectangle.and.hand.point.up.left.filled")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("Davet Kodunu Girin")
                    .font(.title3.weight(.bold))

                TextField("6 haneli kod", text: $inviteEmail)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal, 40)

                Button {
                    // In production: validate code via CloudKit
                    showInviteSheet = false
                } label: {
                    Text("Katıl")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(inviteEmail.count < 6)
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Koda Katıl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { showInviteSheet = false }
                }
            }
        }
    }

    // MARK: - Actions

    private func generateInviteCode() {
        let digits = "0123456789"
        generatedCode = String((0..<6).map { _ in digits.randomElement()! })
    }

    private func generateShareLink() {
        // In production: create a CloudKit share record + deep link
        // For now, generate a share text
        generatedCode = String((0..<6).map { _ in "0123456789".randomElement()! })
        UIPasteboard.general.string = "PetLog'da \(pet.name)'in profilini paylaşıyorum! Davet kodu: \(generatedCode)"
    }
}
