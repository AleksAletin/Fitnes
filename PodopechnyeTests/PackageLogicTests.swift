import XCTest
import SwiftData
@testable import Podopechnye

// Тесты бизнес-логики пакетов: списание, долг, отмена, откаты, семафор.
@MainActor
final class PackageLogicTests: XCTestCase {

    private var context: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Client.self, Package.self, Lesson.self, Payment.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    private func makeClient(packageTotal: Int?, used: Int = 0) -> Client {
        let client = Client(name: "Тест")
        context.insert(client)
        if let total = packageTotal {
            let pkg = Package(kind: .package, total: total, used: used)
            client.package = pkg
            context.insert(pkg)
        }
        return client
    }

    private func makeLesson(for client: Client) -> Lesson {
        let lesson = Lesson(date: Date())
        lesson.client = client
        context.insert(lesson)
        return lesson
    }

    // MARK: Проведение занятия

    func testMarkDoneChargesPackage() {
        let client = makeClient(packageTotal: 10, used: 3)
        let lesson = makeLesson(for: client)

        _ = LessonActions.markDone(lesson, context: context)

        XCTAssertEqual(lesson.status, .done)
        XCTAssertEqual(client.package?.used, 4)
        XCTAssertEqual(client.remaining, 6)
    }

    func testMarkDoneUndoRestoresPackage() {
        let client = makeClient(packageTotal: 10, used: 3)
        let lesson = makeLesson(for: client)

        let undo = LessonActions.markDone(lesson, context: context)
        undo()

        XCTAssertEqual(lesson.status, .planned)
        XCTAssertEqual(client.package?.used, 3)
    }

    // MARK: Долг

    func testMarkDoneWithoutPackageCreatesDebt() {
        let client = makeClient(packageTotal: nil)
        let lesson = makeLesson(for: client)

        _ = LessonActions.markDone(lesson, context: context)

        XCTAssertNotNil(client.package, "должен создаться нулевой пакет-долг")
        XCTAssertEqual(client.package?.total, 0)
        XCTAssertEqual(client.debt, 1)
        XCTAssertEqual(client.remainingText, "долг 1")
    }

    func testUndoRemovesAutoCreatedDebtPackage() {
        let client = makeClient(packageTotal: nil)
        let lesson = makeLesson(for: client)

        let undo = LessonActions.markDone(lesson, context: context)
        undo()

        XCTAssertNil(client.package, "авто-созданный пакет-долг должен исчезнуть при откате")
        XCTAssertEqual(client.debt, 0)
    }

    func testDebtGrowsBeyondEmptyPackage() {
        let client = makeClient(packageTotal: 10, used: 10)
        let lesson = makeLesson(for: client)

        _ = LessonActions.markDone(lesson, context: context)

        XCTAssertEqual(client.debt, 1)
        XCTAssertEqual(client.remaining, -1)
    }

    // MARK: Отмена

    func testCancelWithChargeAndUndo() {
        let client = makeClient(packageTotal: 10, used: 5)
        let lesson = makeLesson(for: client)

        let undo = LessonActions.cancel(lesson, charge: true)
        XCTAssertEqual(lesson.status, .cancelled)
        XCTAssertTrue(lesson.charged)
        XCTAssertEqual(client.package?.used, 6)

        undo()
        XCTAssertEqual(lesson.status, .planned)
        XCTAssertFalse(lesson.charged)
        XCTAssertEqual(client.package?.used, 5)
    }

    func testCancelWithoutChargeKeepsPackage() {
        let client = makeClient(packageTotal: 10, used: 5)
        let lesson = makeLesson(for: client)

        _ = LessonActions.cancel(lesson, charge: false)

        XCTAssertEqual(lesson.status, .cancelled)
        XCTAssertFalse(lesson.charged)
        XCTAssertEqual(client.package?.used, 5)
    }

    // MARK: Рекомендация списания (окно поздней отмены)

    func testRecommendChargeInsideWindow() {
        let lesson = Lesson(date: Date().addingTimeInterval(2 * 3600)) // через 2 часа
        XCTAssertTrue(LessonActions.recommendCharge(lesson, lateCancelHours: 8))
    }

    func testNoChargeRecommendationOutsideWindow() {
        let lesson = Lesson(date: Date().addingTimeInterval(20 * 3600)) // через 20 часов
        XCTAssertFalse(LessonActions.recommendCharge(lesson, lateCancelHours: 8))
    }

    // MARK: Семафор

    func testSemaphoreThresholds() {
        XCTAssertEqual(SemaphoreState.from(remaining: nil, yellowThreshold: 3), .none)
        XCTAssertEqual(SemaphoreState.from(remaining: -2, yellowThreshold: 3), .red)
        XCTAssertEqual(SemaphoreState.from(remaining: 0, yellowThreshold: 3), .red)
        XCTAssertEqual(SemaphoreState.from(remaining: 3, yellowThreshold: 3), .yellow)
        XCTAssertEqual(SemaphoreState.from(remaining: 4, yellowThreshold: 3), .green)
    }

    // MARK: Заголовки пакета

    func testPackageTitles() {
        XCTAssertEqual(Package(kind: .package, total: 10).title, "Пакет 10 занятий")
        XCTAssertEqual(Package(kind: .package, total: 0).title, "Занятия в долг")
        XCTAssertEqual(Package(kind: .trial, total: 1).title, "Пробное")
    }
}

extension SemaphoreState: Equatable {}
