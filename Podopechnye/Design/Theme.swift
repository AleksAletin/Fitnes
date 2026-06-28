import SwiftUI
import UIKit

// Дизайн-токены из DEV_BRIEF §9. Один акцент + семафор только для остатка.
// Базовые токены — семантические системные цвета, поэтому тёмная тема адаптируется сама.
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
    static let appAccent = Color(hex: 0x5856D6)   // фиолетовый акцент (один в обеих темах)

    // Адаптивные поверхности и текст
    static let appBackground = Color(uiColor: .systemGroupedBackground)
    static let appCard = Color(uiColor: .secondarySystemGroupedBackground)
    static let appText = Color(uiColor: .label)
    static let appSecondary = Color(uiColor: .secondaryLabel)

    // Семафор остатка (только для сигнала остатка занятий — одинаков в обеих темах)
    static let semGreen = Color(hex: 0x34C759)
    static let semYellow = Color(hex: 0xFF9F0A)
    static let semRed = Color(hex: 0xFF3B30)
    static let semNone = Color(uiColor: .systemGray3)
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
