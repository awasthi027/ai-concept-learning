//
//  BrowserView.swift
//  ai-concept-learning
//
//  Browser tab: enter a target URL and pick a browser to open it. Each row shows
//  the browser icon, its name (title) and the complete scheme URL (subtitle),
//  built by swapping the embedded https target inside the admin-pushed template.
//

import SwiftUI

struct BrowserView: View {

    @StateObject var browserViewModel: BrowserViewModel

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { browserViewModel.errorMessage != nil },
            set: { if !$0 { browserViewModel.errorMessage = nil } }
        )
    }

    private var isShowingOptions: Binding<Bool> {
        Binding(
            get: { browserViewModel.pendingBrowser != nil },
            set: { if !$0 { browserViewModel.pendingBrowser = nil } }
        )
    }

    var body: some View {
        List {
            availableSection
            targetSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("browserList")
        .navigationTitle("Browser")
        .onAppear {
            browserViewModel.loadBrowsers()
        }
        .navigationDestination(item: $browserViewModel.textDestination) { destination in
            BrowserTextView(
                textViewModel: browserViewModel.makeTextViewModel(for: destination)
            )
        }
        .alert(
            "Open with",
            isPresented: isShowingOptions,
            presenting: browserViewModel.pendingBrowser
        ) { browser in
            optionButtons(for: browser)
        }
        .alert("Unable to open browser", isPresented: isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(browserViewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func optionButtons(for browser: Browser) -> some View {
        Button("Open in \(browser.name)") {
            Task {
                await browserViewModel.open(browser)
            }
        }
        Button("Open in Text View") {
            browserViewModel.presentTextView(for: browser)
        }
        Button("Cancel", role: .cancel) { }
    }

    @ViewBuilder
    private var availableSection: some View {
        if browserViewModel.availableBrowsers.isEmpty {
            Section("Available browsers") {
                Text("No supported browsers found on this device.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } else {
            Section("Available browsers") {
                ForEach(browserViewModel.availableBrowsers) { browser in
                    HStack(spacing: 12) {
                        BrowserIcon(
                            systemName: browser.iconSystemName,
                            colorHex: browser.colorHex
                        )
                        Text(browser.name)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .accessibilityIdentifier("available-\(browser.id)")
                }
            }
        }
    }

    private var targetSection: some View {
        Section("URL to open") {
            TextField("https://www.example.com", text: $browserViewModel.targetURLString)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .accessibilityIdentifier("browserTargetField")
        }
    }

    private var actionsSection: some View {
        Section("Open in") {
            ForEach(browserViewModel.browsers) { browser in
                BrowserActionRow(
                    browser: browser,
                    urlString: browserViewModel.displayURL(for: browser)
                ) {
                    browserViewModel.presentOptions(for: browser)
                }
            }
        }
    }
}

struct BrowserActionRow: View {

    let browser: Browser
    let urlString: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                BrowserIcon(
                    systemName: browser.iconSystemName,
                    colorHex: browser.colorHex
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(browser.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(urlString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "arrow.up.forward.app")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("browser-\(browser.id)")
    }
}

#Preview {
    NavigationStack {
        BrowserView(
            browserViewModel: BrowserViewModel(opener: SystemURLOpener())
        )
    }
}
