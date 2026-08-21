//
//  BrowserService.swift
//  ai-concept-learning
//
//  Loads the catalog of target browsers (name, scheme, admin-pushed open-url
//  template) from the bundled Browsers.plist so nothing is hardcoded in source.
//

import Foundation

protocol BrowserServiceProtocol {
    func fetchBrowsers() throws -> [Browser]
}

final class BrowserCatalogDataSource: BrowserServiceProtocol {

    enum CatalogError: Error {
        case missingCatalog
        case invalidEntry
    }

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func fetchBrowsers() throws -> [Browser] {
        guard let url = bundle.url(forResource: "Browsers", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let raw = try PropertyListSerialization
                .propertyList(from: data, format: nil) as? [[String: Any]] else {
            throw CatalogError.missingCatalog
        }
        return try raw.map { try Self.makeBrowser(from: $0) }
    }

    private static func makeBrowser(from entry: [String: Any]) throws -> Browser {
        guard let id = entry["id"] as? String,
              let name = entry["name"] as? String,
              let scheme = entry["scheme"] as? String,
              let template = entry["urlTemplate"] as? String else {
            throw CatalogError.invalidEntry
        }
        return Browser(
            id: id,
            name: name,
            scheme: scheme,
            iconSystemName: entry["iconSystemName"] as? String ?? "globe",
            colorHex: entry["colorHex"] as? String ?? "#1E88E5",
            urlTemplate: template
        )
    }
}
