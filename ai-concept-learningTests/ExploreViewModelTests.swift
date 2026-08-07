//
//  ExploreViewModelTests.swift
//  ai-concept-learningTests
//
//  Unit tests for the online Explore tab's view model.
//

import Testing
@testable import ai_concept_learning
import Foundation

struct ExploreViewModelTests {

    @Test("Loads remote content into items on success")
    @MainActor
    func loadsItemsOnSuccess() async throws {
        let service = MockRemoteContentService(result: .success(Self.sampleItems))
        let viewModel = ExploreViewModel(remoteService: service)

        await viewModel.loadData()

        #expect(viewModel.items.count == 2)
        #expect(viewModel.items.first?.title == "Alpha")
        #expect(viewModel.items.first?.subtitle == "First subtitle")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("Publishes error message on failure")
    @MainActor
    func setsErrorOnFailure() async throws {
        let service = MockRemoteContentService(result: .failure(MockError.failed))
        let viewModel = ExploreViewModel(remoteService: service)

        await viewModel.loadData()

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    static var sampleItems: [RemoteContent] {
        [
            RemoteContent(id: 1, title: "Alpha", subtitle: "First subtitle", imageURL: nil),
            RemoteContent(id: 2, title: "Beta", subtitle: "Second subtitle", imageURL: nil)
        ]
    }
}

enum MockError: Error {
    case failed
}

final class MockRemoteContentService: RemoteContentServiceProtocol {

    private let result: Result<[RemoteContent], Error>

    init(result: Result<[RemoteContent], Error>) {
        self.result = result
    }

    func fetchContent() async throws -> [RemoteContent] {
        try result.get()
    }
}
