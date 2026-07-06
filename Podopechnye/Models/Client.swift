import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID
    var name: String
    var phone: String?
    var tg: String?               // Telegram @username
    var statusRaw: String
    var prevStatusRaw: String?    // сохраняется при архивировании для возврата
    var notes: String?            // цель, травмы, предпочтения
    var createdAt: Date

    // Текущий пакет (может отсутствовать). Каскадное удаление вместе с клиентом.
    @Relationship(deleteRule: .cascade, inverse: \Package.client)
    var package: Package?

    @Relationship(deleteRule: .cascade, inverse: \Lesson.client)
    var lessons: [Lesson] = []

    @Relationship(deleteRule: .cascade, inverse: \Payment.client)
    var payments: [Payment] = []

    init(
        id: UUID = UUID(),
        name: String,
        phone: String? = nil,
        tg: String? = nil,
        status: ClientStatus = .active,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.tg = tg
        self.statusRaw = status.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Удобные вычисляемые свойства
extension Client {
    var status: ClientStatus {
        get { ClientStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var prevStatus: ClientStatus? {
        get { prevStatusRaw.flatMap(ClientStatus.init(rawValue:)) }
        set { prevStatusRaw = newValue?.rawValue }
    }

    /// Остаток занятий по текущему пакету. nil — пакета нет. Может быть отрицательным (долг).
    var remaining: Int? {
        guard let package else { return nil }
        return package.total - package.used
    }

    /// Долг = занятий проведено больше, чем оплачено.
    var debt: Int {
        guard let remaining, remaining < 0 else { return 0 }
        return -remaining
    }

    func semaphore(yellowThreshold: Int) -> SemaphoreState {
        SemaphoreState.from(remaining: remaining, yellowThreshold: yellowThreshold)
    }

    /// Единый текст остатка для списков: «долг N» / «осталось X из Y» /
    /// «Пакет закончился» / «Без пакета». Один источник — правится в одном месте.
    var remainingText: String {
        if debt > 0 { return "долг \(debt)" }
        guard let package else { return "Без пакета" }
        if package.remaining <= 0 { return "Пакет закончился" }
        return "осталось \(package.remaining) из \(package.total)"
    }

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    // MARK: Архив / возврат (DEV_BRIEF §6.9)
    func archive() {
        guard status != .archived else { return }
        prevStatus = status
        status = .archived
    }

    func unarchive() {
        status = prevStatus ?? .active
        prevStatus = nil
    }
}
