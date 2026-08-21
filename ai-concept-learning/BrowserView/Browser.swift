//
//  Browser.swift
//  ai-concept-learning
//
//  Display model for a target browser app that can open a URL. The full open-url
//  string (scheme + embedded https target) is admin-pushed via Browsers.plist.
//  Before display the embedded https URL is swapped for the user's target.
//

import Foundation

struct Browser: Identifiable, Hashable {
    let id: String
    let name: String
    let scheme: String
    let iconSystemName: String
    let colorHex: String
    let urlTemplate: String
}

extension Browser {

    func composedURLString(for target: String) -> String {
        let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return urlTemplate
        }
        guard let range = urlTemplate.range(of: "https://", options: .backwards) else {
            return trimmed
        }
        return urlTemplate.replacingCharacters(
            in: range.lowerBound..<urlTemplate.endIndex,
            with: trimmed
        )
    }

    func composedURL(for target: String) -> URL? {
        let raw = composedURLString(for: target)
        guard !raw.isEmpty else {
            return nil
        }
        return URL(string: raw)
    }
}
