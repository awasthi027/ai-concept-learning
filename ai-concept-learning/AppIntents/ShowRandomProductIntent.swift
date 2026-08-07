//
//  ShowRandomProductIntent.swift
//  ai-concept-learning
//
//  Parameter-less App Intent so it appears in the auto App Shortcuts list. Shows
//  a random product's title, subtitle, and a bigger image as an inline snippet.
//

import AppIntents
import SwiftUI

struct ShowRandomProductIntent: AppIntent {

    static var title: LocalizedStringResource = "Show Random Product"

    static var description = IntentDescription(
        "Shows a random product's title, subtitle, and image."
    )

    private var remoteService: RemoteContentServiceProtocol { RemoteContentDataSource() }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let product = try await remoteService.fetchContent().randomElement() else {
            return .result(
                dialog: IntentDialog("No products available."),
                view: ProductSnippetView(title: "No products", subtitle: "", image: nil)
            )
        }
        let image = await ProductImageLoader.loadImage(from: product.imageURL)
        return .result(
            dialog: IntentDialog("\(product.title)"),
            view: ProductSnippetView(
                title: product.title,
                subtitle: product.subtitle,
                image: image
            )
        )
    }
}
