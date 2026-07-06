import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var lessons: [Lesson]
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var toasts: ToastCenter

    @State private var day = Calendar.current.startOfDay(for: Date())
    @State private var addingLesson = false
    @State private var editingLesson: Lesson?
    @State private var transferLesson: Lesson?
    @State private var packageEmptyLesson: Lesson?
    @State private var cancelLesson: Lesson?
    @State private var showSettings = false

    private var lessonsOfDay: [Lesson] {
        let cal = Calendar.current
        return lessons
            .filter { cal.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date < $1.date }
    }

    private var lessonDays: Set<String> {
        Set(lessons.filter { $0.status != .cancelled }.map { SettingsStore.key($0.date) })
    }

    private var isPast: Bool {
        day < Calendar.current.startOfDay(for: Date())
    }

    private var isDayOff: Bool { settings.isDayOff(day) }

    private var title: String {
        Calendar.current.isDateInToday(day) ? "Сегодня" : "Расписание"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CalendarHeader(selectedDay: $day, lessonDays: lessonDays)
                Divider()
                ZStack(alignment: .bottomTrailing) {
                    listContent
                    FloatingAddButton { addingLesson = true }
                }
            }
            .background(Color.appBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if isDayOff {
                        Text("Выходной")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.appAccent.opacity(0.12), in: Capsule())
                    }
                    if !Calendar.current.isDateInToday(day) {
                        Button { withAnimation(.snappy) { day = Calendar.current.startOfDay(for: Date()) } } label: { Text("Сегодня") }
                    }
                }
            }
            .sheet(isPresented: $addingLesson) { LessonFormView() }
            .sheet(item: $editingLesson) { ProgramEditorView(lesson: $0) }
            .sheet(item: $transferLesson) { LessonFormView(lessonToEdit: $0) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .alert("Занятие не оплачено", isPresented: emptyAlertBinding, presenting: packageEmptyLesson) { lesson in
                Button("Провести в долг") { performDone(lesson) }
                Button("Отмена", role: .cancel) {}
            } message: { _ in
                Text("У клиента нет оплаченных занятий. «Провести в долг» — остаток уйдёт в минус и подсветится красным, пока не оформите пакет.")
            }
            // .alert вместо confirmationDialog: на iOS 26 диалоги-поповеры
            // всплывают у верха экрана и выглядят «не на месте».
            .alert("Отменить занятие?", isPresented: cancelDialogBinding, presenting: cancelLesson) { lesson in
                let charge = recommendCharge(lesson)
                Button(charge ? "Отменить со списанием" : "Отменить без списания") { cancel(lesson, charge: charge) }
                Button(charge ? "Отменить без списания" : "Отменить со списанием") { cancel(lesson, charge: !charge) }
                Button("Назад", role: .cancel) {}
            } message: { lesson in
                Text(recommendCharge(lesson)
                     ? "До занятия меньше \(settings.lateCancelHours) ч — по правилам занятие списывается. Можно сделать исключение."
                     : "До занятия больше \(settings.lateCancelHours) ч — списание не требуется.")
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        List {
            ForEach(lessonsOfDay) { lesson in
                LessonRow(lesson: lesson, yellowThreshold: settings.yellowThreshold)
                    .contentShape(Rectangle())
                    .onTapGesture { editingLesson = lesson }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if lesson.status == .planned && !isPast {
                            Button { tapDone(lesson) } label: { Label("Провести", systemImage: "checkmark") }
                                .tint(.semGreen)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if lesson.status == .planned && !isPast {
                            Button(role: .destructive) { cancelLesson = lesson } label: { Label("Отменить", systemImage: "xmark") }
                            Button { transferLesson = lesson } label: { Label("Перенести", systemImage: "calendar") }.tint(.blue)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .overlay {
            if lessonsOfDay.isEmpty {
                if isDayOff {
                    ContentUnavailableView("Выходной", systemImage: "moon.zzz",
                                           description: Text("По расписанию это выходной. Записать занятие всё равно можно."))
                } else {
                    ContentUnavailableView("На этот день занятий нет", systemImage: "calendar",
                                           description: Text("Запишите занятие кнопкой +"))
                }
            }
        }
    }

    // MARK: Действия
    private func tapDone(_ lesson: Lesson) {
        // Нет пакета или пакет исчерпан → спрашиваем про долг.
        let remaining = lesson.client?.package?.remaining
        if remaining == nil || remaining! <= 0 {
            packageEmptyLesson = lesson
        } else {
            performDone(lesson)
        }
    }

    private func performDone(_ lesson: Lesson) {
        var undo: (() -> Void)!
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            undo = LessonActions.markDone(lesson, context: context)
        }
        toasts.show("Занятие проведено", undo: undo)
    }

    private func cancel(_ lesson: Lesson, charge: Bool) {
        var undo: (() -> Void)!
        withAnimation {
            undo = LessonActions.cancel(lesson, charge: charge)
        }
        toasts.show(charge ? "Отменено · списано" : "Отменено", undo: undo)
    }

    private func recommendCharge(_ lesson: Lesson) -> Bool {
        LessonActions.recommendCharge(lesson, lateCancelHours: settings.lateCancelHours)
    }

    private var emptyAlertBinding: Binding<Bool> {
        Binding(get: { packageEmptyLesson != nil }, set: { if !$0 { packageEmptyLesson = nil } })
    }
    private var cancelDialogBinding: Binding<Bool> {
        Binding(get: { cancelLesson != nil }, set: { if !$0 { cancelLesson = nil } })
    }
}

struct LessonRow: View {
    let lesson: Lesson
    let yellowThreshold: Int

    private var client: Client? { lesson.client }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(lesson.timeText)
                .font(.headline)
                .foregroundStyle(Color.appText).monospacedDigit()
                .frame(width: 56, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(client?.name ?? "—")
                        .font(.headline)
                        .foregroundStyle(lesson.status == .done ? Color.appSecondary : Color.appText)
                        .strikethrough(lesson.status == .cancelled)
                    if let badge = lesson.kind.badge { StatusBadge(text: badge) }
                }
                HStack(spacing: 6) {
                    SemaphoreDot(state: client?.semaphore(yellowThreshold: yellowThreshold) ?? .none)
                    Text(client?.remainingText ?? "Без пакета")
                        .font(.subheadline).foregroundStyle(Color.appSecondary)
                }
                if lesson.hasProgram {
                    Text(programPreview).font(.footnote).foregroundStyle(Color.appAccent).lineLimit(2)
                }
                if let note = lesson.note, !note.isEmpty {
                    Text(note).font(.footnote).foregroundStyle(Color.appSecondary).lineLimit(2)
                }
            }
            Spacer()
            if lesson.status == .done {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.semGreen)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .opacity(lesson.status == .planned ? 1 : 0.55)
    }

    private var programPreview: String {
        lesson.program
            .map { [$0.ex, $0.weight].filter { !$0.isEmpty }.joined(separator: " ") }
            .joined(separator: " · ")
    }
}

#Preview {
    TodayView()
        .previewEnvironment()
}
