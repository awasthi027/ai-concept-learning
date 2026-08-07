//
//  ProductSnippetView.swift
//  ai-concept-learning
//
//  Snippet shown by product intents: title, subtitle, and a bigger image. The
//  image is preloaded before rendering because App Intent snippets are
//  snapshotted immediately and cannot wait for AsyncImage.
//

import SwiftUI
import UIKit

struct ProductSnippetView: View {

    let title: String
    let subtitle: String
    let image: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            imageContent
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    @ViewBuilder
    private var imageContent: some View {
        if let image {
            image
                .resizable()
                .scaledToFit()
        } else {
            Color(.secondarySystemBackground)
        }
    }
}

enum ProductImageLoader {

    static func loadImage(from url: URL?) async -> Image? {
        guard let url else {
            return nil
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}
