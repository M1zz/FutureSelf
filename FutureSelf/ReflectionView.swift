//
//  ReflectionView.swift
//  Weekly reflection: quadrant summary and 7-day completion strip per habit.
//

import SwiftUI
import SwiftData

struct ReflectionView: View {
    @Query(filter: #Predicate<Habit> { $0.isArchived == false })
    private var habits: [Habit]

    var body: some View {
        NavigationStack {
            List {
                Section("이번 주 구성") {
                    SummaryRow(title: "유지 중",     color: .green, count: count(.keep))
                    SummaryRow(title: "만드는 중",   color: .blue,  count: count(.build))
                    SummaryRow(title: "끊어내는 중", color: .red,   count: count(.breakIt))
                }

                Section {
                    ForEach(habits.filter { $0.quadrant.needsDesign }) { habit in
                        WeekStripRow(habit: habit)
                    }
                } header: {
                    Text("지난 7일")
                } footer: {
                    Text("완료율이 70% 아래로 떨어지면 습관이 너무 큽니다. 2분 이내로 더 쪼개보세요.")
                }
            }
            .navigationTitle("돌아보기")
        }
    }

    private func count(_ q: HabitQuadrant) -> Int {
        habits.filter { $0.quadrant == q }.count
    }
}

// MARK: - Summary row

private struct SummaryRow: View {
    let title: String
    let color: Color
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title)
            Spacer()
            Text("\(count)개")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

// MARK: - 7-day strip

private struct WeekStripRow: View {
    let habit: Habit

    private var days: [(Date, Bool)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset -> (Date, Bool)? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let done = habit.logs.contains { cal.isDate($0.date, inSameDayAs: day) && $0.completed }
            return (day, done)
        }
    }

    private var completionRate: Double {
        let done = days.filter { $0.1 }.count
        return Double(done) / 7.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(habit.name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(completionRate * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, entry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(entry.1 ? habit.quadrant.color : Color(.tertiarySystemFill))
                        .frame(height: 20)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
