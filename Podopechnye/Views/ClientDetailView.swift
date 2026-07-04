import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Bindable var client: Client
    var yellowThreshold: Int = 3

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var editingClient = false
    @State private var editingPackage = false
    @State private var addingLesson = false
    @State private var showDeleteConfirm = false
    @State private var showCallSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                packageCard
                contactsBar
                if let notes = client.notes, !notes.isEmpty {
                    sectionCard("Заметки") {
                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.appText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                upcomingCard
                historyCard
            }
            .padding(16)
        }
        .background(Color.appBackground)
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editingClient = true } label: { Label("Редактировать", systemImage: "pencil") }
                    if client.status == .archived {
                        Button { client.unarchive() } label: { Label("Вернуть из архива", systemImage: "tray.and.arrow.up") }
                    } else {
                        Button { client.archive() } label: { Label("В архив", systemImage: "archivebox") }
                    }
                    Button(role: .destructive) { showDeleteConfirm = true } label: { Label("Удалить", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $editingClient) {
            ClientFormView(client: client)
        }
        .sheet(isPresented: $editingPackage) {
            PackageFormView(client: client)
        }
        .sheet(isPresented: $addingLesson) {
            LessonFormView(presetClient: client)
        }
        .confirmationDialog("Удалить клиента?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                // Убираем события клиента из Календаря айфона, иначе они осиротеют.
                for lesson in client.lessons where lesson.eventId != nil {
                    CalendarService.shared.remove(eventId: lesson.eventId)
                }
                context.delete(client)
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Удалится клиент и все его занятия. Чтобы сохранить историю — используйте архив.")
        }
    }

    // MARK: Пакет
    private var packageCard: some View {
        sectionCard {
            HStack(spacing: 16) {
                PackageRing(client: client, yellowThreshold: yellowThreshold, size: 110)
                VStack(alignment: .leading, spacing: 6) {
                    Text(client.package?.title ?? "Без пакета")
                        .font(.system(size: 17, weight: .semibold))
                    if let p = client.package {
                        Text("оплачено \(p.total) · проведено \(p.used)")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appSecondary)
                        if !p.price.isEmpty {
                            Text(p.price).font(.system(size: 14)).foregroundStyle(Color.appSecondary)
                        }
                    }
                    Button {
                        editingPackage = true
                    } label: {
                        Text(client.package == nil ? "Оформить пакет" : "Продлить / новый пакет")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.appAccent, in: Capsule())
                    }
                    .padding(.top, 2)
                }
                Spacer()
            }
        }
    }

    // MARK: Контакты — звонок / телеграм
    @ViewBuilder
    private var contactsBar: some View {
        if (client.phone?.isEmpty == false) || (client.tg?.isEmpty == false) {
            HStack(spacing: 12) {
                if let phone = client.phone, !phone.isEmpty {
                    contactButton(title: "Позвонить", icon: "phone.fill") { showCallSheet = true }
                        .confirmationDialog("Позвонить", isPresented: $showCallSheet, titleVisibility: .visible) {
                            Button(phone) {
                                let digits = phone.filter { $0.isNumber || $0 == "+" }
                                if let url = URL(string: "tel://\(digits)") { openURL(url) }
                            }
                            Button("Отмена", role: .cancel) {}
                        }
                }
                if let tg = client.tg, !tg.isEmpty {
                    contactButton(title: "Телеграм", icon: "paperplane.fill") { openTelegram(tg) }
                }
            }
        }
    }

    private func openTelegram(_ tg: String) {
        let user = tg.hasPrefix("@") ? String(tg.dropFirst()) : tg
        if let deeplink = URL(string: "tg://resolve?domain=\(user)") {
            openURL(deeplink) { accepted in
                if !accepted, let web = URL(string: "https://t.me/\(user)") { openURL(web) }
            }
        }
    }

    private func contactButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appCard, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var upcomingCard: some View {
        let upcoming = client.lessons
            .filter { $0.status == .planned && $0.date >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.date < $1.date }
        sectionCard("Ближайшие занятия") {
            VStack(spacing: 10) {
                if upcoming.isEmpty {
                    Text("Нет запланированных занятий")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(upcoming) { lesson in
                        HStack {
                            Text(lesson.date.formatted(.dateTime.day().month().hour().minute()))
                                .font(.system(size: 15))
                            Spacer()
                            if let badge = lesson.kind.badge { StatusBadge(text: badge) }
                        }
                    }
                }
                Button { addingLesson = true } label: {
                    Label("Записать занятие", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private var historyCard: some View {
        let past = client.lessons
            .filter { $0.status != .planned }
            .sorted { $0.date > $1.date }
        if !past.isEmpty || !client.payments.isEmpty {
            sectionCard("История") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(past) { lesson in
                        HStack {
                            Text(lesson.date.formatted(.dateTime.day().month()))
                                .font(.system(size: 14)).foregroundStyle(Color.appSecondary)
                            Spacer()
                            Text(historyStatus(lesson))
                                .font(.system(size: 14))
                                .foregroundStyle(lesson.status == .done ? Color.semGreen : Color.appSecondary)
                        }
                    }
                    if !client.payments.isEmpty {
                        Divider().padding(.vertical, 4)
                        ForEach(client.payments.sorted { $0.date > $1.date }) { p in
                            HStack {
                                Text(p.type).font(.system(size: 14))
                                Spacer()
                                Text(p.sum).font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                }
            }
        }
    }

    private func historyStatus(_ lesson: Lesson) -> String {
        switch lesson.status {
        case .done: return "проведено"
        case .cancelled: return lesson.charged ? "отменено · списано" : "отменено"
        case .planned: return ""
        }
    }

    // MARK: Хелпер карточки-секции
    private func sectionCard<Content: View>(_ title: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appSecondary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 16))
    }
}
