import Foundation
import SwiftData

// История оплат клиента — основа учёта денег в V1.
@Model
final class Payment {
    var id: UUID
    var date: Date
    var type: String      // что оплачено, напр. «Пакет 10 занятий»
    var sum: String       // сумма, напр. «8 000 ₽»

    var client: Client?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: String,
        sum: String
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.sum = sum
    }
}
