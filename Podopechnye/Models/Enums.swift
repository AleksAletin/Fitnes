import Foundation

// MARK: - Статус клиента
enum ClientStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case trial
    case new
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active:   return "Активный"
        case .trial:    return "Пробный"
        case .new:      return "Новый"
        case .archived: return "Архив"
        }
    }
}

// MARK: - Тип пакета
// Тренер берёт по-разному: пакет на N занятий, разовое, пробное, абонемент на период.
enum PackageKind: String, Codable, CaseIterable, Identifiable {
    case package   // пакет на N занятий
    case single    // разовое
    case trial     // пробное
    case period    // абонемент на период

    var id: String { rawValue }

    var title: String {
        switch self {
        case .package: return "Пакет"
        case .single:  return "Разовое"
        case .trial:   return "Пробное"
        case .period:  return "Абонемент"
        }
    }
}

// MARK: - Тип занятия
enum LessonKind: String, Codable {
    case package
    case trial
    case single

    /// Бейдж рядом с именем (nil для обычного пакетного занятия — бейдж не нужен).
    var badge: String? {
        switch self {
        case .package: return nil
        case .trial:   return "Пробное"
        case .single:  return "Разовое"
        }
    }
}

// MARK: - Статус занятия
enum LessonStatus: String, Codable {
    case planned
    case done
    case cancelled
}

// MARK: - Семафор остатка занятий
// Главный сигнал во всём приложении: сколько занятий осталось и пора ли брать оплату.
enum SemaphoreState {
    case none    // нет пакета — серый
    case red     // 0 или долг — пора брать деньги
    case yellow  // мало (<= порога) — скоро напомнить
    case green   // достаточно

    /// Логика из DEV_BRIEF §6.1.
    static func from(remaining: Int?, yellowThreshold: Int) -> SemaphoreState {
        guard let remaining else { return .none }
        if remaining <= 0 { return .red }
        if remaining <= yellowThreshold { return .yellow }
        return .green
    }
}
