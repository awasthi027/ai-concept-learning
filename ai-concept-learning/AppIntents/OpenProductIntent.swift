//
//  OpenProductIntent.swift
//  ai-concept-learning
//
//  App Intent that opens a chosen product in the Explore tab detail screen.
//

import AppIntents

struct OpenProductIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Product"

    static var description = IntentDescription("Opens a product in the Explore tab.")

    static var openAppWhenRun = true

    @Parameter(title: "Product")
    var product: ProductEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$product)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        ToDoNavigator.shared.open(product: product.remoteContent)
        return .result()
    }
}
