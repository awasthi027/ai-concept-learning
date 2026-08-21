//
//  SystemURLOpener.swift
//  ai-concept-learning
//
//  UIApplication-backed URL opener used by the Browser tab in production.
//

import UIKit

@MainActor
final class SystemURLOpener: URLOpening {

    func canOpen(_ url: URL) -> Bool {
        UIApplication.shared.canOpenURL(url)
    }

    func open(_ url: URL) async -> Bool {
        await UIApplication.shared.open(url)
    }
}
