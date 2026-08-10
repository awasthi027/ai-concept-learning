//
//  ExploreViewUITests.swift
//  ai-concept-learning
//
//  Created by Ashish Awasthi on 07/08/26.
//

import XCTest

final class ExploreViewUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExploreTabListingAndNavigationFlow() throws {
        let app = TestApplication(applicationInfo: TestApplicationInfo())
        app.launchArguments.append("-uiTestStubExplore")
        app.launch()
        XCTAssertTrue(app.exploreScreen.tabButton.waitForExistence(timeout: 2.0))
        app.exploreScreen.tabButton.tap()
        XCTAssertTrue(app.exploreScreen.navigationTitle.waitForExistence(timeout: 5.0))

        let firstRow = app.exploreScreen.firstRow
        XCTAssertTrue(firstRow.waitForExistence(timeout: 10.0))
        firstRow.tap()
        XCTAssertTrue(app.detailsScreen.navigationBar.waitForExistence(timeout: 5.0))
        app.detailsScreen.backButton.tap()
        XCTAssertTrue(app.exploreScreen.navigationTitle.waitForExistence(timeout: 2.0))
    }

}
