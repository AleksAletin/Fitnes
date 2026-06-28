import SwiftUI
import SwiftData

@main
struct PodopechnyeApp: App {
    let container: ModelContainer
    @StateObject private var settings = SettingsStore()
    @StateObject private var toasts = ToastCenter()
    @StateObject private var calendar = CalendarService.shared

    init() {
        do {
            container = try ModelContainer(
                for: Client.self, Package.self, Lesson.self, Payment.self
            )
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
        SampleData.seedIfNeeded(container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(toasts)
                .environmentObject(calendar)
        }
        .modelContainer(container)
    }
}
