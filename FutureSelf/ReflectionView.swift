//
//  ReflectionView.swift
//  Monthly calendar retrospective: tap a day to see what happened.
//

import SwiftUI
import SwiftData

struct ReflectionView: View {
    @Query(filter: #Predicate<Habit> { $0.isArchived == false })
    private var habits: [Habit]

    @State private var displayMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }()
    @State private var selectedDay: Date? = nil

    private let cal = Calendar.current
    private var actionable: [Habit] { habits.filter { $0.quadrant.needsDesign } }

    private var canGoForward: Bool {
        let next = cal.date(byAdding: .month, value: 1, to: displayMonth)!
        let current = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
        return next <= current
    }

    var body: some View {
        NavigationStack {
            List {
                calendarSection
                if let day = selectedDay {
                    dayDetailSection(for: day)
                }
                if !actionable.isEmpty {
                    monthlyStatsSection
                }
            }
            .navigationTitle("돌아보기")
        }
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        Section {
            HStack {
                Button {
                    displayMonth = cal.date(byAdding: .month, value: -1, to: displayMonth)!
                    selectedDay = nil
                } label: {
                    Image(systemName: "chevron.left").fontWeight(.semibold)
                }
                .buttonStyle(.plain)

                Spacer()
                Text(monthTitle).font(.headline)
                Spacer()

                Button {
                    if canGoForward {
                        displayMonth = cal.date(byAdding: .month, value: 1, to: displayMonth)!
                        selectedDay = nil
                    }
                } label: {
                    Image(systemName: "chevron.right").fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .foregroundStyle(canGoForward ? Color.primary : Color(.tertiaryLabel))
            }
            .padding(.vertical, 4)

            CalendarGridView(
                month: displayMonth,
                habits: actionable,
                selectedDay: $selectedDay
            )
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 8, trailing: 12))
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: displayMonth)
    }

    // MARK: - Day detail

    private func dayDetailSection(for date: Date) -> some View {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"

        return Section(f.string(from: date)) {
            if actionable.isEmpty {
                Text("활성 습관이 없습니다").foregroundStyle(.secondary)
            } else {
                ForEach(actionable) { habit in
                    let hasLog = habit.logs.contains {
                        $0.completed && cal.isDate($0.date, inSameDayAs: date)
                    }
                    let isBreak = habit.quadrant == .breakIt
                    // breakIt: hasLog = 실수, no log = 지킴
                    // keep/build: hasLog = 완료, no log = 미완료
                    let isGood = isBreak ? !hasLog : hasLog
                    HStack(spacing: 10) {
                        Image(systemName: isBreak
                              ? (hasLog ? "xmark.circle.fill" : "shield.fill")
                              : (hasLog ? "checkmark.circle.fill" : "circle"))
                            .foregroundStyle(isGood
                                ? (isBreak ? Color.green : habit.quadrant.color)
                                : (isBreak ? Color.red   : Color(.tertiaryLabel)))
                        Text(habit.name)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(isBreak ? (hasLog ? "실수" : "지킴") : (hasLog ? "완료" : "미완료"))
                            .font(.caption)
                            .foregroundStyle(isGood ? Color.secondary : (isBreak ? Color.red : Color(.tertiaryLabel)))
                    }
                }
            }
        }
    }

    // MARK: - Monthly stats

    private var monthlyStatsSection: some View {
        Section {
            ForEach(actionable) { habit in
                let rate = monthlyRate(for: habit)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle().fill(habit.quadrant.color).frame(width: 8, height: 8)
                        Text(habit.name).font(.subheadline)
                        Spacer()
                        Text("\(Int(rate * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(rate >= 0.7 ? habit.quadrant.color : Color.secondary)
                    }
                    ProgressView(value: rate).tint(habit.quadrant.color)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("이번 달 완료율")
        } footer: {
            Text("완료율이 70% 아래면 설계를 더 작게 쪼개보세요.")
        }
    }

    private func monthlyRate(for habit: Habit) -> Double {
        let comps = cal.dateComponents([.year, .month], from: displayMonth)
        let startOfMonth = cal.date(from: comps)!
        let range = cal.range(of: .day, in: .month, for: startOfMonth)!
        let today = cal.startOfDay(for: Date())
        guard let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { return 0 }
        let effectiveEnd = min(today, endOfMonth)
        let daysPassed = max(1, (cal.dateComponents([.day], from: startOfMonth, to: effectiveEnd).day ?? 0) + 1)
        _ = range.count

        let completedDays = Set(
            habit.logs
                .filter { $0.completed }
                .map { cal.startOfDay(for: $0.date) }
                .filter { day in
                    let dc = cal.dateComponents([.year, .month], from: day)
                    return dc.year == comps.year && dc.month == comps.month
                }
        ).count
        return Double(completedDays) / Double(daysPassed)
    }
}

// MARK: - Calendar grid

private struct CalendarGridView: View {
    let month: Date
    let habits: [Habit]
    @Binding var selectedDay: Date?

    private let cal = Calendar.current
    private let weekdays = ["월", "화", "수", "목", "금", "토", "일"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { d in
                    Text(d)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(calendarDays, id: \.self) { date in
                    DayCell(
                        date: date,
                        isCurrentMonth: isCurrentMonth(date),
                        isToday: cal.isDateInToday(date),
                        isSelected: selectedDay.map { cal.isDate($0, inSameDayAs: date) } ?? false,
                        isFuture: date > cal.startOfDay(for: Date()),
                        dots: dots(for: date)
                    )
                    .onTapGesture {
                        guard date <= cal.startOfDay(for: Date()), isCurrentMonth(date) else { return }
                        if let sel = selectedDay, cal.isDate(sel, inSameDayAs: date) {
                            selectedDay = nil
                        } else {
                            selectedDay = date
                        }
                    }
                }
            }
        }
    }

    private var calendarDays: [Date] {
        let comps = cal.dateComponents([.year, .month], from: month)
        let start = cal.date(from: comps)!
        let firstWeekday = cal.component(.weekday, from: start)
        let leading = (firstWeekday - 2 + 7) % 7
        let gridStart = cal.date(byAdding: .day, value: -leading, to: start)!
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        let mc = cal.dateComponents([.year, .month], from: month)
        let dc = cal.dateComponents([.year, .month], from: date)
        return mc.year == dc.year && mc.month == dc.month
    }

    private func dots(for date: Date) -> [Color] {
        habits.compactMap { habit -> Color? in
            let hasLog = habit.logs.contains { $0.completed && cal.isDate($0.date, inSameDayAs: date) }
            if habit.quadrant == .breakIt {
                return hasLog ? .red : nil      // 빨간 점 = 실수한 날
            } else {
                return hasLog ? habit.quadrant.color : nil  // 색상 점 = 완료한 날
            }
        }
    }
}

// MARK: - Day cell

private struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isFuture: Bool
    let dots: [Color]

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 3) {
            Text("\(cal.component(.day, from: date))")
                .font(.caption.monospacedDigit())
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : Color.primary))
                .frame(width: 26, height: 22)
                .background(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.12) : Color.clear))
                .clipShape(RoundedRectangle(cornerRadius: 5))

            HStack(spacing: 2) {
                ForEach(Array(dots.prefix(3).enumerated()), id: \.offset) { _, color in
                    Circle().fill(color).frame(width: 4, height: 4)
                }
                if dots.count > 3 {
                    Circle().fill(Color.secondary).frame(width: 4, height: 4)
                }
            }
            .frame(height: 5)
        }
        .opacity(!isCurrentMonth || isFuture ? 0.25 : 1)
    }
}
