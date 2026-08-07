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

    var tabButton: XCUIElement {
        application.tabBars.buttons["Home"]
    }
    
    var navigationTitle: XCUIElement {
        application.navigationBars["Home"]
    }

    var list: XCUIElement {
        application.descendants(matching: .any).matching(identifier: "homeViewList").firstMatch
    }
    
    var firstRow: XCUIElement {
        list.staticTexts["row_1"].firstMatch
    }
}
