import SwiftUI
import SwiftData

struct ClientFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var client: Client?   // nil — создаём нового

    @State private var name = ""
    @State private var phone = ""
    @State private var tg = ""
    @State private var status: ClientStatus = .active
    @State private var notes = ""

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Имя", text: $name)
                    TextField("Телефон", text: $phone).keyboardType(.phonePad)
                    TextField("Телеграм @username", text: $tg).autocorrectionDisabled().textInputAutocapitalization(.never)
                }
                Section("Статус") {
                    Picker("Статус", selection: $status) {
                        Text("Активный").tag(ClientStatus.active)
                        Text("Пробный").tag(ClientStatus.trial)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Цель и заметки") {
                    TextField("Цель, травмы, предпочтения", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(client == nil ? "Новый клиент" : "Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }.disabled(!isValid)
                }
            }
            .onAppear(perform: load)
            .presentationBackground(.thinMaterial)
        }
    }

    private func load() {
        guard let client else { return }
        name = client.name
        phone = client.phone ?? ""
        tg = client.tg ?? ""
        status = client.status == .archived ? .active : client.status
        notes = client.notes ?? ""
    }

    private func save() {
        let target: Client
        if let client {
            target = client
        } else {
            target = Client(name: "")
            context.insert(target)
        }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.phone = phone.isEmpty ? nil : phone
        target.tg = tg.isEmpty ? nil : tg
        target.status = status
        target.notes = notes.isEmpty ? nil : notes
        dismiss()
    }
}
