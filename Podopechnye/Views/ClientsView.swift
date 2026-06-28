import SwiftUI
import SwiftData

struct ClientsView: View {
    @Query(sort: \Client.name) private var clients: [Client]
    @EnvironmentObject private var settings: SettingsStore
    @State private var search = ""
    @State private var segment: Segment = .all
    @State private var sortByRemaining = false
    @State private var addingClient = false
    @State private var showSettings = false

    private var yellowThreshold: Int { settings.yellowThreshold }

    enum Segment: String, CaseIterable, Identifiable {
        case all = "Все", active = "Активные", trial = "Пробные", archive = "Архив"
        var id: String { rawValue }
    }

    private var visible: [Client] {
        var list = clients.filter { c in
            switch segment {
            case .all:     return c.status != .archived
            case .active:  return c.status == .active
            case .trial:   return c.status == .trial
            case .archive: return c.status == .archived
            }
        }
        if !search.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(search) }
        }
        if sortByRemaining {
            list.sort { ($0.remaining ?? Int.max) < ($1.remaining ?? Int.max) }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    Section {
                        Picker("Сегмент", selection: $segment) {
                            ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .listRowSeparator(.hidden)

                        HStack {
                            Spacer()
                            Button {
                                sortByRemaining.toggle()
                            } label: {
                                Label(sortByRemaining ? "по остатку" : "по имени",
                                      systemImage: "arrow.up.arrow.down")
                                    .font(.system(size: 14))
                            }
                        }
                        .listRowSeparator(.hidden)
                    }

                    ForEach(visible) { client in
                        NavigationLink {
                            ClientDetailView(client: client, yellowThreshold: yellowThreshold)
                        } label: {
                            ClientRow(client: client, yellowThreshold: yellowThreshold)
                        }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if visible.isEmpty {
                        ContentUnavailableView(
                            search.isEmpty ? emptyTitle : "Никого не нашли",
                            systemImage: "person.2",
                            description: Text(search.isEmpty && segment != .archive ? "Добавьте клиента кнопкой +" : "")
                        )
                    }
                }

                FloatingAddButton { addingClient = true }
            }
            .navigationTitle("Клиенты")
            .searchable(text: $search, prompt: "Поиск по имени")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $addingClient) { ClientFormView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var emptyTitle: String {
        switch segment {
        case .archive: return "Архив пуст"
        case .trial:   return "Нет пробных"
        default:       return "Пока нет клиентов"
        }
    }
}

struct ClientRow: View {
    let client: Client
    let yellowThreshold: Int

    var body: some View {
        HStack(spacing: 12) {
            InitialsAvatar(initials: client.initials)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(client.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.appText)
                    if client.status == .trial { StatusBadge(text: "Пробный") }
                }
                Text(client.package?.title ?? "Без пакета")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appSecondary)
            }

            Spacer()
            remainingLabel
            SemaphoreDot(state: client.semaphore(yellowThreshold: yellowThreshold))
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var remainingLabel: some View {
        if client.debt > 0 {
            Text("долг \(client.debt)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.semRed)
        } else if let package = client.package {
            Text("\(package.remaining) / \(package.total)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(client.semaphore(yellowThreshold: yellowThreshold).color)
                .monospacedDigit()
        }
    }
}

#Preview {
    ClientsView()
        .modelContainer(PreviewData.container)
        .environmentObject(SettingsStore())
        .environmentObject(ToastCenter())
        .environmentObject(CalendarService.shared)
}
