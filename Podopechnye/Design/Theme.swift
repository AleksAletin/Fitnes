import SwiftUI

// Дизайн-токены из DEV_BRIEF §9. Один акцент + семафор только для остатка.
extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    // Бренд
    static let appAccent = Color(hex: 0x5856D6)   // фиолетовый акцент
    static let appBackground = Color(hex: 0xF2F2F7)
    static let appCard = Color.white
    static let appText = Color(hex: 0x1C1C1E)
    static let appSecondary = Color(hex: 0x8E8E93)

    // Семафор остатка (только для сигнала остатка занятий)
    static let semGreen = Color(hex: 0x34C759)
    static let semYellow = Color(hex: 0xFF9F0A)
    static let semRed = Color(hex: 0xFF3B30)
    static let semNone = Color(hex: 0xC7C7CC)
}

// Платформенные значения цвета (для EventKit и т.п., где нужен CGColor).
enum AppColors {
    static let accentCG = CGColor(red: 0x58 / 255, green: 0x56 / 255, blue: 0xD6 / 255, alpha: 1)
}

extension SemaphoreState {
    var color: Color {
        switch self {
        case .none:   return .semNone
        case .red:    return .semRed
        case .yellow: return .semYellow
        case .green:  return .semGreen
        }
    }
}
