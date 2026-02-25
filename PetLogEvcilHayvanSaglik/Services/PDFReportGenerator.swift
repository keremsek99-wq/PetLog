import UIKit
import SwiftUI

@MainActor
class PDFReportGenerator {

    static func generateReport(for pet: Pet, store: PetStore) -> Data? {
        let pageWidth: CGFloat = 595.0  // A4
        let pageHeight: CGFloat = 842.0
        let margin: CGFloat = 40.0
        let contentWidth = pageWidth - (margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()
            var yOffset: CGFloat = margin

            // Title
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let titleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.label]
            let title = "🐾 \(pet.name) — Sağlık Raporu"
            title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttr)
            yOffset += 36

            // Date
            let dateFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let dateAttr: [NSAttributedString.Key: Any] = [.font: dateFont, .foregroundColor: UIColor.secondaryLabel]
            let dateStr = "Oluşturulma: \(Date().formatted(date: .long, time: .shortened))"
            dateStr.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: dateAttr)
            yOffset += 30

            // Divider
            yOffset = drawDivider(context: context.cgContext, y: yOffset, width: contentWidth, margin: margin)
            yOffset += 10

            // Pet Info
            yOffset = drawSection(title: "Genel Bilgiler", y: yOffset, margin: margin, contentWidth: contentWidth, in: context)
            yOffset = drawKeyValue("Tür", value: pet.species.rawValue, y: yOffset, margin: margin)
            if !pet.breed.isEmpty {
                yOffset = drawKeyValue("Irk", value: pet.breed, y: yOffset, margin: margin)
            }
            yOffset = drawKeyValue("Yaş", value: pet.age, y: yOffset, margin: margin)
            if pet.sex != .unknown {
                yOffset = drawKeyValue("Cinsiyet", value: pet.sex.rawValue, y: yOffset, margin: margin)
            }
            yOffset += 10

            // Weight
            let sortedWeights = pet.weightLogs.sorted { $0.date > $1.date }
            if !sortedWeights.isEmpty {
                yOffset = drawDivider(context: context.cgContext, y: yOffset, width: contentWidth, margin: margin)
                yOffset += 10
                yOffset = drawSection(title: "Kilo Takibi", y: yOffset, margin: margin, contentWidth: contentWidth, in: context)
                yOffset = drawKeyValue("Son Kilo", value: String(format: "%.1f kg", sortedWeights[0].weightKg), y: yOffset, margin: margin)
                yOffset = drawKeyValue("Kayıt Tarihi", value: sortedWeights[0].date.formatted(date: .abbreviated, time: .omitted), y: yOffset, margin: margin)
                if sortedWeights.count >= 2 {
                    let diff = sortedWeights[0].weightKg - sortedWeights[1].weightKg
                    yOffset = drawKeyValue("Değişim", value: String(format: "%+.1f kg", diff), y: yOffset, margin: margin)
                }
                let minW = sortedWeights.map(\.weightKg).min() ?? 0
                let maxW = sortedWeights.map(\.weightKg).max() ?? 0
                yOffset = drawKeyValue("Aralık", value: String(format: "%.1f – %.1f kg", minW, maxW), y: yOffset, margin: margin)
                yOffset += 10
            }

            // Vaccines
            let vaccines = pet.vaccineRecords.sorted { $0.dateAdministered > $1.dateAdministered }
            if !vaccines.isEmpty {
                yOffset = drawDivider(context: context.cgContext, y: yOffset, width: contentWidth, margin: margin)
                yOffset += 10
                yOffset = drawSection(title: "Aşılar", y: yOffset, margin: margin, contentWidth: contentWidth, in: context)
                for vaccine in vaccines.prefix(10) {
                    let dateStr = vaccine.dateAdministered.formatted(date: .abbreviated, time: .omitted)
                    let nextStr = vaccine.dueDate.map { " → Sonraki: \($0.formatted(date: .abbreviated, time: .omitted))" } ?? ""
                    yOffset = drawBullet("• \(vaccine.name) — \(dateStr)\(nextStr)", y: yOffset, margin: margin, contentWidth: contentWidth)

                    if yOffset > pageHeight - margin - 40 {
                        context.beginPage()
                        yOffset = margin
                    }
                }
                yOffset += 10
            }

            // Medications
            let meds = pet.activeMedications
            if !meds.isEmpty {
                if yOffset > pageHeight - 120 {
                    context.beginPage()
                    yOffset = margin
                }
                yOffset = drawDivider(context: context.cgContext, y: yOffset, width: contentWidth, margin: margin)
                yOffset += 10
                yOffset = drawSection(title: "Aktif İlaçlar", y: yOffset, margin: margin, contentWidth: contentWidth, in: context)
                for med in meds {
                    yOffset = drawBullet("• \(med.name) — \(med.dosage) (\(med.schedule.rawValue))", y: yOffset, margin: margin, contentWidth: contentWidth)
                }
                yOffset += 10
            }

            // Expenses Summary
            let expenses = pet.expenses
            if !expenses.isEmpty {
                if yOffset > pageHeight - 120 {
                    context.beginPage()
                    yOffset = margin
                }
                yOffset = drawDivider(context: context.cgContext, y: yOffset, width: contentWidth, margin: margin)
                yOffset += 10
                yOffset = drawSection(title: "Harcama Özeti", y: yOffset, margin: margin, contentWidth: contentWidth, in: context)
                let total = expenses.reduce(0) { $0 + $1.amount }
                let monthlyAvg = store.monthlySpending(for: pet)
                yOffset = drawKeyValue("Toplam Harcama", value: String(format: "₺%.0f", total), y: yOffset, margin: margin)
                yOffset = drawKeyValue("Aylık Ortalama", value: String(format: "₺%.0f", monthlyAvg), y: yOffset, margin: margin)
                yOffset += 10
            }

            // Vet Visits
            let vetVisits = pet.vetVisits.sorted { $0.date > $1.date }
            if !vetVisits.isEmpty {
                if yOffset > pageHeight - 120 {
                    context.beginPage()
                    yOffset = margin
                }
                yOffset = drawDivider(context: context.cgContext, y: yOffset, width: contentWidth, margin: margin)
                yOffset += 10
                yOffset = drawSection(title: "Veteriner Ziyaretleri", y: yOffset, margin: margin, contentWidth: contentWidth, in: context)
                for visit in vetVisits.prefix(10) {
                    let dateStr = visit.date.formatted(date: .abbreviated, time: .omitted)
                    let costStr = visit.cost > 0 ? " — ₺\(String(format: "%.0f", visit.cost))" : ""
                    yOffset = drawBullet("• \(visit.reason) — \(dateStr)\(costStr)", y: yOffset, margin: margin, contentWidth: contentWidth)
                    if !visit.diagnosis.isEmpty {
                        yOffset = drawBullet("  Tanı: \(visit.diagnosis)", y: yOffset, margin: margin, contentWidth: contentWidth)
                    }
                    if yOffset > pageHeight - margin - 40 {
                        context.beginPage()
                        yOffset = margin
                    }
                }
                yOffset += 10
            }

            // Behavior Summary
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recentBehaviors = pet.behaviorLogs.filter { $0.date >= thirtyDaysAgo }
            if !recentBehaviors.isEmpty {
                if yOffset > pageHeight - 120 {
                    context.beginPage()
                    yOffset = margin
                }
                yOffset = drawDivider(context: context.cgContext, y: yOffset, width: contentWidth, margin: margin)
                yOffset += 10
                yOffset = drawSection(title: "Davranış Özeti (Son 30 Gün)", y: yOffset, margin: margin, contentWidth: contentWidth, in: context)
                var counts: [String: Int] = [:]
                for log in recentBehaviors { counts[log.behaviorType.rawValue, default: 0] += 1 }
                for (type, count) in counts.sorted(by: { $0.value > $1.value }).prefix(8) {
                    yOffset = drawBullet("• \(type): \(count)x", y: yOffset, margin: margin, contentWidth: contentWidth)
                }
                yOffset += 10
            }

            // Footer
            if yOffset > pageHeight - 60 {
                context.beginPage()
                yOffset = margin
            }
            yOffset = drawDivider(context: context.cgContext, y: yOffset, width: contentWidth, margin: margin)
            yOffset += 10
            let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            let footerAttr: [NSAttributedString.Key: Any] = [.font: footerFont, .foregroundColor: UIColor.tertiaryLabel]
            "PetLog tarafından oluşturuldu. Bu rapor veteriner tavsiyesi yerine geçmez.".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: footerAttr)
        }
    }

    // MARK: - Drawing Helpers

    private static func drawSection(title: String, y: CGFloat, margin: CGFloat, contentWidth: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: attr)
        return y + 28
    }

    private static func drawKeyValue(_ key: String, value: String, y: CGFloat, margin: CGFloat) -> CGFloat {
        let keyFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        let valFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        let keyAttr: [NSAttributedString.Key: Any] = [.font: keyFont, .foregroundColor: UIColor.secondaryLabel]
        let valAttr: [NSAttributedString.Key: Any] = [.font: valFont, .foregroundColor: UIColor.label]
        key.draw(at: CGPoint(x: margin + 8, y: y), withAttributes: keyAttr)
        value.draw(at: CGPoint(x: margin + 160, y: y), withAttributes: valAttr)
        return y + 22
    }

    private static func drawBullet(_ text: String, y: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 12, weight: .regular)
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
        let rect = CGRect(x: margin + 8, y: y, width: contentWidth - 16, height: 40)
        text.draw(with: rect, options: [.usesLineFragmentOrigin], attributes: attr, context: nil)
        let size = (text as NSString).boundingRect(with: CGSize(width: contentWidth - 16, height: .infinity), options: .usesLineFragmentOrigin, attributes: attr, context: nil)
        return y + size.height + 4
    }

    private static func drawDivider(context: CGContext, y: CGFloat, width: CGFloat, margin: CGFloat) -> CGFloat {
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: margin + width, y: y))
        context.strokePath()
        return y + 2
    }
}
