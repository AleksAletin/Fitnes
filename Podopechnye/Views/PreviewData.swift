import Foundation
import SwiftData
import SwiftUI

// In-memory контейнер с демо-данными для SwiftUI-превью.
enum PreviewData {
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Client.self, Package.self, Lesson.self, Payment.self,
            configurations: config
        )
        SampleData.seedIfNeeded(ModelContext(container))
        return container
    }()
}

// Общее окружение для #Preview, чтобы не повторять environmentObject в каждом.
extension View {
    func previewEnvironment() -> some View {
        self
            .modelContainer(PreviewData.container)
            .environmentObject(SettingsStore())
            .environmentObject(ToastCenter())
            .environmentObject(CalendarService.shared)
    }
}
