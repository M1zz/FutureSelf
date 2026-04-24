//
//  RootView.swift
//  Gates onboarding, then shows the main tab interface.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Query(filter: #Predicate<IdentityStatement> { $0.isPrimary == true })
    private var primaryIdentities: [IdentityStatement]

    var body: some View {
        if primaryIdentities.isEmpty {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

// MARK: - Main tabs

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("오늘", systemImage: "sun.max") }

            HabitMatrixView()
                .tabItem { Label("매트릭스", systemImage: "square.grid.2x2") }

            ReflectionView()
                .tabItem { Label("돌아보기", systemImage: "book.closed") }
        }
    }
}

// MARK: - Onboarding: capture the identity statement first

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var statement: String = "나는 "
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("시작은 정체성에서")
                            .font(.largeTitle.bold())
                        Text("습관은 목표가 아니라 사람을 만듭니다.\n되고 싶은 모습을 한 문장으로 적어보세요.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("예시")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                        Text("나는 매일 몸을 움직이는 사람이다.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("나는 깊이 집중하는 개발자다.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    TextEditor(text: $statement)
                        .focused($focused)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("시작하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(statement.trimmingCharacters(in: .whitespacesAndNewlines).count < 4)
                .padding(24)
                .background(.bar)
            }
            .onAppear { focused = true }
        }
    }

    private func save() {
        let trimmed = statement.trimmingCharacters(in: .whitespacesAndNewlines)
        let identity = IdentityStatement(statement: trimmed, isPrimary: true)
        context.insert(identity)
        try? context.save()
    }
}
