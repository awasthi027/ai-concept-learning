//
//  ExploreScreen.swift
//  ai-concept-learningUITests
//
//  Screen object for the online Explore tab.
//

import XCTest

class ExploreScreen {

    var application: XCUIApplication

    init(application: XCUIApplication) {
        self.application = application
    }

    var tabButton: XCUIElement {
        application.tabBars.buttons["Explore"]
    }

    var navigationTitle: XCUIElement {
        application.navigationBars["Explore"]
    }

    var list: XCUIElement {
        application.descendants(matching: .any)
            .matching(identifier: "exploreList")
            .firstMatch
    }

    var firstRow: XCUIElement {
        list.buttons.firstMatch
    }
}
