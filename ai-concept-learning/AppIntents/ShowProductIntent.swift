//
//  ShowProductIntent.swift
//  ai-concept-learning
//
//  App Intent that displays a product's title, subtitle, and a bigger image as
//  an inline snippet, without opening the app.
//

import AppIntents
import SwiftUI

struct ShowProductIntent: AppIntent {

    static var title: LocalizedStringResource = "Show Product"

    static var description = IntentDescription(
        "Shows a product's title, subtitle, and image."
    )

    @Parameter(title: "Product")
    var product: ProductEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$product)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let content = product.remoteContent
        let image = await ProductImageLoader.loadImage(from: content.imageURL)
        return .result(
            dialog: IntentDialog("\(content.title)"),
            view: ProductSnippetView(
                title: content.title,
                subtitle: content.subtitle,
                image: image
            )
        )
    }
}
