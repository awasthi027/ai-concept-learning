//
//  ProductEntity.swift
//  ai-concept-learning
//
//  Exposes an Explore product to the system (Siri / Shortcuts) via App Intents.
//

import AppIntents

struct ProductEntity: AppEntity, Identifiable {

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Product")
    }

    static var defaultQuery = ProductEntityQuery()

    let id: Int
    let title: String
    let subtitle: String
    let imageURLString: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }

    init(content: RemoteContent) {
        self.id = content.id
        self.title = content.title
        self.subtitle = content.subtitle
        self.imageURLString = content.imageURL?.absoluteString
    }

    var remoteContent: RemoteContent {
        RemoteContent(
            id: id,
            title: title,
            subtitle: subtitle,
            imageURL: imageURLString.flatMap { URL(string: $0) }
        )
    }
}
