//
//  ExploreProduct.swift
//  AIWidget
//
//  Display model for an Explore product shown in the widget.
//

import Foundation

struct ExploreProduct: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let imageURL: URL?
}
