import SwiftUI

// Цветная точка-семафор остатка.
struct SemaphoreDot: View {
    let state: SemaphoreState
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(state.color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// Аватар с инициалами клиента.
struct InitialsAvatar: View {
    let initials: String
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Color.appAccent.opacity(0.12))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            )
    }
}

// Плавающая кнопка добавления (FAB).
struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.appAccent, in: Circle())
                .shadow(color: Color.appAccent.opacity(0.4), radius: 8, y: 4)
        }
        .padding(20)
    }
}

// Бейдж статуса клиента / типа занятия.
struct StatusBadge: View {
    let text: String
    var fg: Color = Color(hex: 0xC2691C)
    var bg: Color = Color(hex: 0xFFF1E0)

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg, in: Capsule())
    }
}
