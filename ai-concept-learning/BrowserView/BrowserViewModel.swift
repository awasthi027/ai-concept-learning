//
//  BrowserViewModel.swift
//  ai-concept-learning
//
//  Presentation logic for the Browser tab: loads the browser catalog, composes
//  the complete scheme URL for a target, and opens it in the chosen browser.
//

import Combine
import Foundation

@MainActor
protocol URLOpening {
    func canOpen(_ url: URL) -> Bool
    func open(_ url: URL) async -> Bool
}

@MainActor
final class BrowserViewModel: ObservableObject {

    @Published var browsers: [Browser] = []
    @Published var availableBrowsers: [Browser] = []
    @Published var targetURLString: String = "https://www.google.com/"
    @Published var errorMessage: String?

    private let service: BrowserServiceProtocol
    private let opener: URLOpening

    init(
        service: BrowserServiceProtocol = BrowserCatalogDataSource(),
        opener: URLOpening
    ) {
        self.service = service
        self.opener = opener
    }

    func loadBrowsers() {
        do {
            browsers = try service.fetchBrowsers()
            availableBrowsers = browsers.filter(isAvailable)
        } catch {
            errorMessage = "Unable to load browsers."
        }
    }

    private func isAvailable(_ browser: Browser) -> Bool {
        guard let url = URL(string: "\(browser.scheme)://") else {
            return false
        }
        return opener.canOpen(url)
    }

    func composedURL(for browser: Browser) -> URL? {
        browser.composedURL(for: targetURLString)
    }

    func displayURL(for browser: Browser) -> String {
        browser.composedURLString(for: targetURLString)
    }

    func open(_ browser: Browser) async {
        guard let url = composedURL(for: browser) else {
            errorMessage = "Enter a valid URL to open."
            return
        }
        guard opener.canOpen(url) else {
            errorMessage = "\(browser.name) is not installed."
            return
        }
        let didOpen = await opener.open(url)
        if !didOpen {
            errorMessage = "Could not open \(browser.name)."
        }
    }
}
