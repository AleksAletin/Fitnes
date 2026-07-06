import Foundation
import SwiftData

// Бизнес-действия над занятием: списание, долг, отмена и их откаты.
// Вынесены из вью, чтобы логика пакетов была тестируемой (см. PodopechnyeTests).
@MainActor
enum LessonActions {

    /// Отметить занятие проведённым и списать из пакета.
    /// Если пакета нет вообще — создаёт нулевой «Занятия в долг», остаток уходит в минус.
    /// Возвращает замыкание отката (для тоста «Отменить»).
    static func markDone(_ lesson: Lesson, context: ModelContext) -> () -> Void {
        lesson.status = .done

        var createdDebtPackage = false
        if let client = lesson.client, client.package == nil {
            let debt = Package(kind: .package, total: 0, used: 0, price: "", date: Date())
            client.package = debt
            context.insert(debt)
            createdDebtPackage = true
        }
        lesson.client?.package?.used += 1

        return {
            lesson.status = .planned
            guard let pkg = lesson.client?.package else { return }
            pkg.used -= 1
            // Авто-созданный пакет-долг убираем, если он снова пуст.
            if createdDebtPackage && pkg.total == 0 && pkg.used <= 0 {
                lesson.client?.package = nil
                context.delete(pkg)
            }
        }
    }

    /// Отменить занятие. `charge` — поздняя отмена со списанием из пакета.
    /// Удаляет событие из Календаря; откат возвращает и списание, и событие.
    static func cancel(_ lesson: Lesson, charge: Bool) -> () -> Void {
        let clientName = lesson.client?.name ?? ""
        let date = lesson.date

        lesson.status = .cancelled
        lesson.charged = charge
        if charge { lesson.client?.package?.used += 1 }
        CalendarService.shared.remove(eventId: lesson.eventId)
        lesson.eventId = nil

        return {
            lesson.status = .planned
            if charge { lesson.client?.package?.used -= 1 }
            lesson.charged = false
            lesson.eventId = CalendarService.shared.upsert(
                title: "Тренировка · \(clientName)", start: date, existingEventId: nil)
        }
    }

    /// Рекомендовать списание при отмене: до занятия меньше окна поздней отмены.
    static func recommendCharge(_ lesson: Lesson, lateCancelHours: Int, now: Date = Date()) -> Bool {
        lesson.date.timeIntervalSince(now) / 3600 < Double(lateCancelHours)
    }
}
