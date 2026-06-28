import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var calendar: CalendarService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Оформление") {
                    Picker("Тема", selection: $settings.appearanceRaw) {
                        Text("Система").tag(0)
                        Text("Светлая").tag(1)
                        Text("Тёмная").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Сигнал остатка") {
                    Stepper("Жёлтый при остатке ≤ \(settings.yellowThreshold)",
                            value: $settings.yellowThreshold, in: 1...10)
                    Text("При остатке ниже этого числа клиент подсветится жёлтым — пора напомнить про оплату.")
                        .font(.footnote).foregroundStyle(Color.appSecondary)
                }

                Section("Отмена занятия") {
                    Stepper("Списывать при отмене позже чем за \(settings.lateCancelHours) ч",
                            value: $settings.lateCancelHours, in: 0...48)
                    Text("Если до занятия меньше этого времени — по умолчанию предлагается списать. Исключение всегда можно сделать.")
                        .font(.footnote).foregroundStyle(Color.appSecondary)
                }

                Section("Пакет по умолчанию") {
                    Stepper("\(settings.defaultPackageCount) занятий",
                            value: $settings.defaultPackageCount, in: 1...30)
                }

                Section("Календарь айфона") {
                    HStack {
                        Text("Доступ к Календарю")
                        Spacer()
                        Text(calendar.granted ? "Разрешён" : "Нет")
                            .foregroundStyle(calendar.granted ? Color.semGreen : Color.appSecondary)
                    }
                    if !calendar.granted {
                        Button("Запросить доступ") {
                            Task { _ = await calendar.requestAccess() }
                        }
                    }
                }

                Section {
                    Text("Подопечные · версия 0.1")
                        .font(.footnote).foregroundStyle(Color.appSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(.thinMaterial)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } }
            }
        }
    }
}
