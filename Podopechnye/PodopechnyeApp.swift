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
        // Демо-данные в продакшене не засеваем — приложение стартует пустым.
        // SampleData используется только в SwiftUI-превью (см. PreviewData)
        // и для скриншотов App Store по debug-флагу запуска (в релиз не входит).
        #if DEBUG
        if CommandLine.arguments.contains("-seedDemo") {
            SampleData.seedIfNeeded(container.mainContext)
            UserDefaults.standard.set(true, forKey: "didOnboardCalendar")
        }
        #endif
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
