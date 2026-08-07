//
//  RemoteContent.swift
//  ai-concept-learning
//
//  Display model for content fetched from the online endpoint.
//

import Foundation

struct RemoteContent: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let imageURL: URL?
}
