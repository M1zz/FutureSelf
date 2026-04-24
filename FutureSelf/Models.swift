//
//  Models.swift
//  Core data model: identity, habits, logs, and the 2x2 quadrant.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Quadrant

/// The core 2x2 classification.
///   - have it + want it           -> keep & reinforce
///   - don't have it + want it     -> build new
///   - have it + don't want it     -> break
///   - don't have it + don't want  -> ignore
enum HabitQuadrant: String, Codable, CaseIterable, Identifiable {
    case keep       // have it, want it
    case build      // don't have it, want it
    case breakIt    // have it, don't want it ("break" is a Swift keyword)
    case ignore     // don't have it, don't want it

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keep:    return "유지하고 강화"
        case .build:   return "새로 만들기"
        case .breakIt: return "끊어내기"
        case .ignore:  return "신경 끄기"
        }
    }

    var subtitle: String {
        switch self {
        case .keep:    return "가지고 있음 · 원함"
        case .build:   return "가지고 있지 않음 · 원함"
        case .breakIt: return "가지고 있음 · 원하지 않음"
        case .ignore:  return "가지고 있지 않음 · 원하지 않음"
        }
    }

    var color: Color {
        switch self {
        case .keep:    return .green
        case .build:   return .blue
        case .breakIt: return .red
        case .ignore:  return .gray
        }
    }

    var iconName: String {
        switch self {
        case .keep:    return "checkmark.seal"
        case .build:   return "plus.circle"
        case .breakIt: return "scissors"
        case .ignore:  return "circle.slash"
        }
    }

    /// One-line strategy for this quadrant.
    var strategy: String {
        switch self {
        case .keep:    return "신호 강화 · 자동화"
        case .build:   return "작게 설계 → 4법칙 적용"
        case .breakIt: return "신호 제거 · 마찰 추가"
        case .ignore:  return "에너지 낭비 없이 방치"
        }
    }

    /// Where this quadrant is trying to move toward.
    var goal: String {
        switch self {
        case .keep:    return "여기 유지"
        case .build:   return "→ 유지하고 강화"
        case .breakIt: return "→ 신경 끄기"
        case .ignore:  return "관여 불필요"
        }
    }

    var needsDesign: Bool {
        self == .build || self == .breakIt || self == .keep
    }
}

// MARK: - Identity

@Model
final class IdentityStatement {
    var id: UUID = UUID()
    var statement: String = ""
    var isPrimary: Bool = false
    var createdAt: Date = Date()

    init(statement: String, isPrimary: Bool = false) {
        self.id = UUID()
        self.statement = statement
        self.isPrimary = isPrimary
        self.createdAt = Date()
    }
}

// MARK: - Habit

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var detail: String = ""
    var quadrantRaw: String = HabitQuadrant.build.rawValue
    var createdAt: Date = Date()
    var isArchived: Bool = false

    /// Free-text link back to an identity statement, e.g. "나는 매일 움직이는 사람".
    var linkedIdentity: String?

    // MARK: Four Laws (Clear)
    // Fields do double duty depending on quadrant:
    //   BUILD / KEEP: fill as the positive version of each law
    //   BREAK:        fill as the inverted friction design
    var cue: String?        // Law 1: obvious / invisible
    var craving: String?    // Law 2: attractive / unattractive
    var response: String?   // Law 3: easy / difficult (also the tiny action itself)
    var reward: String?     // Law 4: satisfying / unsatisfying

    // MARK: Tiny Habits (Fogg)
    var anchorHabit: String?   // "After I [anchor]"
    var tinyVersion: String?   // "I will [tiny behavior]"

    // MARK: Implementation intention (Gollwitzer)
    var timeOfDay: Date?
    var locationContext: String?

    // MARK: Fogg Behavior Model — B = MAP
    var motivation: Int = 5   // 1...10
    var ability: Int = 5      // 1...10
    var hasPrompt: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

    init(name: String, quadrant: HabitQuadrant) {
        self.id = UUID()
        self.name = name
        self.quadrantRaw = quadrant.rawValue
        self.createdAt = Date()
    }

    var quadrant: HabitQuadrant {
        get { HabitQuadrant(rawValue: quadrantRaw) ?? .build }
        set { quadrantRaw = newValue.rawValue }
    }

    /// Estimated likelihood on Fogg's behavior curve (0.0 ... 1.0).
    var foggScore: Double {
        let m = Double(motivation) / 10.0
        let a = Double(ability) / 10.0
        let p = hasPrompt ? 1.0 : 0.0
        return m * a * p
    }

    /// How complete the design is, 0...1. Used in the habit row.
    var designCompleteness: Double {
        let slots: [String?] = [cue, craving, response, reward, anchorHabit, tinyVersion]
        let filled = slots.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                          .filter { !$0.isEmpty }
                          .count
        return Double(filled) / Double(slots.count)
    }

    /// Consecutive completed days up to `asOf`, counting only whole days.
    func streak(asOf: Date = Date()) -> Int {
        let cal = Calendar.current
        let completedDays = Set(
            logs.filter { $0.completed }
                .map { cal.startOfDay(for: $0.date) }
        )
        var streak = 0
        var cursor = cal.startOfDay(for: asOf)
        while completedDays.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}

// MARK: - Log

@Model
final class HabitLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var completed: Bool = true
    var note: String = ""
    var habit: Habit?

    init(date: Date = Date(), completed: Bool = true, note: String = "") {
        self.id = UUID()
        self.date = date
        self.completed = completed
        self.note = note
    }
}
