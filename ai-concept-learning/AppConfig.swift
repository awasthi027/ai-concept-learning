//
//  AppConfig.swift
//  ai-concept-learning
//
//  Reads app configuration (such as endpoints) from the bundled AppConfig.plist
//  so URLs are never hardcoded in source.
//

import Foundation

struct AppConfig {

    enum ConfigError: Error {
        case missingValue(String)
        case invalidURL(String)
    }

    private let values: [String: Any]

    init(bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: "AppConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let parsed = try PropertyListSerialization
                .propertyList(from: data, format: nil) as? [String: Any] else {
            throw ConfigError.missingValue("AppConfig.plist")
        }
        self.values = parsed
    }

    func contentEndpoint() throws -> URL {
        let key = "ContentEndpoint"
        guard let raw = values[key] as? String else {
            throw ConfigError.missingValue(key)
        }
        guard let url = URL(string: raw) else {
            throw ConfigError.invalidURL(raw)
        }
        return url
    }
}
