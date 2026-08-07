//
//  RemoteContentDetailView.swift
//  ai-concept-learning
//
//  Detail screen for an Explore item showing a larger image and its details.
//

import SwiftUI

struct RemoteContentDetailView: View {

    let item: RemoteContent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                image
                Text(item.title)
                    .font(.title)
                    .fontWeight(.bold)
                Text(item.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var image: some View {
        AsyncImage(url: item.imageURL) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            ProgressView()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
