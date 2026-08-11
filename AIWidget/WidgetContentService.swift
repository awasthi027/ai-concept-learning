//
//  WidgetContentService.swift
//  AIWidget
//
//  Fetches Explore products from the configured endpoint and exposes a
//  random product plus its thumbnail data for the widget to render.
//

import Foundation

protocol WidgetContentServiceProtocol {
    func fetchProducts() async throws -> [ExploreProduct]
    func imageData(for product: ExploreProduct) async -> Data?
}

final class WidgetContentService: WidgetContentServiceProtocol {

    private let session: URLSession
    private let config: WidgetAppConfig?

    init(session: URLSession = .shared) {
        self.session = session
        self.config = try? WidgetAppConfig()
    }

    func fetchProducts() async throws -> [ExploreProduct] {
        guard let endpoint = try config?.contentEndpoint() else {
            throw WidgetAppConfig.ConfigError.missingValue("ContentEndpoint")
        }
        let (data, _) = try await session.data(from: endpoint)
        let response = try JSONDecoder().decode(ProductsResponse.self, from: data)
        return response.products.map { ExploreProduct(product: $0) }
    }

    func imageData(for product: ExploreProduct) async -> Data? {
        guard let url = product.imageURL else {
            return nil
        }
        return try? await session.data(from: url).0
    }
}

private struct ProductsResponse: Decodable {
    let products: [Product]
}

private struct Product: Decodable {
    let id: Int
    let title: String
    let description: String
    let thumbnail: String
}

private extension ExploreProduct {
    init(product: Product) {
        self.init(
            id: product.id,
            title: product.title,
            subtitle: product.description,
            imageURL: URL(string: product.thumbnail)
        )
    }
}
