import SwiftUI
import SwiftData

struct PackageFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsStore

    @Bindable var client: Client

    @State private var kind: PackageKind = .package
    @State private var count = 10
    @State private var price = ""

    private let presets = [5, 10, 12]
    private var needsCount: Bool { kind == .package || kind == .period }

    var body: some View {
        NavigationStack {
            Form {
                Section("Тип") {
                    Picker("Тип", selection: $kind) {
                        ForEach(PackageKind.allCases) { k in Text(k.title).tag(k) }
                    }
                    .pickerStyle(.segmented)
                }

                if needsCount {
                    Section("Количество занятий") {
                        Picker("Пресет", selection: $count) {
                            ForEach(presets, id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Stepper("Своё число: \(count)", value: $count, in: 1...60)
                    }
                }

                Section("Цена") {
                    TextField("напр. 8 000 ₽", text: $price)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Пакет")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(.thinMaterial)
            .onAppear { if !presets.contains(count) || count == 10 { count = settings.defaultPackageCount } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Сохранить") { save() } }
            }
        }
    }

    private func save() {
        let total: Int = needsCount ? count : 1
        let package = Package(kind: kind, total: total, used: 0, price: price, date: Date())
        client.package = package
        context.insert(package)

        let payment = Payment(date: Date(), type: package.title, sum: price.isEmpty ? "—" : price)
        payment.client = client
        context.insert(payment)

        dismiss()
    }
}
