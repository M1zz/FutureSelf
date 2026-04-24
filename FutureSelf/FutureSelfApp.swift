//
//  FutureSelfApp.swift
//  FutureSelf - Identity-based habit shaper
//

import SwiftUI
import SwiftData

@main
struct FutureSelfApp: App {
    let container: ModelContainer = {
        let schema = Schema([
            IdentityStatement.self,
            Habit.self,
            HabitLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
