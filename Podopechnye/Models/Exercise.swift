import Foundation

// Строка программы занятия: упражнение · рабочий вес · схема подходов («4×12»).
// Хранится как Codable-значение внутри Lesson (SwiftData умеет хранить массивы Codable).
struct Exercise: Codable, Hashable, Identifiable {
    var id: UUID
    var ex: String        // упражнение
    var weight: String    // рабочий вес, кг
    var scheme: String    // схема подходов, напр. «4×12»

    init(id: UUID = UUID(), ex: String = "", weight: String = "", scheme: String = "") {
        self.id = id
        self.ex = ex
        self.weight = weight
        self.scheme = scheme
    }
}
