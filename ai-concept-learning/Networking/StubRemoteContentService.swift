//
//  StubRemoteContentService.swift
//  ai-concept-learning
//
//  Provides deterministic Explore content for UI tests so the tab never
//  depends on live network access (which is unreliable on CI runners).
//

#if DEBUG
import Foundation

final class StubRemoteContentService: RemoteContentServiceProtocol {

    static let launchArgument = "-uiTestStubExplore"

    func fetchContent() async throws -> [RemoteContent] {
        [
            RemoteContent(
                id: 1,
                title: "Sample One",
                subtitle: "First stubbed item",
                imageURL: nil
            ),
            RemoteContent(
                id: 2,
                title: "Sample Two",
                subtitle: "Second stubbed item",
                imageURL: nil
            )
        ]
    }
}
#endif
