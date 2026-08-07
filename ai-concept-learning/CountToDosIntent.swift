//
//  CountToDosIntent.swift
//  ai-concept-learning
//
//  App Intent that reports how many to-dos match a chosen status. Invokable from
//  Siri, the Shortcuts app, and Spotlight without opening the app.
//

import AppIntents

struct CountToDosIntent: AppIntent {

    static var title: LocalizedStringResource = "Count To-Dos"

    static var description = IntentDescription(
        "Counts your to-dos, optionally filtered by their status."
    )

    @Parameter(title: "Status", default: .all)
    var status: ToDoStatusFilter

    private var toDoService: ToDoServiceProtocol { LocalToDoDataSource() }

    static var parameterSummary: some ParameterSummary {
        Summary("Count \(\.$status) to-dos")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let matching = try toDoService.getToDo().filter { status.matches($0.status) }
        let count = matching.count
        return .result(value: count, dialog: dialog(for: count))
    }

    private func dialog(for count: Int) -> IntentDialog {
        let label = status == .all ? "" : "\(status.rawValue) "
        let noun = count == 1 ? "to-do" : "to-dos"
        return IntentDialog("You have \(count) \(label)\(noun).")
    }
}
