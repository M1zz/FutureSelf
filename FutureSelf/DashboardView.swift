//
//  DashboardView.swift
//  Today: habit formation progress stages and action items.
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

    private var actionable: [Habit] { habits.filter { $0.quadrant.needsDesign } }
    private var pending: [Habit]   { actionable.filter { !isCompletedToday($0) } }
    private var completed: [Habit] { actionable.filter {  isCompletedToday($0) } }

    var body: some View {
        NavigationStack {
            List {
                summarySection
                if !pending.isEmpty   { pendingSection }
                if !completed.isEmpty { completedSection }
                if actionable.isEmpty {
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

    // MARK: - Sections

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                if let identity = identities.first {
                    Text(identity.statement)
                        .font(.subheadline.weight(.semibold))
                }
                HStack(spacing: 10) {
                    ProgressView(
                        value: actionable.isEmpty ? 0 : Double(completed.count) / Double(actionable.count)
                    )
                    .tint(.green)
                    Text("\(completed.count) / \(actionable.count) 완료")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

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

// MARK: - Row

private struct HabitProgressRow: View {
    let habit: Habit
    let onToggle: () -> Void

    private var isCompletedToday: Bool {
        let cal = Calendar.current
        return habit.logs.contains { $0.completed && cal.isDate($0.date, inSameDayAs: Date()) }
    }

    private var stage: (label: String, color: Color) {
        if habit.designCompleteness < 0.5 {
            return ("설계 필요", .orange)
        }
        let s = habit.streak()
        switch s {
        case 0:       return ("시작 전",   .gray)
        case 1..<7:   return ("\(s)일 연속", .blue)
        case 7..<21:  return ("\(s)일 연속", .teal)
        default:      return ("\(s)일 연속", .green)
        }
    }

    private var actionHint: String {
        if habit.designCompleteness < 0.5 {
            return "설계를 완성하면 실행 확률이 올라갑니다"
        }
        if !habit.hasPrompt { return "언제·어디서 할지 신호를 설정하세요" }
        if habit.ability < 4 { return "더 작게 쪼개거나 마찰을 줄이세요" }
        if habit.motivation < 4 { return "매력을 높이거나 더 쉽게 만드세요" }
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
                    .foregroundStyle(isCompletedToday ? habit.quadrant.color : .secondary)
            }
            .buttonStyle(.plain)

            NavigationLink(value: habit) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .foregroundStyle(isCompletedToday ? .secondary : .primary)
                            .strikethrough(isCompletedToday && habit.quadrant == .breakIt)
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
