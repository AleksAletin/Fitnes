import SwiftUI

// Календарь в шапке «Сегодня»: неделя ↔ месяц, точки тренировок, плавающие выходные.
// (DEV_BRIEF §4, §6.7, §6.8). Выходные редактируются только в режиме недели.
struct CalendarHeader: View {
    @Binding var selectedDay: Date
    let lessonDays: Set<String>          // ключи дней с занятиями
    @EnvironmentObject private var settings: SettingsStore
    @State private var expanded = false

    private let cal = Calendar.current
    private let weekdaySymbols = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        VStack(spacing: 10) {
            titleRow
            if expanded {
                weekdayLabels
                monthGrid
            } else {
                weekStrip
                dayOffToggles
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var titleRow: some View {
        HStack {
            Text(monthYearText).font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appSecondary)
            Spacer()
            Button {
                withAnimation(.snappy) { expanded.toggle() }
            } label: {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
        }
    }

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { s in
                Text(s).font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.appSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDates().enumerated()), id: \.offset) { idx, date in
                VStack(spacing: 4) {
                    Text(weekdaySymbols[idx])
                        .font(.system(size: 12)).foregroundStyle(Color.appSecondary)
                    dayCell(date)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .contentShape(Rectangle())
        .id(SettingsStore.key(startOfWeek(selectedDay)))
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width < -40 { shiftWeek(1) }
                    else if value.translation.width > 40 { shiftWeek(-1) }
                }
        )
    }

    private func shiftWeek(_ direction: Int) {
        withAnimation(.snappy) {
            if let d = cal.date(byAdding: .day, value: 7 * direction, to: selectedDay) {
                selectedDay = cal.startOfDay(for: d)
            }
        }
    }

    private var monthGrid: some View {
        let days = monthGridDates()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 38)
                }
            }
        }
        .contentShape(Rectangle())
        .id(monthYearText)
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width < -40 { shiftMonth(1) }
                    else if value.translation.width > 40 { shiftMonth(-1) }
                }
        )
    }

    private func shiftMonth(_ direction: Int) {
        withAnimation(.snappy) {
            if let d = cal.date(byAdding: .month, value: direction, to: selectedDay) {
                selectedDay = cal.startOfDay(for: d)
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = cal.isDate(date, inSameDayAs: selectedDay)
        let isToday = cal.isDateInToday(date)
        let hasLessons = lessonDays.contains(SettingsStore.key(date))
        let isOff = settings.isDayOff(date)

        return Button {
            withAnimation(.snappy) { selectedDay = cal.startOfDay(for: date) }
        } label: {
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(textColor(isSelected: isSelected, isToday: isToday, isOff: isOff))
                    .frame(width: 34, height: 34)
                    .background {
                        if isSelected { Circle().fill(Color.appAccent) }
                        else if isOff { Circle().fill(Color.appBackground) }
                    }
                Circle()
                    .fill(hasLessons ? Color.appAccent : .clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
    }

    private func textColor(isSelected: Bool, isToday: Bool, isOff: Bool) -> Color {
        if isSelected { return .white }
        if isOff { return .appSecondary }
        if isToday { return .appAccent }
        return .appText
    }

    // Переключатели выходных для текущей недели.
    private var dayOffToggles: some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill").font(.system(size: 11)).foregroundStyle(Color.appSecondary)
            Text("Выходные:").font(.system(size: 12)).foregroundStyle(Color.appSecondary)
            ForEach(Array(weekDates().enumerated()), id: \.offset) { idx, date in
                Button {
                    settings.toggleDayOff(date)
                } label: {
                    Text(weekdaySymbols[idx])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(settings.isDayOff(date) ? .white : Color.appSecondary)
                        .frame(width: 26, height: 22)
                        .background(settings.isDayOff(date) ? Color.appAccent : Color.appBackground,
                                    in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Вычисления дат
    private func startOfWeek(_ date: Date) -> Date {
        let weekday = cal.component(.weekday, from: date)        // 1=Вс ... 7=Сб
        let daysFromMonday = (weekday + 5) % 7                   // 0 для Пн
        return cal.date(byAdding: .day, value: -daysFromMonday, to: cal.startOfDay(for: date))!
    }

    private func weekDates() -> [Date] {
        let start = startOfWeek(selectedDay)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private func monthGridDates() -> [Date?] {
        let comps = cal.dateComponents([.year, .month], from: selectedDay)
        guard let firstOfMonth = cal.date(from: comps) else { return [] }
        let gridStart = startOfWeek(firstOfMonth)
        let range = cal.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
        let monthIndex = cal.component(.month, from: firstOfMonth)
        var result: [Date?] = []
        for i in 0..<42 {
            let date = cal.date(byAdding: .day, value: i, to: gridStart)!
            // Показываем только дни текущего месяца, прочие — пустые ячейки.
            result.append(cal.component(.month, from: date) == monthIndex ? date : nil)
            _ = range
        }
        return result
    }

    private var monthYearText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: selectedDay).capitalized
    }
}
