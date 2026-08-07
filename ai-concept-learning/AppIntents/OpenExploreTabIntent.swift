//
//  OpenExploreTabIntent.swift
//  ai-concept-learning
//
//  App Intent that launches the app and switches to the Explore tab.
//

import AppIntents

struct OpenExploreTabIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Explore"

    static var description = IntentDescription("Opens the Explore tab.")

    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        ToDoNavigator.shared.showExplore()
        return .result()
    }
}
