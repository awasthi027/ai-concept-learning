//
//  ListToDosIntent.swift
//  ai-concept-learning
//
//  App Intent that returns the to-dos (optionally filtered by status) so Siri,
//  Shortcuts, and Spotlight can display the full list.
//

import AppIntents
import SwiftUI

struct ListToDosIntent: AppIntent {

    static var title: LocalizedStringResource = "List To-Dos"

    static var description = IntentDescription(
        "Lists your to-dos, optionally filtered by their status."
    )

    @Parameter(title: "Status", default: .all)
    var status: ToDoStatusFilter

    private var toDoService: ToDoServiceProtocol { LocalToDoDataSource() }

    static var parameterSummary: some ParameterSummary {
        Summary("List \(\.$status) to-dos")
    }

    @MainActor
    func perform() async throws
        -> some IntentResult & ReturnsValue<[ToDoEntity]> & ProvidesDialog & ShowsSnippetView {
        let entities = try toDoService.getToDo()
            .filter { status.matches($0.status) }
            .map(ToDoEntity.init)
        return .result(
            value: entities,
            dialog: dialog(for: entities.count),
            view: ToDoSnippetView(toDos: entities)
        )
    }

    private func dialog(for count: Int) -> IntentDialog {
        let label = status == .all ? "" : "\(status.rawValue) "
        let noun = count == 1 ? "to-do" : "to-dos"
        return IntentDialog("Here \(count == 1 ? "is" : "are") \(count) \(label)\(noun).")
    }
}
