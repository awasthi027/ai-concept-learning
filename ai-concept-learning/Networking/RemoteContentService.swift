//
//  RemoteContentService.swift
//  ai-concept-learning
//
//  Fetches content (title, subtitle, image) from a public endpoint sourced
//  from AppConfig, and maps it into RemoteContent display models.
//

import Foundation

protocol RemoteContentServiceProtocol {
    func fetchContent() async throws -> [RemoteContent]
}

final class RemoteContentDataSource: RemoteContentServiceProtocol {

    private let session: URLSession
    private let config: AppConfig?

    init(session: URLSession = .shared) {
        self.session = session
        self.config = try? AppConfig()
    }

    func fetchContent() async throws -> [RemoteContent] {
        guard let endpoint = try config?.contentEndpoint() else {
            throw AppConfig.ConfigError.missingValue("ContentEndpoint")
        }
        let (data, _) = try await session.data(from: endpoint)
        let response = try JSONDecoder().decode(ProductsResponse.self, from: data)
        return response.products.map { RemoteContent(product: $0) }
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

private extension RemoteContent {
    init(product: Product) {
        self.init(
            id: product.id,
            title: product.title,
            subtitle: product.description,
            imageURL: URL(string: product.thumbnail)
        )
    }
}
