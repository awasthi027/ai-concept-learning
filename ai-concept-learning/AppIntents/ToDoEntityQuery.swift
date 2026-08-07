//
//  ToDoEntityQuery.swift
//  ai-concept-learning
//
//  Lets the system resolve ToDoEntity values for App Intents parameters.
//

import AppIntents

struct ToDoEntityQuery: EntityQuery {

    func entities(for identifiers: [Int]) async throws -> [ToDoEntity] {
        let requested = Set(identifiers)
        return try allEntities().filter { requested.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ToDoEntity] {
        try allEntities()
    }

    private func allEntities() throws -> [ToDoEntity] {
        try LocalToDoDataSource().getToDo().map(ToDoEntity.init)
    }
}
