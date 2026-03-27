import SwiftUI

struct WeightLogRow: View {
    let log: WeightLog
    let onDelete: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.1f kg", log.weightKg))
                    .font(.headline)
                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert)
        .alert("Bu kaydı silmek istiyor musunuz?", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive, action: onDelete)
        }
    }
}

struct VaccineRow: View {
    let record: VaccineRecord
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "syringe.fill")
                        .font(.subheadline)
                        .foregroundStyle(statusColor)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(record.name)
                    .font(.headline)
                Text("Yapıldı: \(record.dateAdministered.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let dueDate = record.dueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(record.isOverdue ? "Gecikmiş" : (record.isDueSoon ? "Yakında" : "Planlandı"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(statusColor)
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Sil", systemImage: "trash")
            }
        }
        .contextMenu {
            Button("Sil", role: .destructive, action: onDelete)
        }
    }

    private var statusColor: Color {
        if record.isOverdue { return .red }
        if record.isDueSoon { return .orange }
        return .green
    }
}

struct MedicationRow: View {
    let medication: Medication
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(medication.isActive ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "pills.fill")
                        .font(.subheadline)
                        .foregroundStyle(medication.isActive ? .blue : .gray)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.headline)
                if !medication.dosage.isEmpty {
                    Text(medication.dosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(medication.schedule.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(medication.isActive ? .blue : .secondary)
                if medication.isActive {
                    Text("Aktif")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Sil", systemImage: "trash")
            }
        }
        .contextMenu {
            Button("Sil", role: .destructive, action: onDelete)
        }
    }
}

struct VetVisitRow: View {
    let visit: VetVisit
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.red.opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "cross.case.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.reason)
                    .font(.headline)
                Text(visit.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if visit.cost > 0 {
                Text(visit.cost.formatted(.currency(code: "TRY")))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Sil", systemImage: "trash")
            }
        }
        .contextMenu {
            Button("Sil", role: .destructive, action: onDelete)
        }
    }
}
