import SwiftUI

struct QuickLogPanel: View {
    let pet: Pet
    let store: PetStore
    
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hızlı Kayıt")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickLogItems, id: \.label) { item in
                        QuickLogButton(
                            icon: item.icon,
                            label: item.label,
                            color: item.color
                        ) {
                            performQuickLog(item)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .overlay(alignment: .top) {
            if showToast {
                quickToast
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
    }
    
    // MARK: - Species-Aware Quick Log Items
    
    private var quickLogItems: [QuickLogItem] {
        switch pet.species {
        case .dog:
            return [
                QuickLogItem(icon: "fork.knife", label: "Mama verdim", color: .orange, action: .feeding(.breakfast)),
                QuickLogItem(icon: "figure.walk", label: "Yürüdük", color: .blue, action: .activity(.walk)),
                QuickLogItem(icon: "leaf.fill", label: "Tuvalet", color: .green, action: .activity(.potty)),
                QuickLogItem(icon: "drop.fill", label: "Su verdim", color: .cyan, action: .water)
            ]
        case .cat:
            return [
                QuickLogItem(icon: "fork.knife", label: "Mama verdim", color: .orange, action: .feeding(.breakfast)),
                QuickLogItem(icon: "tennisball.fill", label: "Oynadık", color: .pink, action: .activity(.play)),
                QuickLogItem(icon: "leaf.fill", label: "Kum değiştim", color: .green, action: .activity(.grooming)),
                QuickLogItem(icon: "drop.fill", label: "Su verdim", color: .cyan, action: .water)
            ]
        case .fish:
            return [
                QuickLogItem(icon: "fork.knife", label: "Besin verdim", color: .orange, action: .feeding(.breakfast)),
                QuickLogItem(icon: "drop.fill", label: "Su değiştirdim", color: .blue, action: .activity(.other)),
                QuickLogItem(icon: "thermometer.medium", label: "Su testi", color: .teal, action: .activity(.other))
            ]
        case .bird:
            return [
                QuickLogItem(icon: "fork.knife", label: "Besin verdim", color: .orange, action: .feeding(.breakfast)),
                QuickLogItem(icon: "bird.fill", label: "Uçurduk", color: .blue, action: .activity(.play)),
                QuickLogItem(icon: "trash.fill", label: "Kafes temizledim", color: .green, action: .activity(.grooming))
            ]
        case .rabbit:
            return [
                QuickLogItem(icon: "fork.knife", label: "Mama verdim", color: .orange, action: .feeding(.breakfast)),
                QuickLogItem(icon: "leaf.fill", label: "Saman koydum", color: .green, action: .activity(.other)),
                QuickLogItem(icon: "tennisball.fill", label: "Oynadık", color: .pink, action: .activity(.play))
            ]
        case .reptile:
            return [
                QuickLogItem(icon: "fork.knife", label: "Besin verdim", color: .orange, action: .feeding(.breakfast)),
                QuickLogItem(icon: "sun.max.fill", label: "UVB kontrol", color: .yellow, action: .activity(.other)),
                QuickLogItem(icon: "humidity.fill", label: "Nem kontrol", color: .teal, action: .activity(.other))
            ]
        default:
            return [
                QuickLogItem(icon: "fork.knife", label: "Mama verdim", color: .orange, action: .feeding(.breakfast)),
                QuickLogItem(icon: "drop.fill", label: "Su verdim", color: .cyan, action: .water),
                QuickLogItem(icon: "tennisball.fill", label: "Oynadık", color: .pink, action: .activity(.play))
            ]
        }
    }
    
    // MARK: - Quick Log Action
    
    private func performQuickLog(_ item: QuickLogItem) {
        switch item.action {
        case .feeding(let mealType):
            store.addFeedingLog(to: pet, mealType: mealType, portionGrams: 0, foodBrand: "", notes: "Hızlı kayıt", date: Date())
            showQuickToast(icon: item.icon, message: "\(item.label) kaydedildi")
            
        case .water:
            store.addFeedingLog(to: pet, mealType: .water, portionGrams: 0, foodBrand: "", notes: "Hızlı kayıt", date: Date())
            showQuickToast(icon: item.icon, message: "Su kaydedildi")
            
        case .activity(let activityType):
            store.addActivityLog(to: pet, activityType: activityType, durationMinutes: 0, notes: "Hızlı kayıt", date: Date())
            showQuickToast(icon: item.icon, message: "\(item.label) kaydedildi")
        }
    }
    
    private func showQuickToast(icon: String, message: String) {
        toastIcon = icon
        toastMessage = message
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showToast = false
            }
        }
    }
    
    // MARK: - Toast
    
    private var quickToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(toastMessage)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.top, -8)
    }
}

// MARK: - Quick Log Item Model

struct QuickLogItem {
    let icon: String
    let label: String
    let color: Color
    let action: QuickLogAction
    
    enum QuickLogAction {
        case feeding(MealType)
        case water
        case activity(ActivityType)
    }
}

// MARK: - Quick Log Button

struct QuickLogButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(width: 72)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(QuickLogButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct QuickLogButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
