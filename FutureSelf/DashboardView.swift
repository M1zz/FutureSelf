//
//  DashboardView.swift
//  Today: do-habits to check off + break-habits to guard all day.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context

    @Query(filter: #Predicate<Habit> { $0.isArchived == false },
           sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @Query(filter: #Predicate<IdentityStatement> { $0.isPrimary == true })
    private var identities: [IdentityStatement]

    // keep / build: need to be checked off
    private var doHabits: [Habit]    { habits.filter { $0.quadrant == .keep || $0.quadrant == .build } }
    private var pending: [Habit]     { doHabits.filter { !isCompletedToday($0) } }
    private var completed: [Habit]   { doHabits.filter {  isCompletedToday($0) } }

    // breakIt: should NOT be done — track slips
    private var breakItHabits: [Habit] { habits.filter { $0.quadrant == .breakIt } }

    var body: some View {
        NavigationStack {
            List {
                summarySection
                if !pending.isEmpty   { pendingSection }
                if !breakItHabits.isEmpty { breakItSection }
                if !completed.isEmpty { completedSection }
                if doHabits.isEmpty && breakItHabits.isEmpty {
                    ContentUnavailableView(
                        "오늘 할 습관이 없습니다",
                        systemImage: "tray",
                        description: Text("매트릭스에서 습관을 추가하거나 분류하세요.")
                    )
                }
            }
            .navigationTitle("오늘")
            .navigationDestination(for: Habit.self) { HabitDesignerView(habit: $0) }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                if let identity = identities.first {
                    Text(identity.statement)
                        .font(.subheadline.weight(.semibold))
                }

                if !doHabits.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView(value: Double(completed.count), total: Double(doHabits.count))
                            .tint(.green)
                        Text("\(completed.count) / \(doHabits.count) 완료")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                if !breakItHabits.isEmpty {
                    let slipped = breakItHabits.filter { isCompletedToday($0) }.count
                    let maintained = breakItHabits.count - slipped
                    HStack(spacing: 6) {
                        Image(systemName: slipped == 0 ? "shield.fill" : "shield.slash.fill")
                            .font(.caption)
                            .foregroundStyle(slipped == 0 ? .green : .red)
                        Text(slipped == 0
                             ? "끊어내기 \(maintained)개 — 오늘도 잘 버티는 중"
                             : "끊어내기 \(maintained)개 유지, \(slipped)개 실수")
                            .font(.caption)
                            .foregroundStyle(slipped == 0 ? Color.secondary : Color.red)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Do-habits (keep / build)

    private var pendingSection: some View {
        Section("오늘 할 일") {
            ForEach(pending) { habit in
                HabitProgressRow(habit: habit) { toggle(habit) }
            }
        }
    }

    private var completedSection: some View {
        Section("완료") {
            ForEach(completed) { habit in
                HabitProgressRow(habit: habit) { toggle(habit) }
            }
        }
    }

    // MARK: - Break-habits (avoid all day)

    private var breakItSection: some View {
        Section {
            ForEach(breakItHabits) { habit in
                BreakItRow(habit: habit) { toggle(habit) }
            }
        } header: {
            Text("끊어내기 — 오늘 하루")
        } footer: {
            Text("실수했다면 솔직하게 기록하세요. 기록이 쌓여야 패턴이 보입니다.")
        }
    }

    // MARK: - Helpers

    private func isCompletedToday(_ habit: Habit) -> Bool {
        let cal = Calendar.current
        return habit.logs.contains { $0.completed && cal.isDate($0.date, inSameDayAs: Date()) }
    }

    private func toggle(_ habit: Habit) {
        let cal = Calendar.current
        if let existing = habit.logs.first(where: { cal.isDate($0.date, inSameDayAs: Date()) }) {
            context.delete(existing)
        } else {
            let log = HabitLog(date: Date(), completed: true)
            log.habit = habit
            context.insert(log)
        }
        try? context.save()
    }
}

// MARK: - Do-habit row (keep / build)

private struct HabitProgressRow: View {
    let habit: Habit
    let onToggle: () -> Void

    private var isCompletedToday: Bool {
        let cal = Calendar.current
        return habit.logs.contains { $0.completed && cal.isDate($0.date, inSameDayAs: Date()) }
    }

    private var stage: (label: String, color: Color) {
        if habit.designCompleteness < 0.5 { return ("설계 필요", .orange) }
        let s = habit.streak()
        switch s {
        case 0:      return ("시작 전",    .gray)
        case 1..<7:  return ("\(s)일 연속", .blue)
        case 7..<21: return ("\(s)일 연속", .teal)
        default:     return ("\(s)일 연속", .green)
        }
    }

    private var actionHint: String {
        if habit.designCompleteness < 0.5 { return "설계를 완성하면 실행 확률이 올라갑니다" }
        if !habit.hasPrompt { return "언제·어디서 할지 신호를 설정하세요" }
        if habit.ability <= 3 { return "더 작게 쪼개거나 마찰을 줄이세요" }
        if habit.motivation <= 3 { return "매력을 높이거나 더 쉽게 만드세요" }
        let s = habit.streak()
        if s == 0  { return "오늘 첫 실행으로 시작해보세요" }
        if s < 7   { return "7일까지 \(7 - s)일 남았습니다" }
        if s < 21  { return "21일까지 \(21 - s)일 남았습니다" }
        return "\(s)일 연속 — 자동화 단계입니다"
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompletedToday ? habit.quadrant.color : Color.secondary)
            }
            .buttonStyle(.plain)

            NavigationLink(value: habit) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .foregroundStyle(isCompletedToday ? Color.secondary : Color.primary)
                        StagePill(label: stage.label, color: stage.color)
                    }
                    Text(actionHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Break-habit row (avoid all day)

private struct BreakItRow: View {
    let habit: Habit
    let onToggle: () -> Void

    private var slippedToday: Bool {
        let cal = Calendar.current
        return habit.logs.contains { $0.completed && cal.isDate($0.date, inSameDayAs: Date()) }
    }

    private var cleanDays: Int {
        let cal = Calendar.current
        let slipDays = Set(habit.logs.filter { $0.completed }.map { cal.startOfDay(for: $0.date) })
        var count = 0
        var cursor = cal.startOfDay(for: Date())
        while !slipDays.contains(cursor) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
            if count > 365 { break }
        }
        return count
    }

    private var statusText: String {
        if slippedToday { return "오늘 실수를 기록했습니다" }
        if cleanDays <= 1 { return "오늘도 잘 버티는 중" }
        return "\(cleanDays)일째 지키는 중"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: slippedToday ? "xmark.circle.fill" : "shield.fill")
                .font(.title2)
                .foregroundStyle(slippedToday ? Color.red : Color.green)

            NavigationLink(value: habit) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .foregroundStyle(Color.primary)
                        .strikethrough(slippedToday, color: .red)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(slippedToday ? Color.red : Color.secondary)
                }
            }

            Spacer()

            Button(slippedToday ? "취소" : "실수 기록") { onToggle() }
                .font(.caption)
                .buttonStyle(.bordered)
                .tint(slippedToday ? Color.secondary : Color.red)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Stage pill

private struct StagePill: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
