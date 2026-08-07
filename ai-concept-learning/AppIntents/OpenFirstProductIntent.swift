//
//  OpenFirstProductIntent.swift
//  ai-concept-learning
//
//  Parameter-less App Intent so it appears in the auto App Shortcuts list. Opens
//  the app and navigates to the first product's detail in the Explore tab.
//

import AppIntents

struct OpenFirstProductIntent: AppIntent {

    static var title: LocalizedStringResource = "Open First Product"

    static var description = IntentDescription(
        "Opens the first product in the Explore tab."
    )

    static var openAppWhenRun = true

    private var remoteService: RemoteContentServiceProtocol { RemoteContentDataSource() }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let product = try await remoteService.fetchContent().first else {
            ToDoNavigator.shared.showExplore()
            return .result()
        }
        ToDoNavigator.shared.open(product: product)
        return .result()
    }
}
