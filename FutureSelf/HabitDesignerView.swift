//
//  HabitDesignerView.swift
//  Progressive habit design: fill in only what you need, when you need it.
//

import SwiftUI
import SwiftData

struct HabitDesignerView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var context
    @Query private var identities: [IdentityStatement]
    @State private var showArchiveConfirm = false

    var body: some View {
        Form {
            basicSection
            quadrantSection
            if habit.quadrant != .ignore {
                nextStepSection
                designSection
                checkSection
            }
            dangerZoneSection
        }
        .navigationTitle(habit.name.isEmpty ? "습관" : habit.name)
        .navigationBarTitleDisplayMode(.inline)
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
                Image(systemName: habit.quadrant.iconName).foregroundStyle(habit.quadrant.color)
                Text(habit.quadrant.subtitle).font(.footnote).foregroundStyle(.secondary)
            }
        } footer: {
            Text(quadrantHint)
        }
    }

    // MARK: - Next step banner

    private var nextStepSection: some View {
        Section {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.subheadline)
                Text(nextStepText)
                    .font(.subheadline)
            }
            .padding(.vertical, 2)
        } header: {
            Text("지금 할 것")
        }
    }

    private var nextStepText: String {
        if !habit.hasPrompt || (habit.cue ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "먼저 신호(언제, 어디서)를 정하세요. 신호가 없으면 아무리 좋은 의도도 실행으로 이어지지 않습니다."
        }
        if habit.ability <= 3 {
            return "너무 어렵게 느껴집니다. '2분 버전'으로 더 작게 쪼개보세요."
        }
        if habit.motivation <= 3 {
            return "하고 싶은 마음이 낮습니다. '매력 높이기'를 점검해보세요."
        }
        if (habit.anchorHabit ?? "").isEmpty {
            return "기존 습관에 붙일 수 있다면 실행 확률이 크게 올라갑니다. '2분 버전'을 열어보세요."
        }
        return "설계가 잘 돼 있습니다. 꾸준히 체크하며 쌓아가세요."
    }

    // MARK: - Design elements (expandable, fill only what you need)

    private var designSection: some View {
        Section {
            ForEach(HabitFormulas.Law.allCases) { law in
                lawDisclosure(for: law)
            }
            if habit.quadrant != .breakIt {
                tinyHabitDisclosure
                scheduleDisclosure
            }
        } header: {
            Text("설계 현황")
        } footer: {
            Text("안 되는 게 생기면 해당 항목만 열어서 채워보세요. 전부 채울 필요는 없습니다.")
        }
    }

    private func lawDisclosure(for law: HabitFormulas.Law) -> some View {
        let title   = habit.quadrant == .breakIt ? law.titleForBreak : law.titleForBuild
        let current = currentValue(for: law)
        let isEmpty = current.isEmpty

        return DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text(lawReason(for: law))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
                TextField(
                    law.prompt(for: habit.quadrant),
                    text: binding(for: law),
                    axis: .vertical
                )
                .lineLimit(2...5)
                Text(lawExample(for: law))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(isEmpty ? Color(.tertiarySystemFill) : habit.quadrant.color)
                    .frame(width: 8, height: 8)
                Text(title)
                Spacer()
                Text(isEmpty ? "미설정" : current)
                    .font(.caption)
                    .foregroundStyle(isEmpty ? .tertiary : .secondary)
                    .lineLimit(1)
            }
        }
    }

    private var tinyHabitDisclosure: some View {
        let anchorSet = !(habit.anchorHabit ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let tinySet   = !(habit.tinyVersion  ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isEmpty   = !anchorSet && !tinySet

        return DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text("기존에 이미 하는 행동 뒤에 새 습관을 붙이면, 별도의 의지력 없이 타이밍이 생깁니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
                TextField("기존 습관 (After I…)", text: Binding(
                    get: { habit.anchorHabit ?? "" },
                    set: { habit.anchorHabit = $0 }
                ))
                TextField("2분 이내 버전 (I will…)", text: Binding(
                    get: { habit.tinyVersion ?? "" },
                    set: { habit.tinyVersion = $0 }
                ))
                if anchorSet || tinySet {
                    Text(HabitFormulas.tinyHabitRecipe(anchor: habit.anchorHabit, tiny: habit.tinyVersion))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(isEmpty ? Color(.tertiarySystemFill) : habit.quadrant.color)
                    .frame(width: 8, height: 8)
                Text("2분 버전 — 기존 습관에 붙이기")
                Spacer()
                Text(isEmpty ? "미설정" : "설정됨")
                    .font(.caption)
                    .foregroundStyle(isEmpty ? .tertiary : .secondary)
            }
        }
    }

    private var scheduleDisclosure: some View {
        let timeSet     = habit.timeOfDay != nil
        let locationSet = !(habit.locationContext ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isEmpty     = !timeSet && !locationSet

        return DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text("'하고 싶을 때 하겠다'는 계획보다 시간과 장소를 구체적으로 정해두면 실행 확률이 2배 이상 높아집니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
                DatePicker("시간", selection: Binding(
                    get: { habit.timeOfDay ?? Date() },
                    set: { habit.timeOfDay = $0 }
                ), displayedComponents: .hourAndMinute)
                TextField("장소", text: Binding(
                    get: { habit.locationContext ?? "" },
                    set: { habit.locationContext = $0 }
                ))
            }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(isEmpty ? Color(.tertiarySystemFill) : habit.quadrant.color)
                    .frame(width: 8, height: 8)
                Text("실행 시간·장소")
                Spacer()
                Text(isEmpty ? "미설정" : "설정됨")
                    .font(.caption)
                    .foregroundStyle(isEmpty ? .tertiary : .secondary)
            }
        }
    }

    // MARK: - Check (Fogg, simplified)

    private var checkSection: some View {
        Section {
            // 동기
            VStack(alignment: .leading, spacing: 8) {
                Text("이 습관, 하고 싶은 마음이 있나요?")
                    .font(.subheadline)
                Picker("동기", selection: motivationBinding) {
                    Text("별로 없다").tag(2)
                    Text("조금 있다").tag(5)
                    Text("충분하다").tag(9)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)

            // 능력
            VStack(alignment: .leading, spacing: 8) {
                Text("지금 바로 할 수 있을 만큼 쉬운가요?")
                    .font(.subheadline)
                Picker("능력", selection: abilityBinding) {
                    Text("너무 어렵다").tag(2)
                    Text("적당하다").tag(5)
                    Text("매우 쉽다").tag(9)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)

            // 신호
            Toggle("언제 할지 정해져 있나요?", isOn: $habit.hasPrompt)
        } header: {
            Text("지금 상태 점검")
        } footer: {
            Text(HabitFormulas.foggDiagnosis(
                motivation: habit.motivation,
                ability: habit.ability,
                hasPrompt: habit.hasPrompt
            ))
        }
    }

    // MARK: - Danger zone

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showArchiveConfirm = true
            } label: {
                Label("보관하기", systemImage: "archivebox")
            }
        } footer: {
            Text("보관된 습관은 매트릭스 하단에서 복원할 수 있습니다.")
        }
        .alert("습관을 보관할까요?", isPresented: $showArchiveConfirm) {
            Button("보관하기", role: .destructive) {
                habit.isArchived = true
                try? context.save()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("오늘 탭과 매트릭스에서 숨겨집니다. 매트릭스 하단에서 언제든지 복원할 수 있습니다.")
        }
    }

    // MARK: - Helpers

    private var linkedIdentityBinding: Binding<String> {
        Binding(
            get: { habit.linkedIdentity ?? "" },
            set: { habit.linkedIdentity = $0.isEmpty ? nil : $0 }
        )
    }

    private var motivationBinding: Binding<Int> {
        Binding(
            get: {
                switch habit.motivation {
                case 1...3: return 2
                case 4...6: return 5
                default:    return 9
                }
            },
            set: { habit.motivation = $0 }
        )
    }

    private var abilityBinding: Binding<Int> {
        Binding(
            get: {
                switch habit.ability {
                case 1...3: return 2
                case 4...6: return 5
                default:    return 9
                }
            },
            set: { habit.ability = $0 }
        )
    }

    private func currentValue(for law: HabitFormulas.Law) -> String {
        switch law {
        case .cue:      return (habit.cue      ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .craving:  return (habit.craving  ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .response: return (habit.response ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .reward:   return (habit.reward   ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func binding(for law: HabitFormulas.Law) -> Binding<String> {
        switch law {
        case .cue:      return .init(get: { habit.cue      ?? "" }, set: { habit.cue      = $0 })
        case .craving:  return .init(get: { habit.craving  ?? "" }, set: { habit.craving  = $0 })
        case .response: return .init(get: { habit.response ?? "" }, set: { habit.response = $0 })
        case .reward:   return .init(get: { habit.reward   ?? "" }, set: { habit.reward   = $0 })
        }
    }

    private func lawReason(for law: HabitFormulas.Law) -> String {
        if habit.quadrant == .breakIt {
            switch law {
            case .cue:      return "신호를 보는 순간 저항하기 어렵습니다. 눈에 보이지 않으면 의지력 없이도 실행을 막을 수 있습니다."
            case .craving:  return "하고 싶다는 느낌이 습관을 유지시킵니다. 그 근거를 제거하면 욕구 자체가 줄어듭니다."
            case .response: return "마찰이 생기면 귀찮아서 안 하게 됩니다. 몇 걸음만 더 필요해도 실행률이 크게 떨어집니다."
            case .reward:   return "보상이 사라지면 반복할 이유가 없어집니다. 결과의 비용을 눈에 보이게 하면 욕구를 억제할 수 있습니다."
            }
        } else {
            switch law {
            case .cue:      return "신호가 없으면 좋은 의도도 실행으로 이어지지 않습니다. 뇌는 명확한 트리거가 있을 때만 행동을 시작합니다."
            case .craving:  return "동기는 의지로 만들어지지 않습니다. 실행 자체가 매력적으로 느껴질 때 자발적으로 하게 됩니다."
            case .response: return "시작하는 것이 가장 어렵습니다. 2분이면 누구나 할 수 있고, 시작하면 대부분 계속 이어집니다."
            case .reward:   return "뇌는 즉각적인 보상을 기억합니다. 실행 직후의 작은 만족감이 '다음에도 하고 싶다'는 회로를 만듭니다."
            }
        }
    }

    private func lawExample(for law: HabitFormulas.Law) -> String {
        if habit.quadrant == .breakIt {
            switch law {
            case .cue:      return "예: 과자를 서랍 안으로, SNS 앱을 두 번째 폴더로"
            case .craving:  return "예: 실제 비용·시간 낭비를 기록으로 시각화"
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

    private var quadrantHint: String {
        switch habit.quadrant {
        case .keep:    return "이미 하고 있고 계속 하고 싶은 습관. 조건을 더 자동화하세요."
        case .build:   return "아직 없지만 원하는 습관. 작게 시작하고 기존 습관에 붙이세요."
        case .breakIt: return "하고 있지만 그만두고 싶은 습관. 신호·보상을 뒤집으세요."
        case .ignore:  return "신경 쓰지 않아도 되는 영역. 별도 설계는 생략합니다."
        }
    }
}
