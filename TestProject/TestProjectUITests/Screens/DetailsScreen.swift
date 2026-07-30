//
//  DetailsScreen.swift
//  TestProject
//
//  Created by Ashish Awasthi on 30/07/26.
//

import XCTest

class DetailsScreen {

    var application: XCUIApplication

    init (application: XCUIApplication) {
        self.application = application
    }
    
    var navigationBar: XCUIElement {
        application.navigationBars.firstMatch
    }

    var backButton: XCUIElement {
        application.navigationBars.buttons.element(boundBy: 0)
    }
}
