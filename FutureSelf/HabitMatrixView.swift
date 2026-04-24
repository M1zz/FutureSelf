//
//  HabitMatrixView.swift
//  The core 2x2 audit screen: classify every habit, navigate into design.
//

import SwiftUI
import SwiftData

struct HabitMatrixView: View {
    @Query(filter: #Predicate<Habit> { $0.isArchived == false },
           sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    matrixGrid
                        .padding(.top, 4)
                    quadrantSections
                }
                .padding(12)
            }
            .navigationTitle("습관 매트릭스")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddHabitSheet()
            }
            .navigationDestination(for: Habit.self) { habit in
                HabitDesignerView(habit: habit)
            }
        }
    }

    // MARK: Grid

    private var matrixGrid: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Spacer().frame(width: 52)
                columnHeader("가지고 있다")
                columnHeader("가지고 있지 않다")
            }
            HStack(spacing: 4) {
                rowLabel("원함")
                MatrixCell(quadrant: .keep, count: count(for: .keep))
                MatrixCell(quadrant: .build, count: count(for: .build))
            }
            HStack(spacing: 4) {
                rowLabel("원하지\n않음")
                MatrixCell(quadrant: .breakIt, count: count(for: .breakIt))
                MatrixCell(quadrant: .ignore, count: count(for: .ignore))
            }
        }
    }

    private func columnHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(width: 52)
    }

    // MARK: Lists

    private var quadrantSections: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach([HabitQuadrant.keep, .build, .breakIt, .ignore], id: \.self) { q in
                let list = habits.filter { $0.quadrant == q }
                if !list.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Circle().fill(q.color).frame(width: 8, height: 8)
                            Text(q.title).font(.headline)
                            Text("\(list.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(q.goal)
                                .font(.caption)
                                .foregroundStyle(q == .keep || q == .ignore ? .secondary : q.color)
                        }
                        ForEach(list) { habit in
                            NavigationLink(value: habit) {
                                HabitRow(habit: habit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if habits.isEmpty {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("먼저 지금의 습관을 꺼내 놓으세요")
                .font(.headline)
            Text("있는 것, 없는 것을 구분 없이 떠오르는 대로 적어두고,\n그 다음에 매트릭스로 분류합니다.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showingAdd = true
            } label: {
                Label("습관 추가", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func count(for q: HabitQuadrant) -> Int {
        habits.filter { $0.quadrant == q }.count
    }
}

// MARK: - Matrix cell

private struct MatrixCell: View {
    let quadrant: HabitQuadrant
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(quadrant.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(quadrant.color)
                .lineLimit(1)
            Text("\(count)개")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            Text(quadrant.strategy)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .padding(8)
        .background(quadrant.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Habit row (used in quadrant lists)

private struct HabitRow: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(habit.quadrant.color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .foregroundStyle(.primary)
                if let anchor = habit.anchorHabit, !anchor.isEmpty,
                   let tiny = habit.tinyVersion, !tiny.isEmpty {
                    Text("\(anchor) 후에 \(tiny)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text("\(Int(habit.designCompleteness * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Add habit sheet

struct AddHabitSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var quadrant: HabitQuadrant = .build

    var body: some View {
        NavigationStack {
            Form {
                Section("습관") {
                    TextField("예: 아침 30분 산책, 자기 전 릴스 보기", text: $name)
                }
                Section {
                    ForEach(HabitQuadrant.allCases) { q in
                        Button {
                            quadrant = q
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: quadrant == q ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(q.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(q.title).foregroundStyle(.primary)
                                    Text(q.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("분류")
                } footer: {
                    Text("지금 상태 + 원하는 방향으로 먼저 나눈 다음, 상세 설계는 저장 후 진행합니다.")
                }
            }
            .navigationTitle("새 습관")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let habit = Habit(name: name.trimmingCharacters(in: .whitespaces),
                          quadrant: quadrant)
        context.insert(habit)
        try? context.save()
        dismiss()
    }
}
