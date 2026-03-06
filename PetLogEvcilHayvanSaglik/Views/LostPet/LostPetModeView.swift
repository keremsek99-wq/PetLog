import SwiftUI
import CoreImage.CIFilterBuiltins

struct LostPetModeView: View {
    let pet: Pet
    let store: PetStore

    @State private var isLostMode = false
    @State private var lastSeenLocation = ""
    @State private var lastSeenDate = Date()
    @State private var contactPhone = ""
    @State private var contactName = ""
    @State private var additionalNotes = ""
    @State private var showPosterPreview = false
    @State private var showQRCard = false
    @State private var reward = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(isLostMode ? "🔴" : "🟢")
                            .font(.system(size: 48))
                        Text(isLostMode ? "KAYIP MODU AKTİF" : "Kayıp Hayvan Modu")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(isLostMode ? .red : .primary)
                        Text("Kayıp poster, QR kimlik kartı ve paylaşım araçları")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Toggle lost mode
                    Toggle(isOn: $isLostMode) {
                        HStack {
                            Image(systemName: isLostMode ? "exclamationmark.triangle.fill" : "shield.checkmark.fill")
                                .foregroundStyle(isLostMode ? .red : .green)
                            VStack(alignment: .leading) {
                                Text(isLostMode ? "Kayıp Modu Aktif" : "Kayıp Modu Kapalı")
                                    .font(.subheadline.weight(.semibold))
                                Text(isLostMode ? "Paylaşım araçları aktif" : "Hayvanınız güvende")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(isLostMode ? Color.red.opacity(0.08) : Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal)

                    // QR ID Card (always available)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🪪 QR Kimlik Kartı")
                            .font(.subheadline.weight(.semibold))

                        Button {
                            showQRCard = true
                        } label: {
                            HStack(spacing: 14) {
                                qrCodeImage(for: generateQRData())
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(pet.name) — Kimlik Kartı")
                                        .font(.subheadline.weight(.semibold))
                                    Text("QR kodu tarattırarak bilgilere ulaşılabilir")
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

                    if isLostMode {
                        // Lost pet info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📋 Kayıp Bilgileri")
                                .font(.subheadline.weight(.semibold))

                            TextField("Son Görülen Konum", text: $lastSeenLocation)
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 10))

                            DatePicker("Son Görülme Tarihi", selection: $lastSeenDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 10))

                            TextField("İletişim Adı", text: $contactName)
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 10))

                            TextField("İletişim Telefon", text: $contactPhone)
                                .keyboardType(.phonePad)
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 10))

                            TextField("Ödül (opsiyonel)", text: $reward)
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 10))

                            TextField("Ek Notlar (ayırt edici özellikler vb.)", text: $additionalNotes, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 10))
                        }
                        .padding(.horizontal)

                        // Actions
                        VStack(spacing: 10) {
                            Button {
                                showPosterPreview = true
                            } label: {
                                Label("Kayıp Poster Oluştur", systemImage: "doc.richtext.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)

                            ShareLink(item: generateShareText()) {
                                Label("Sosyal Medyada Paylaş", systemImage: "square.and.arrow.up")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Kayıp Modu")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPosterPreview) {
                LostPetPosterView(
                    pet: pet,
                    lastSeenLocation: lastSeenLocation,
                    lastSeenDate: lastSeenDate,
                    contactName: contactName,
                    contactPhone: contactPhone,
                    reward: reward,
                    additionalNotes: additionalNotes
                )
            }
            .sheet(isPresented: $showQRCard) {
                QRIDCardView(pet: pet)
            }
        }
    }

    // MARK: - QR Code

    private func generateQRData() -> String {
        var info = "PetLog KİMLİK\n"
        info += "Ad: \(pet.name)\n"
        info += "Tür: \(pet.species.rawValue)\n"
        info += "Irk: \(pet.breed)\n"
        if !pet.microchipID.isEmpty { info += "Mikroçip: \(pet.microchipID)\n" }
        if !pet.emergencyContactPhone.isEmpty { info += "İletişim: \(pet.emergencyContactPhone)\n" }
        if !pet.allergies.isEmpty { info += "Alerji: \(pet.allergies)\n" }
        return info
    }

    private func qrCodeImage(for string: String) -> Image {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return Image(uiImage: UIImage(cgImage: cgImage))
        }
        return Image(systemName: "qrcode")
    }

    private func generateShareText() -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateFormat = "d MMMM yyyy, HH:mm"

        var text = "🚨 KAYIP HAYVAN 🚨\n\n"
        text += "🐾 Ad: \(pet.name)\n"
        text += "📋 Tür: \(pet.species.rawValue)\n"
        text += "🏷 Irk: \(pet.breed)\n"
        if !pet.microchipID.isEmpty { text += "📡 Mikroçip: \(pet.microchipID)\n" }
        text += "\n📍 Son Görülen: \(lastSeenLocation)\n"
        text += "🕐 Tarih: \(df.string(from: lastSeenDate))\n"
        if !additionalNotes.isEmpty { text += "📝 Not: \(additionalNotes)\n" }
        if !reward.isEmpty { text += "💰 Ödül: \(reward) TL\n" }
        text += "\n📞 İletişim: \(contactName) \(contactPhone)\n"
        text += "\nLütfen gördüyseniz haber verin! 🙏"
        return text
    }
}

// MARK: - QR ID Card View

struct QRIDCardView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Card
                VStack(spacing: 16) {
                    // Pet info header
                    HStack(spacing: 14) {
                        Text(pet.emoji)
                            .font(.system(size: 40))
                            .frame(width: 56, height: 56)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pet.name)
                                .font(.title2.weight(.bold))
                            Text("\(pet.species.rawValue) • \(pet.breed)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Yaş: \(pet.age)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    Divider()

                    // QR Code
                    qrCodeImage(for: generateQRData())
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)

                    Text("Bu QR kodu tarattırarak\n\(pet.name)'in bilgilerine ulaşabilirsiniz")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Divider()

                    // Key info
                    VStack(spacing: 8) {
                        if !pet.microchipID.isEmpty {
                            infoRow(icon: "barcode", label: "Mikroçip", value: pet.microchipID)
                        }
                        if !pet.bloodType.isEmpty {
                            infoRow(icon: "drop.fill", label: "Kan Grubu", value: pet.bloodType)
                        }
                        if !pet.allergies.isEmpty {
                            infoRow(icon: "exclamationmark.triangle", label: "Alerji", value: pet.allergies)
                        }
                        if !pet.emergencyContactPhone.isEmpty {
                            infoRow(icon: "phone.fill", label: "İletişim", value: pet.emergencyContactPhone)
                        }
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                .padding(.horizontal, 24)

                Spacer()

                ShareLink(item: generateQRData()) {
                    Label("Kartı Paylaş", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("QR Kimlik Kartı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
        }
    }

    private func generateQRData() -> String {
        var info = "PetLog KİMLİK\n"
        info += "Ad: \(pet.name)\n"
        info += "Tür: \(pet.species.rawValue)\n"
        info += "Irk: \(pet.breed)\n"
        if !pet.microchipID.isEmpty { info += "Mikroçip: \(pet.microchipID)\n" }
        if !pet.emergencyContactPhone.isEmpty { info += "İletişim: \(pet.emergencyContactPhone)\n" }
        if !pet.allergies.isEmpty { info += "Alerji: \(pet.allergies)\n" }
        return info
    }

    private func qrCodeImage(for string: String) -> Image {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return Image(uiImage: UIImage(cgImage: cgImage))
        }
        return Image(systemName: "qrcode")
    }
}

// MARK: - Lost Pet Poster View

struct LostPetPosterView: View {
    let pet: Pet
    let lastSeenLocation: String
    let lastSeenDate: Date
    let contactName: String
    let contactPhone: String
    let reward: String
    let additionalNotes: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // RED HEADER
                    VStack(spacing: 8) {
                        Text("🚨 KAYIP HAYVAN 🚨")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(.white)
                        Text("LÜTFEN YARDIM EDİN")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.red)

                    // Pet photo placeholder
                    VStack(spacing: 8) {
                        if let photoData = pet.photoLogs.sorted(by: { $0.date > $1.date }).first?.imageData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 250)
                                .clipped()
                        } else {
                            VStack(spacing: 8) {
                                Text(pet.emoji)
                                    .font(.system(size: 80))
                                Text("Fotoğraf Yok")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .background(Color(.systemGray6))
                        }
                    }

                    // Pet info
                    VStack(spacing: 12) {
                        Text(pet.name)
                            .font(.system(size: 32, weight: .bold))

                        HStack(spacing: 16) {
                            infoPill("🐾 \(pet.species.rawValue)")
                            infoPill("📋 \(pet.breed)")
                            infoPill("📅 \(pet.age)")
                        }
                    }
                    .padding()

                    Divider().padding(.horizontal)

                    // Last seen
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Son Görülen Yer")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(lastSeenLocation.isEmpty ? "Belirtilmedi" : lastSeenLocation)
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Son Görülme Tarihi")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                let df: DateFormatter = {
                                    let f = DateFormatter()
                                    f.locale = Locale(identifier: "tr_TR")
                                    f.dateFormat = "d MMMM yyyy, HH:mm"
                                    return f
                                }()
                                Text(df.string(from: lastSeenDate))
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()

                    // Distinguishing features
                    if !additionalNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ayırt Edici Özellikler")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(additionalNotes)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }

                    // Microchip
                    if !pet.microchipID.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "barcode")
                                .foregroundStyle(.blue)
                            Text("Mikroçip: \(pet.microchipID)")
                                .font(.caption.weight(.semibold))
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    // Reward
                    if !reward.isEmpty {
                        Text("💰 ÖDÜL: \(reward) TL")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.green)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    // Contact
                    VStack(spacing: 8) {
                        Text("📞 İLETİŞİM")
                            .font(.headline)
                        if !contactName.isEmpty {
                            Text(contactName)
                                .font(.subheadline)
                        }
                        Text(contactPhone)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))

                    // QR Code
                    VStack(spacing: 4) {
                        qrCodeImage(for: generateContactQR())
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        Text("QR ile iletişim bilgisi")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .background(.white)
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Kayıp Poster")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: generateShareText()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private func infoPill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
    }

    private func generateContactQR() -> String {
        "KAYIP: \(pet.name)\nİletişim: \(contactName) \(contactPhone)"
    }

    private func generateShareText() -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateFormat = "d MMMM yyyy, HH:mm"

        var text = "🚨 KAYIP HAYVAN 🚨\n\n"
        text += "🐾 Ad: \(pet.name)\n"
        text += "📋 Tür/Irk: \(pet.species.rawValue) / \(pet.breed)\n"
        text += "📅 Yaş: \(pet.age)\n"
        if !pet.microchipID.isEmpty { text += "📡 Mikroçip: \(pet.microchipID)\n" }
        text += "\n📍 Son Görülen: \(lastSeenLocation)\n"
        text += "🕐 Tarih: \(df.string(from: lastSeenDate))\n"
        if !additionalNotes.isEmpty { text += "\n📝 \(additionalNotes)\n" }
        if !reward.isEmpty { text += "\n💰 Ödül: \(reward) TL\n" }
        text += "\n📞 İletişim: \(contactName) \(contactPhone)\n"
        text += "\nLütfen gördüyseniz haber verin! 🙏"
        return text
    }

    private func qrCodeImage(for string: String) -> Image {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return Image(uiImage: UIImage(cgImage: cgImage))
        }
        return Image(systemName: "qrcode")
    }
}
