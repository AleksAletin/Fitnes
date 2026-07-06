import SwiftUI

struct RootView: View {
    @EnvironmentObject private var calendar: CalendarService
    @EnvironmentObject private var settings: SettingsStore
    @AppStorage("didOnboardCalendar") private var didOnboard = false
    @State private var showOnboarding = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Сегодня", systemImage: "calendar") }
            ClientsView()
                .tabItem { Label("Клиенты", systemImage: "person.2.fill") }
        }
        .tint(.appAccent)
        .preferredColorScheme(settings.colorScheme)
        .overlay(ToastView())
        .sheet(isPresented: $showOnboarding) {
            CalendarPermissionView { didOnboard = true }
        }
        .onAppear {
            calendar.refreshAccess()
            if !didOnboard && !calendar.granted { showOnboarding = true }
        }
    }
}

// Pre-permission экран Календаря (DEV_BRIEF §2, §8): объясняем зачем доступ
// до системного диалога.
struct CalendarPermissionView: View {
    @EnvironmentObject private var calendar: CalendarService
    @Environment(\.dismiss) private var dismiss
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(Color.appAccent)
            Text("Доступ к Календарю")
                .font(.title2.bold())
            VStack(spacing: 12) {
                permissionRow(icon: "plus.circle.fill", text: "Занятия автоматически попадают в Календарь айфона — в отдельный календарь «Тренировки».")
                permissionRow(icon: "exclamationmark.triangle.fill", text: "При записи проверяется, не занято ли время другими событиями.")
            }
            .padding(.horizontal, 24)
            Spacer()
            VStack(spacing: 12) {
                Button {
                    Task {
                        _ = await calendar.requestAccess()
                        finish()
                    }
                } label: {
                    Text("Разрешить доступ")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 14))
                }
                Button("Позже") { finish() }
                    .font(.callout)
                    .foregroundStyle(Color.appSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .interactiveDismissDisabled()
    }

    private func permissionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(Color.appAccent).frame(width: 24)
            Text(text).font(.subheadline).foregroundStyle(Color.appText)
            Spacer()
        }
    }

    private func finish() {
        onFinish()
        dismiss()
    }
}

#Preview {
    RootView()
        .previewEnvironment()
}
