//
//  HomeScreen.swift
//  TestProject
//
//  Created by Ashish Awasthi on 30/07/26.
//

import XCTest

class HomeScreen {

    var application: XCUIApplication

    init (application: XCUIApplication) {
        self.application = application
    }
    var navigationTitle: XCUIElement {
        application.navigationBars["Home"]
    }

    var list: XCUIElement {
        application.descendants(matching: .any).matching(identifier: "homeViewList").firstMatch
    }
}
