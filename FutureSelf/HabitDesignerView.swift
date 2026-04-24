//
//  HabitDesignerView.swift
//  Step-by-step habit design wizard. One concept per screen.
//

import SwiftUI
import SwiftData

struct HabitDesignerView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var context
    @Query private var identities: [IdentityStatement]
    @State private var stepIndex = 0

    // MARK: - Step model

    private enum Step: Equatable {
        case basics
        case law(HabitFormulas.Law)
        case execution
        case diagnosis
    }

    private var steps: [Step] {
        switch habit.quadrant {
        case .ignore:
            return [.basics]
        case .breakIt:
            return [.basics] + HabitFormulas.Law.allCases.map { .law($0) } + [.diagnosis]
        default:
            return [.basics] + HabitFormulas.Law.allCases.map { .law($0) } + [.execution, .diagnosis]
        }
    }

    private var currentStep: Step { steps[stepIndex] }
    private var isLastStep: Bool  { stepIndex == steps.count - 1 }

    private func stepTitle(_ s: Step) -> String {
        switch s {
        case .basics:        return "기본 정보"
        case .law(let law):  return habit.quadrant == .breakIt ? law.titleForBreak : law.titleForBuild
        case .execution:     return "실행 계획"
        case .diagnosis:     return "진단"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            stepHeader
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color(.systemGroupedBackground))

            Form {
                stepContent
                if isLastStep { dangerZoneSection }
            }
            .id(stepIndex)
        }
        .navigationTitle(habit.name.isEmpty ? "습관" : habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { navBar }
        .onChange(of: habit.quadrant) {
            stepIndex = min(stepIndex, steps.count - 1)
        }
    }

    // MARK: - Step header

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stepTitle(currentStep))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(stepIndex + 1) / \(steps.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(stepIndex + 1), total: Double(steps.count))
                .tint(.accentColor)
        }
    }

    // MARK: - Bottom nav

    private var navBar: some View {
        HStack(spacing: 12) {
            if stepIndex > 0 {
                Button("이전") { stepIndex -= 1 }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
            if !isLastStep {
                Button("다음") { stepIndex += 1 }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // MARK: - Step content router

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .basics:
            basicSection
            quadrantSection
        case .law(let law):
            lawSection(for: law)
        case .execution:
            tinyHabitSection
            implementationIntentionSection
        case .diagnosis:
            foggSection
            completenessSection
        }
    }

    // MARK: - Basics

    private var basicSection: some View {
        Section {
            TextField("이름", text: $habit.name)
            if !identities.isEmpty {
                Picker("정체성 연결", selection: linkedIdentityBinding) {
                    Text("연결 안 함").tag("")
                    ForEach(identities) { identity in
                        Text(identity.statement).tag(identity.statement)
                    }
                }
                .pickerStyle(.menu)
            }
        } header: {
            Text("기본")
        } footer: {
            if habit.linkedIdentity != nil {
                Text("이 습관은 선택한 정체성에 대한 표 한 장입니다. 체크할 때마다 그 사람에 가까워집니다.")
            } else {
                Text("정체성을 연결하면 '해야 해서'가 아니라 '나는 그런 사람이라서' 실행하게 됩니다.")
            }
        }
    }

    private var quadrantSection: some View {
        Section {
            Picker("분류", selection: $habit.quadrant) {
                ForEach(HabitQuadrant.allCases) { q in
                    Label(q.title, systemImage: q.iconName).tag(q)
                }
            }
            .pickerStyle(.menu)
            HStack(spacing: 8) {
                Image(systemName: habit.quadrant.iconName)
                    .foregroundStyle(habit.quadrant.color)
                Text(habit.quadrant.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text(quadrantHint)
        }
    }

    // MARK: - Law (one per step)

    private func lawSection(for law: HabitFormulas.Law) -> some View {
        let title = habit.quadrant == .breakIt ? law.titleForBreak : law.titleForBuild
        let reason = lawReason(for: law)
        let placeholder = law.prompt(for: habit.quadrant)

        return Group {
            Section {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.footnote)
                        .padding(.top, 1)
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.yellow.opacity(0.07))
            }

            Section {
                TextField(placeholder, text: binding(for: law), axis: .vertical)
                    .lineLimit(2...6)
            } header: {
                Text(title)
            } footer: {
                Text(lawFooter(for: law))
            }
        }
    }

    private func lawReason(for law: HabitFormulas.Law) -> String {
        if habit.quadrant == .breakIt {
            switch law {
            case .cue:
                return "신호를 보는 순간 저항하기 어렵습니다. 눈에 보이지 않으면 의지력 없이도 실행을 막을 수 있습니다."
            case .craving:
                return "하고 싶다는 느낌이 습관을 유지시킵니다. 그 느낌의 근거를 제거하면 욕구 자체가 줄어듭니다."
            case .response:
                return "마찰이 생기면 귀찮아서 안 하게 됩니다. 단 몇 걸음만 더 필요해도 실행률이 크게 떨어집니다."
            case .reward:
                return "보상이 사라지면 반복할 이유가 없어집니다. 결과의 비용을 눈에 보이게 하면 욕구를 억제할 수 있습니다."
            }
        } else {
            switch law {
            case .cue:
                return "신호가 없으면 아무리 좋은 의도도 실행으로 이어지지 않습니다. 뇌는 명확한 트리거가 있을 때만 행동을 시작합니다."
            case .craving:
                return "동기는 의지로 만들어지지 않습니다. 실행 자체가 매력적으로 느껴질 때 억지 없이 자발적으로 하게 됩니다."
            case .response:
                return "시작하는 것이 가장 어렵습니다. 2분이면 누구나 할 수 있고, 일단 시작하면 대부분 계속 이어집니다."
            case .reward:
                return "뇌는 즉각적인 보상을 기억합니다. 실행 직후의 작은 만족감이 '다음에도 하고 싶다'는 회로를 만듭니다."
            }
        }
    }

    private func lawFooter(for law: HabitFormulas.Law) -> String {
        if habit.quadrant == .breakIt {
            switch law {
            case .cue:      return "예: 과자를 눈에 안 보이는 서랍에, SNS 앱을 두 번째 폴더로"
            case .craving:  return "예: 실제 비용·시간 낭비를 시각화해 기록"
            case .response: return "예: 앱 삭제, 비밀번호 20자리, 물리적 장벽 추가"
            case .reward:   return "예: 했을 때 불쾌한 결과를 책임 파트너에게 공개"
            }
        } else {
            switch law {
            case .cue:      return "예: 양치 직후, 커피 머신 앞, 알람 소리"
            case .craving:  return "예: 좋아하는 팟캐스트는 운동 중에만, 예쁜 노트 구입"
            case .response: return "예: 운동 → 운동화만 신기, 독서 → 책 한 줄만"
            case .reward:   return "예: 체크 표시, 차 한 잔, 스트릭 카운터 확인"
            }
        }
    }

    // MARK: - Execution

    private var tinyHabitSection: some View {
        Section {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.footnote)
                    .padding(.top, 1)
                Text("기존에 이미 하는 행동 뒤에 새 습관을 붙이면, 별도의 의지력 없이 자연스럽게 실행 타이밍이 생깁니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.yellow.opacity(0.07))

            TextField("기존 습관 (After I…)", text: Binding(
                get: { habit.anchorHabit ?? "" },
                set: { habit.anchorHabit = $0 }
            ))
            TextField("2분 이내 작은 행동 (I will…)", text: Binding(
                get: { habit.tinyVersion ?? "" },
                set: { habit.tinyVersion = $0 }
            ))
            Text(HabitFormulas.tinyHabitRecipe(anchor: habit.anchorHabit, tiny: habit.tinyVersion))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        } header: {
            Text("Tiny Habits — 기존 습관에 붙이기")
        } footer: {
            Text("새 습관은 2분 이내 버전부터 시작하세요. 너무 크면 시작 자체가 장벽이 됩니다.")
        }
    }

    private var implementationIntentionSection: some View {
        Section {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.footnote)
                    .padding(.top, 1)
                Text("'하고 싶을 때 하겠다'는 막연한 계획보다 '언제, 어디서'를 구체적으로 정해두면 실제 실행 확률이 2배 이상 높아집니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.yellow.opacity(0.07))

            DatePicker("시간", selection: Binding(
                get: { habit.timeOfDay ?? Date() },
                set: { habit.timeOfDay = $0 }
            ), displayedComponents: .hourAndMinute)

            TextField("장소", text: Binding(
                get: { habit.locationContext ?? "" },
                set: { habit.locationContext = $0 }
            ))
        } header: {
            Text("언제·어디서")
        } footer: {
            Text(HabitFormulas.implementationIntention(
                behavior: habit.name,
                time: habit.timeOfDay,
                location: habit.locationContext
            ))
        }
    }

    // MARK: - Diagnosis

    private var foggSection: some View {
        Section {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.footnote)
                    .padding(.top, 1)
                Text("Fogg의 B=MAP 모델: 행동은 동기(M)·능력(A)·신호(P)가 동시에 충족될 때 일어납니다. 하나라도 부족하면 실행이 무너집니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.yellow.opacity(0.07))

            Stepper("동기 \(habit.motivation) / 10", value: $habit.motivation, in: 1...10)
            Stepper("능력(쉬움) \(habit.ability) / 10", value: $habit.ability, in: 1...10)
            Toggle("신호(프롬프트) 있음", isOn: $habit.hasPrompt)
        } header: {
            Text("실행 가능성 점검")
        } footer: {
            Text(HabitFormulas.foggDiagnosis(
                motivation: habit.motivation,
                ability: habit.ability,
                hasPrompt: habit.hasPrompt
            ))
        }
    }

    private var completenessSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("설계 완성도")
                    Spacer()
                    Text("\(Int(habit.designCompleteness * 100))%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: habit.designCompleteness)
                    .tint(habit.quadrant.color)
            }
        }
    }

    // MARK: - Danger zone

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                habit.isArchived = true
                try? context.save()
            } label: {
                Label("보관하기", systemImage: "archivebox")
            }
        }
    }

    // MARK: - Helpers

    private var linkedIdentityBinding: Binding<String> {
        Binding(
            get: { habit.linkedIdentity ?? "" },
            set: { habit.linkedIdentity = $0.isEmpty ? nil : $0 }
        )
    }

    private func binding(for law: HabitFormulas.Law) -> Binding<String> {
        switch law {
        case .cue:      return .init(get: { habit.cue ?? "" },      set: { habit.cue = $0 })
        case .craving:  return .init(get: { habit.craving ?? "" },  set: { habit.craving = $0 })
        case .response: return .init(get: { habit.response ?? "" }, set: { habit.response = $0 })
        case .reward:   return .init(get: { habit.reward ?? "" },   set: { habit.reward = $0 })
        }
    }

    private var quadrantHint: String {
        switch habit.quadrant {
        case .keep:    return "이미 하고 있고 계속 하고 싶은 습관. 조건을 더 자동화하세요."
        case .build:   return "아직 없지만 원하는 습관. 작게 시작하고 기존 습관에 붙이세요."
        case .breakIt: return "하고 있지만 그만두고 싶은 습관. 신호·보상을 뒤집으세요."
        case .ignore:  return "신경 쓰지 않아도 되는 영역. 별도 설계는 생략합니다."
        }
    }
}
