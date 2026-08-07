//
//  ExploreView.swift
//  ai-concept-learning
//
//  Online tab showing remote content (title, subtitle, image) from a public API.
//

import SwiftUI

struct ExploreView: View {

    @StateObject var exploreViewModel: ExploreViewModel

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { exploreViewModel.errorMessage != nil },
            set: { if !$0 { exploreViewModel.errorMessage = nil } }
        )
    }

    var body: some View {
        content
            .navigationTitle("Explore")
            .navigationDestination(for: RemoteContent.self) { item in
                RemoteContentDetailView(item: item)
            }
            .task {
                await exploreViewModel.loadData()
            }
            .alert("Unable to load content", isPresented: isShowingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exploreViewModel.errorMessage ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        if exploreViewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            RemoteContentListView(items: exploreViewModel.items)
        }
    }
}

struct RemoteContentListView: View {

    let items: [RemoteContent]

    var body: some View {
        List(items) { item in
            NavigationLink(value: item) {
                RemoteContentRowView(item: item)
            }
            .accessibilityIdentifier("explore-\(item.id)")
        }
        .accessibilityIdentifier("exploreList")
        .listStyle(.plain)
    }
}

struct RemoteContentRowView: View {

    let item: RemoteContent

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.imageURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

#Preview {
    ExploreView(exploreViewModel: ExploreViewModel())
}
