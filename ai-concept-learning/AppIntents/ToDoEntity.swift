//
//  ToDoEntity.swift
//  ai-concept-learning
//
//  Exposes a ToDo to the system (Siri, Shortcuts, Spotlight) via App Intents.
//

import AppIntents

struct ToDoEntity: AppEntity, Identifiable {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "To-Do")
    }

    static var defaultQuery = ToDoEntityQuery()

    let id: Int
    let title: String
    let status: ToDoStatus

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(status.rawValue.capitalized)"
        )
    }

    init(toDo: ToDo) {
        self.id = toDo.id
        self.title = toDo.title
        self.status = toDo.status
    }
}
