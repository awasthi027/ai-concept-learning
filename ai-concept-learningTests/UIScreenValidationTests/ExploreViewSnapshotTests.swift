//
//  ExploreViewSnapshotTests.swift
//  ai-concept-learningTests
//
//  Snapshot tests for the Explore list row and detail screens. Image URLs are
//  nil so rendering stays deterministic and offline.
//

import Testing
import SwiftUI
@testable import ai_concept_learning

@MainActor
struct ExploreViewSnapshotTests {

    @Test("TestToValidateExploreListUIChanges")
    func validateExploreList() async throws {
        let screen = NavigationStack {
            RemoteContentListView(items: Self.sampleItems)
                .navigationTitle("Explore")
        }

        try SnapshotValidator.validate(
            screen,
            folder: "ExploreView",
            name: "explore_view.png"
        )
    }

    @Test("TestToValidateExploreDetailUIChanges")
    func validateExploreDetail() async throws {
        let item = RemoteContent(
            id: 1,
            title: "Alpha",
            subtitle: "First subtitle",
            imageURL: nil
        )

        let screen = NavigationStack {
            RemoteContentDetailView(item: item)
        }

        try SnapshotValidator.validate(
            screen,
            folder: "ExploreDetailView",
            name: "details_view.png"
        )
    }

    static var sampleItems: [RemoteContent] {
        [
            RemoteContent(id: 1, title: "Alpha", subtitle: "First subtitle", imageURL: nil),
            RemoteContent(id: 2, title: "Beta", subtitle: "Second subtitle", imageURL: nil),
            RemoteContent(id: 3, title: "Gamma", subtitle: "Third subtitle", imageURL: nil)
        ]
    }
}
