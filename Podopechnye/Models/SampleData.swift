import Foundation
import SwiftData

// Демо-данные, повторяющие кликабельный прототип, чтобы приложение было «живым»
// при первом запуске на симуляторе. Засеваются один раз.
enum SampleData {
    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Client>())) ?? 0
        guard count == 0 else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func at(_ hour: Int, _ minute: Int) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
        }

        // Анна Ковалёва — 3/10
        let anna = Client(name: "Анна Ковалёва", phone: "+7 900 000-00-01", tg: "anna", status: .active,
                          notes: "Бережно с поясницей — без осевой. Взять резинку.")
        anna.package = Package(kind: .package, total: 10, used: 7, price: "8 000 ₽", date: today)
        anna.lessons = [Lesson(date: at(9, 0),
            note: "Бережно с поясницей — без осевой. Взять резинку.",
            program: [
                Exercise(ex: "Присед в тренажёре", weight: "55", scheme: "4×12"),
                Exercise(ex: "Жим гантелей", weight: "14", scheme: "3×12"),
                Exercise(ex: "Тяга верх. блока", weight: "40", scheme: "4×12"),
                Exercise(ex: "Планка", weight: "", scheme: "3×40с")
            ])]
        anna.payments = [Payment(date: today, type: "Пакет 10 занятий", sum: "8 000 ₽")]

        // Дмитрий Орлов — 4/10
        let dmitry = Client(name: "Дмитрий Орлов", phone: "+7 900 000-00-02", status: .active)
        dmitry.package = Package(kind: .package, total: 10, used: 6, price: "8 000 ₽", date: today)
        dmitry.lessons = [Lesson(date: at(11, 0))]

        // Игорь Лебедев — пробное 1/1
        let igor = Client(name: "Игорь Лебедев", tg: "igor", status: .trial)
        igor.package = Package(kind: .trial, total: 1, used: 0, price: "0 ₽", date: today)
        igor.lessons = [Lesson(date: at(14, 30), kind: .trial)]

        // Марина Соколова — пакет закончился (0/10)
        let marina = Client(name: "Марина Соколова", phone: "+7 900 000-00-03", status: .active,
                            notes: "Пакет на нуле — напомнить про оплату.")
        marina.package = Package(kind: .package, total: 10, used: 10, price: "8 000 ₽", date: today)
        marina.lessons = [Lesson(date: at(18, 0))]

        // Елена Морозова — 2/10
        let elena = Client(name: "Елена Морозова", phone: "+7 900 000-00-04", status: .active)
        elena.package = Package(kind: .package, total: 10, used: 8, price: "8 000 ₽", date: today)
        elena.lessons = [Lesson(date: at(19, 30))]

        for client in [anna, dmitry, igor, marina, elena] {
            context.insert(client)
        }
        try? context.save()
    }
}
