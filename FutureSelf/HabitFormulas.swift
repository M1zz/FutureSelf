//
//  HabitFormulas.swift
//  Encodes habit design research as types and context-aware prompts.
//
//  References:
//    Clear, J. (2018). Atomic Habits. The Four Laws of Behavior Change.
//    Fogg, B. J. (2020). Tiny Habits. B = MAP and the anchor recipe.
//    Gollwitzer, P. M. (1999). Implementation intentions.
//

import Foundation

enum HabitFormulas {

    // MARK: - The Four Laws (Clear)

    enum Law: CaseIterable, Identifiable {
        case cue, craving, response, reward

        var id: String { String(describing: self) }

        var titleForBuild: String {
            switch self {
            case .cue:      return "언제·어디서 할지 정하기"
            case .craving:  return "하고 싶어지게 만들기"
            case .response: return "2분 이내로 줄이기"
            case .reward:   return "하자마자 보상 만들기"
            }
        }

        var titleForBreak: String {
            switch self {
            case .cue:      return "트리거 눈에서 치우기"
            case .craving:  return "매력 완전히 없애기"
            case .response: return "실행하기 어렵게 만들기"
            case .reward:   return "결과를 불쾌하게 만들기"
            }
        }

        /// Returns the guiding question shown inside each law's text field,
        /// tailored to whether you're building, keeping, or breaking.
        func prompt(for quadrant: HabitQuadrant) -> String {
            switch (self, quadrant) {
            case (.cue, .build), (.cue, .keep):
                return "언제, 어디서 이 행동의 신호를 받나요? 예: 양치 후 거울 볼 때"
            case (.cue, .breakIt):
                return "이 습관을 유발하는 신호를 어떻게 제거할까요? 예: 간식을 서랍에 넣기"
            case (.craving, .build), (.craving, .keep):
                return "하고 싶어지게 만드는 장치는? 예: 좋아하는 팟캐스트는 운동 중에만"
            case (.craving, .breakIt):
                return "이 습관의 매력을 떨어뜨리려면? 예: 실제 비용을 기록으로 시각화"
            case (.response, .build), (.response, .keep):
                return "2분짜리로 줄이면 무엇이 되나요? 마찰을 어디까지 줄일 수 있나요?"
            case (.response, .breakIt):
                return "실행을 어렵게 만들 물리적/디지털 장벽은? 예: 앱 삭제, 비번 20자"
            case (.reward, .build), (.reward, .keep):
                return "행동 직후 즉시 느낄 작은 보상은? 예: 체크 표시, 차 한 잔"
            case (.reward, .breakIt):
                return "결과를 덜 만족스럽게 만들려면? 예: 책임 파트너에게 공개"
            default:
                return ""
            }
        }
    }

    // MARK: - Tiny Habits recipe (Fogg)

    /// "After I [anchor], I will [tiny behavior]."
    static func tinyHabitRecipe(anchor: String?, tiny: String?) -> String {
        let a = anchor.nilIfBlank ?? "[기존 습관]"
        let t = tiny.nilIfBlank ?? "[아주 작은 행동]"
        return "\(a) 후에, 나는 \(t)."
    }

    // MARK: - Implementation intention (Gollwitzer)

    /// "I will [behavior] at [time] in [location]."
    static func implementationIntention(behavior: String, time: Date?, location: String?) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeStyle = .short
        let timeStr = time.map { formatter.string(from: $0) } ?? "[시간]"
        let loc = location.nilIfBlank ?? "[장소]"
        let b = behavior.nilIfBlank ?? "[행동]"
        return "나는 \(timeStr)에 \(loc)에서 \(b)."
    }

    // MARK: - Fogg Behavior Model diagnosis

    /// Returns the most useful lever to pull given current M/A/P state.
    static func foggDiagnosis(motivation: Int, ability: Int, hasPrompt: Bool) -> String {
        if !hasPrompt {
            return "프롬프트가 없습니다. 언제·어디서 촉발될지를 먼저 설계하세요."
        }
        if ability < 4 {
            return "능력 점수가 낮습니다. 더 작게 쪼개거나 마찰을 줄이세요."
        }
        if motivation < 4 {
            return "동기가 낮습니다. 매력을 올리거나, 능력을 더 높여 보완하세요."
        }
        return "행동 곡선 위에 있습니다. 신호가 오면 실행될 가능성이 높습니다."
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Optional where Wrapped == String {
    var nilIfBlank: String? { self?.nilIfBlank }
}
