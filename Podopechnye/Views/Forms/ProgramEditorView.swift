import SwiftUI
import SwiftData

// Редактор занятия: «Упражнения» / «Заметка». Оба режима хранятся независимо.
struct ProgramEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var lesson: Lesson

    enum Mode { case exercises, note }
    @State private var mode: Mode = .exercises
    @State private var exercises: [Exercise] = []
    @State private var note = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $mode) {
                    Text("Упражнения").tag(Mode.exercises)
                    Text("Заметка").tag(Mode.note)
                }
                .pickerStyle(.segmented)
                .padding(16)

                if mode == .exercises {
                    exercisesList
                } else {
                    noteEditor
                }
            }
            .background(.clear)
            .presentationBackground(.thinMaterial)
            .navigationTitle(lesson.client?.name ?? "Занятие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { save() }
                }
            }
            .onAppear {
                exercises = lesson.program.isEmpty ? [Exercise()] : lesson.program
                note = lesson.note ?? ""
                mode = (lesson.program.isEmpty && !(lesson.note ?? "").isEmpty) ? .note : .exercises
            }
        }
    }

    private var exercisesList: some View {
        List {
            ForEach($exercises) { $ex in
                VStack(spacing: 8) {
                    TextField("Упражнение", text: $ex.ex)
                        .font(.system(size: 16, weight: .medium))
                    HStack {
                        TextField("Вес, кг", text: $ex.weight).keyboardType(.numbersAndPunctuation)
                        Divider()
                        TextField("Схема, напр. 4×12", text: $ex.scheme)
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appSecondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete { exercises.remove(atOffsets: $0) }

            Button {
                exercises.append(Exercise())
            } label: {
                Label("Добавить упражнение", systemImage: "plus")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var noteEditor: some View {
        TextEditor(text: $note)
            .padding(12)
            .scrollContentBackground(.hidden)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12))
            .padding(16)
    }

    private func save() {
        lesson.program = exercises.filter { !$0.ex.trimmingCharacters(in: .whitespaces).isEmpty }
        lesson.note = note.isEmpty ? nil : note
        dismiss()
    }
}
