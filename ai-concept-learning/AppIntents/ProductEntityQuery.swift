//
//  ProductEntityQuery.swift
//  ai-concept-learning
//
//  Resolves ProductEntity values for App Intents parameters.
//

import AppIntents

struct ProductEntityQuery: EntityQuery {

    func entities(for identifiers: [Int]) async throws -> [ProductEntity] {
        let requested = Set(identifiers)
        return try await allEntities().filter { requested.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ProductEntity] {
        try await allEntities()
    }

    private func allEntities() async throws -> [ProductEntity] {
        try await RemoteContentDataSource()
            .fetchContent()
            .map { ProductEntity(content: $0) }
    }
}
