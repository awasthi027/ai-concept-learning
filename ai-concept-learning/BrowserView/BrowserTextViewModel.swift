//
//  BrowserTextViewModel.swift
//  ai-concept-learning
//
//  Presentation logic for the text-view route: exposes the message and link
//  copy, and opens the composed scheme URL in the chosen target browser.
//

import Combine
import Foundation

@MainActor
final class BrowserTextViewModel: ObservableObject {

    let title: String
    let message: String
    
    @Published var errorMessage: String?

    private let browserName: String
    private let opener: URLOpening

    init(destination: BrowserTextDestination, opener: URLOpening) {
        self.title = destination.browser.name
        self.browserName = destination.browser.name
        self.opener = opener
        self.message = "Tap the link below to open this page in " +  destination.url.absoluteString
            + "\(destination.browser.name)."
    }

    func openLink() async {
        guard let urlStr = message.firstSchemeURLSubstring(),
              let linkURL = URL(string: urlStr) else {
            return
        }
        guard opener.canOpen(linkURL) else {
            errorMessage = "\(browserName) is not installed."
            return
        }
        let didOpen = await opener.open(linkURL)
        if !didOpen {
            errorMessage = "Could not open \(browserName)."
        }
    }

}
public extension String {

    func firstSchemeURLSubstring() -> String? {
        let pattern = #"\S+://\S+"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              let matchRange = Range(match.range, in: self) else {
            return nil
        }
        return String(self[matchRange])
    }

    func containsCustomSchemeAndHTTPLink() -> Bool {
        guard let scheme = URL(string: self)?.scheme?.lowercased(),
              scheme != "http", scheme != "https" else {
            return false
        }
        let lowered = self.lowercased()
        return lowered.contains("http://") || lowered.contains("https://")
    }
}
