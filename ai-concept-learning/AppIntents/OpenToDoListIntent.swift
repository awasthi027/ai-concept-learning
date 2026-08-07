//
//  OpenToDoListIntent.swift
//  ai-concept-learning
//
//  App Intent that launches the app and shows the to-do list screen.
//

import AppIntents

struct OpenToDoListIntent: AppIntent {

    static var title: LocalizedStringResource = "Open To-Do List"

    static var description = IntentDescription(
        "Opens the app and shows your to-do list."
    )

    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        ToDoNavigator.shared.showToDoList()
        return .result()
    }
}
