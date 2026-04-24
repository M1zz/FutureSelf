# FutureSelf

Identity-based habit shaper built around a 2×2 audit:

|              | Have it            | Don't have it    |
| ------------ | ------------------ | ---------------- |
| Want         | Keep & reinforce   | Build new        |
| Don't want   | Break              | Ignore           |

Each quadrant maps to a different subset of habit design formulas, and every habit is tied to an identity statement ("나는 ○○한 사람이다").

## Setup in Xcode

1. Open Xcode → File → New → Project → iOS → App.
2. Product name: `FutureSelf`. Interface: SwiftUI. Storage: **None** (we'll add SwiftData manually, not the template).
3. Minimum iOS target: **17.0** (SwiftData requires it).
4. Drop all `.swift` files from this folder into the project, replacing the generated `ContentView.swift` and `FutureSelfApp.swift`.
5. Build and run. The app opens onto onboarding on first launch.

## File map

| File                     | Role                                                                 |
| ------------------------ | -------------------------------------------------------------------- |
| `FutureSelfApp.swift`    | `@main` entry. Declares the SwiftData `ModelContainer`.              |
| `Models.swift`           | `HabitQuadrant`, `IdentityStatement`, `Habit`, `HabitLog`.           |
| `HabitFormulas.swift`    | Research encoded as types + context-aware prompts.                   |
| `RootView.swift`         | Onboarding gate + main `TabView`.                                    |
| `HabitMatrixView.swift`  | The 2×2 grid + quadrant lists + add sheet.                           |
| `HabitDesignerView.swift`| Per-habit designer applying the formulas.                            |
| `DashboardView.swift`    | Today view with tap-to-log rows.                                     |
| `ReflectionView.swift`   | 7-day strip view per habit.                                          |

## Research foundations encoded

- **Identity-based habits** (Clear, *Atomic Habits*, 2018) — Onboarding captures an `IdentityStatement`; every `Habit` stores a `linkedIdentity`.
- **Four Laws** (Clear) — `cue / craving / response / reward` fields. Prompts flip based on quadrant (build-side vs. break-side).
- **Tiny Habits & B = MAP** (Fogg, *Tiny Habits*, 2020) — `anchorHabit` + `tinyVersion` produce the "After I … I will …" recipe. `motivation / ability / hasPrompt` feed a live diagnosis via `HabitFormulas.foggDiagnosis`.
- **Implementation intentions** (Gollwitzer, 1999) — `timeOfDay` + `locationContext` build "I will X at Y in Z".

## Design notes

- `Habit.designCompleteness` rolls up 6 design fields into a 0-100% score surfaced in each row. This pushes users to complete the full design before the habit goes live.
- `Habit.foggScore` = M × A × P (0...1), useful for sorting or diagnostics.
- Four Laws fields do **double duty**: for `.breakIt` habits, the prompt guides you to fill them with the inverted friction version of each law.
- `quadrant == .ignore` skips the designer sections entirely. No need to over-engineer habits you don't care about.

## Suggested extensions

- **Swift Charts** — replace the week strip with a heatmap or stacked area chart.
- **UserNotifications** — schedule a reminder from `timeOfDay` + `locationContext` (region-based triggers).
- **App Intents / Shortcuts** — "Log my [habit]" Siri shortcut.
- **CloudKit sync** — flip `ModelConfiguration` to `.automatic` and enable iCloud capability.
- **WidgetKit** — today's habits on the home screen, tappable via App Intents.
- **HealthKit** — auto-log movement/sleep habits when quadrant is `.keep` or `.build`.
- **Weekly review prompt** — a `NotificationCenter` weekly trigger that pushes users into `ReflectionView` and surfaces habits with <70% completion for re-sizing.
- **Temptation bundling** — a `bundledWith: Habit?` relationship so a build-habit rides on top of a keep-habit.

## Known gaps (intentional, for you to extend)

- No habit reordering yet. `Habit.sortIndex: Int` is the natural addition.
- No recurrence rules (MWF, weekdays, etc.). Add a `schedule: HabitSchedule` enum.
- No undo for log toggling beyond the tap-to-untoggle pattern.
- No export. SwiftData's `fetch` + `JSONEncoder` gives you this in ~30 lines.
