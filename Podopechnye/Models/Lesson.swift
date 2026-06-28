import Foundation
import SwiftData

@Model
final class Lesson {
    var id: UUID
    var date: Date            // полная дата и время занятия
    var kindRaw: String
    var statusRaw: String
    var charged: Bool         // для отменённых: списано ли занятие (поздняя отмена)
    var note: String?         // свободная заметка к занятию
    var program: [Exercise]   // структурированная программа (может быть пустой)
    var eventId: String?      // id связанного EKEvent в Календаре айфона

    var client: Client?

    init(
        id: UUID = UUID(),
        date: Date,
        kind: LessonKind = .package,
        status: LessonStatus = .planned,
        charged: Bool = false,
        note: String? = nil,
        program: [Exercise] = [],
        eventId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.kindRaw = kind.rawValue
        self.statusRaw = status.rawValue
        self.charged = charged
        self.note = note
        self.program = program
        self.eventId = eventId
    }
}

extension Lesson {
    var kind: LessonKind {
        get { LessonKind(rawValue: kindRaw) ?? .package }
        set { kindRaw = newValue.rawValue }
    }

    var status: LessonStatus {
        get { LessonStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    /// «HH:MM» для отображения в расписании.
    var timeText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    var hasProgram: Bool { !program.isEmpty }
}
