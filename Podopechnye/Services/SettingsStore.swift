import SwiftUI

// Глобальные настройки приложения. Скаляры — в @AppStorage, выходные — как множество
// конкретных дат «yyyy-MM-dd» (плавающие, привязаны к неделе; DEV_BRIEF §6.7).
@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("yellowThreshold") var yellowThreshold: Int = 3
    @AppStorage("lateCancelHours") var lateCancelHours: Int = 8
    @AppStorage("defaultPackageCount") var defaultPackageCount: Int = 10
    @AppStorage("appearance") var appearanceRaw: Int = 0   // 0 система · 1 светлая · 2 тёмная
    @AppStorage("daysOffData") private var daysOffData: Data = Data()

    var colorScheme: ColorScheme? {
        switch appearanceRaw {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    @Published private var daysOffCache: Set<String> = []

    init() {
        daysOffCache = decodeDaysOff()
        // По умолчанию ближайшее воскресенье выходной, если ещё ничего не задано.
        if daysOffCache.isEmpty {
            if let sunday = Self.nextSunday() {
                daysOffCache = [Self.key(sunday)]
                persist()
            }
        }
    }

    // MARK: Выходные
    static func key(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.startOfDay(for: date))
    }

    func isDayOff(_ date: Date) -> Bool {
        daysOffCache.contains(Self.key(date))
    }

    func toggleDayOff(_ date: Date) {
        let k = Self.key(date)
        if daysOffCache.contains(k) { daysOffCache.remove(k) } else { daysOffCache.insert(k) }
        persist()
    }

    private func decodeDaysOff() -> Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: daysOffData)) ?? []
    }

    private func persist() {
        daysOffData = (try? JSONEncoder().encode(daysOffCache)) ?? Data()
    }

    private static func nextSunday() -> Date? {
        let cal = Calendar.current
        // Если сегодня воскресенье — «ближайшее» это сегодня, а не через неделю.
        if cal.component(.weekday, from: Date()) == 1 {
            return cal.startOfDay(for: Date())
        }
        return cal.nextDate(after: Date(), matching: DateComponents(weekday: 1),
                            matchingPolicy: .nextTime)
    }
}
