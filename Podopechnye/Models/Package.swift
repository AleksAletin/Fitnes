import Foundation
import SwiftData

@Model
final class Package {
    var kindRaw: String
    var total: Int        // оплачено занятий (для single/trial = 1)
    var used: Int         // проведено (может превысить total → долг)
    var price: String     // напр. «8 000 ₽»
    var date: Date        // дата оплаты

    var client: Client?

    init(
        kind: PackageKind = .package,
        total: Int,
        used: Int = 0,
        price: String = "",
        date: Date = Date()
    ) {
        self.kindRaw = kind.rawValue
        self.total = total
        self.used = used
        self.price = price
        self.date = date
    }
}

extension Package {
    var kind: PackageKind {
        get { PackageKind(rawValue: kindRaw) ?? .package }
        set { kindRaw = newValue.rawValue }
    }

    /// Остаток = оплачено − проведено. Отрицательное значение — долг.
    var remaining: Int { total - used }

    /// Заголовок пакета для UI, напр. «Пакет 10 занятий» / «Пробное».
    var title: String {
        switch kind {
        case .package: return total == 0 ? "Занятия в долг" : "Пакет \(total) занятий"
        case .period:  return "Абонемент"
        case .single:  return "Разовое"
        case .trial:   return "Пробное"
        }
    }
}
