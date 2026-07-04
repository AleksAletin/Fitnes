import SwiftUI
import SwiftData

struct LessonFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toasts: ToastCenter
    @EnvironmentObject private var settings: SettingsStore
    @Query(sort: \Client.name) private var allClients: [Client]

    var presetClient: Client?       // фиксированный клиент (из карточки)
    var lessonToEdit: Lesson?       // режим переноса

    @State private var selectedClient: Client?
    @State private var date = Date()
    @State private var note = ""
    @State private var conflicts: [String] = []
    @State private var showConflict = false

    private var isTransfer: Bool { lessonToEdit != nil }
    private var fixedClient: Client? { presetClient ?? lessonToEdit?.client }

    private var activeClients: [Client] { allClients.filter { $0.status != .archived } }
    private var isValid: Bool { (fixedClient ?? selectedClient) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Клиент") {
                    if let client = fixedClient {
                        HStack {
                            InitialsAvatar(initials: client.initials, size: 32)
                            Text(client.name)
                        }
                    } else {
                        Picker("Клиент", selection: $selectedClient) {
                            Text("Выберите").tag(Client?.none)
                            ForEach(activeClients) { c in Text(c.name).tag(Client?.some(c)) }
                        }
                    }
                }

                Section("Дата") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "ru_RU"))
                        .labelsHidden()
                }
                Section("Время") {
                    WheelTimePicker(date: $date)
                        .frame(height: 150)
                }

                if !isTransfer {
                    Section("Заметка к занятию") {
                        TextField("Необязательно", text: $note, axis: .vertical).lineLimit(2...4)
                    }
                    Section {
                        Text("Занятие спишется из текущего пакета и попадёт в Календарь айфона.")
                            .font(.footnote).foregroundStyle(Color.appSecondary)
                    }
                } else {
                    Section {
                        Text("Дата и время обновятся, событие переедет в Календаре. Пакет не тронется.")
                            .font(.footnote).foregroundStyle(Color.appSecondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(isTransfer ? "Перенести занятие" : "Записать занятие")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(.thinMaterial)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isTransfer ? "Перенести" : "Записать") { attemptSave() }.disabled(!isValid)
                }
            }
            .onAppear(perform: load)
            // .alert вместо confirmationDialog — на iOS 26 диалог-поповер всплывает не на месте.
            .alert("Время занято", isPresented: $showConflict) {
                Button("Записать всё равно") { commit() }
                Button("Изменить время", role: .cancel) {}
            } message: {
                Text(conflictMessage)
            }
        }
    }

    private func load() {
        if let lesson = lessonToEdit { date = lesson.date }
        if let preset = presetClient { selectedClient = preset }
    }

    private var conflictMessage: String {
        conflicts.joined(separator: "\n")
    }

    private func attemptSave() {
        conflicts = findConflicts()
        if conflicts.isEmpty { commit() } else { showConflict = true }
    }

    // Конфликты: занятия приложения + личный Календарь (DEV_BRIEF §6.6).
    // Считаем пересечение интервалов: занятия длятся lessonDurationMinutes (настройка).
    private func findConflicts() -> [String] {
        var result: [String] = []
        let duration = TimeInterval(settings.lessonDurationMinutes * 60)
        let newEnd = date.addingTimeInterval(duration)
        let appConflicts = allClients.flatMap { $0.lessons }.filter { lesson in
            lesson.id != lessonToEdit?.id &&
            lesson.status == .planned &&
            lesson.date < newEnd && date < lesson.date.addingTimeInterval(duration)
        }
        for l in appConflicts {
            result.append("Время занято — уже есть занятие с \(l.client?.name ?? "клиентом") в \(l.timeText)")
        }
        for title in CalendarService.shared.conflictTitles(start: date, durationOverride: duration) {
            result.append("Занято в Календаре — «\(title)»")
        }
        return result
    }

    private func commit() {
        let client = fixedClient ?? selectedClient
        guard let client else { return }

        let lesson: Lesson
        let oldDate = lessonToEdit?.date
        if let existing = lessonToEdit {
            lesson = existing
        } else {
            lesson = Lesson(date: date, kind: client.status == .trial ? .trial : .package)
            lesson.client = client
            lesson.note = note.isEmpty ? nil : note
            context.insert(lesson)
        }
        lesson.date = date

        // Запись в Календарь айфона.
        lesson.eventId = CalendarService.shared.upsert(
            title: "Тренировка · \(client.name)",
            start: date,
            existingEventId: lesson.eventId
        )

        if isTransfer, let oldDate {
            toasts.show("Занятие перенесено") {
                lesson.date = oldDate
                lesson.eventId = CalendarService.shared.upsert(
                    title: "Тренировка · \(client.name)", start: oldDate, existingEventId: lesson.eventId)
            }
        }

        dismiss()
    }
}
