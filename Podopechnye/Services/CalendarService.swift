import Foundation
import EventKit

// Односторонняя интеграция с Календарём айфона (DEV_BRIEF §8):
// приложение пишет занятия в отдельный календарь «Тренировки» и проверяет конфликты.
@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    private let store = EKEventStore()
    private let calendarTitle = "Тренировки"
    @Published private(set) var granted = false

    /// Длительность занятия по умолчанию.
    private let defaultDuration: TimeInterval = 60 * 60

    private init() {
        refreshAccess()
    }

    func refreshAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        granted = (status == .fullAccess)
    }

    /// Запрос полного доступа к Календарю (после pre-permission экрана).
    func requestAccess() async -> Bool {
        do {
            let ok = try await store.requestFullAccessToEvents()
            granted = ok
            return ok
        } catch {
            granted = false
            return false
        }
    }

    // MARK: - Календарь «Тренировки»
    private func trainingCalendar() -> EKCalendar? {
        if let existing = store.calendars(for: .event).first(where: { $0.title == calendarTitle }) {
            return existing
        }
        guard let source = store.defaultCalendarForNewEvents?.source ?? store.sources.first else {
            return nil
        }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = calendarTitle
        cal.source = source
        cal.cgColor = AppColors.accentCG
        try? store.saveCalendar(cal, commit: true)
        return cal
    }

    // MARK: - Создание / обновление события
    /// Создаёт или обновляет EKEvent для занятия. Возвращает eventId.
    @discardableResult
    func upsert(title: String, start: Date, existingEventId: String?) -> String? {
        guard granted, let calendar = trainingCalendar() else { return existingEventId }

        let event: EKEvent
        if let id = existingEventId, let found = store.event(withIdentifier: id) {
            event = found
        } else {
            event = EKEvent(eventStore: store)
        }
        event.title = title
        event.startDate = start
        event.endDate = start.addingTimeInterval(defaultDuration)
        event.calendar = calendar

        do {
            try store.save(event, span: .thisEvent, commit: true)
            return event.eventIdentifier
        } catch {
            return existingEventId
        }
    }

    func remove(eventId: String?) {
        guard granted, let id = eventId, let event = store.event(withIdentifier: id) else { return }
        try? store.remove(event, span: .thisEvent, commit: true)
    }

    // MARK: - Проверка конфликтов в личном Календаре (DEV_BRIEF §6.6)
    /// Названия событий личного Календаря, пересекающихся со слотом.
    func conflictTitles(start: Date, durationOverride: TimeInterval? = nil) -> [String] {
        guard granted else { return [] }
        let end = start.addingTimeInterval(durationOverride ?? defaultDuration)
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
            .filter { $0.calendar.title != calendarTitle }   // не считаем свои же тренировки
            .map { $0.title ?? "Событие" }
    }
}
