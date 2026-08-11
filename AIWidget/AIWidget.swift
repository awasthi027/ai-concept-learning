//
//  AIWidget.swift
//  AIWidget
//
//  Widget that shows a random product from the Explore tab.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {

    private let service: WidgetContentServiceProtocol = WidgetContentService()

    func placeholder(in context: Context) -> ProductEntry {
        ProductEntry(date: Date(), product: nil, imageData: nil)
    }

    func snapshot(
        for configuration: ConfigurationAppIntent, in context: Context
    ) async -> ProductEntry {
        await makeEntry(date: Date())
    }

    func timeline(
        for configuration: ConfigurationAppIntent, in context: Context
    ) async -> Timeline<ProductEntry> {
        let entry = await makeEntry(date: Date())
        let refresh = Calendar.current.date(
            byAdding: .minute, value: 30, to: entry.date
        ) ?? entry.date
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func makeEntry(date: Date) async -> ProductEntry {
        guard let product = try? await service.fetchProducts().randomElement() else {
            return ProductEntry(date: date, product: nil, imageData: nil)
        }
        let imageData = await service.imageData(for: product)
        return ProductEntry(date: date, product: product, imageData: imageData)
    }
}

struct ProductEntry: TimelineEntry {
    let date: Date
    let product: ExploreProduct?
    let imageData: Data?
}

struct AIWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        if let product = entry.product {
            productView(product)
        } else {
            Text("No content available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func productView(_ product: ExploreProduct) -> some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(product.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = entry.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.secondary.opacity(0.2))
                .frame(width: 56, height: 56)
        }
    }
}

struct AIWidget: Widget {
    let kind: String = "AIWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            AIWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Explore Pick")
        .description("Shows a random product from the Explore tab.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    AIWidget()
} timeline: {
    ProductEntry(
        date: .now,
        product: ExploreProduct(
            id: 1, title: "Sample", subtitle: "A sample product", imageURL: nil
        ),
        imageData: nil
    )
}
