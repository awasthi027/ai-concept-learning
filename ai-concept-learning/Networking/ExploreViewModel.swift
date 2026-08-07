//
//  ExploreViewModel.swift
//  ai-concept-learning
//
//  Presentation logic for the online Explore tab.
//

import Combine
import Foundation

class ExploreViewModel: ObservableObject {

    @Published var items: [RemoteContent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let remoteService: RemoteContentServiceProtocol

    init(remoteService: RemoteContentServiceProtocol = RemoteContentDataSource()) {
        self.remoteService = remoteService
    }

    @MainActor
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await remoteService.fetchContent()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
