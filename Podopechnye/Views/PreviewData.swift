import Foundation
import SwiftData

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
