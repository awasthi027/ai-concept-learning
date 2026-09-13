//
//  BrowserTextDestination.swift
//  ai-concept-learning
//
//  Navigation payload for the text-view route: carries the chosen browser and
//  the composed scheme URL so the next screen can present a tappable link that
//  opens the target website in that browser.
//

import Foundation

struct BrowserTextDestination: Identifiable, Hashable {
    let id: String
    let browser: Browser
    let urlString: String
    let url: URL
}
