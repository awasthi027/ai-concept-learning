//
//  HomeViewUITests.swift
//  TestProject
//
//  Created by Ashish Awasthi on 30/07/26.
//


import XCTest

final class HomeViewUITests: XCTestCase {

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
    func testListingAndNavigationflow() throws {
        let app = TestApplication(applicationInfo: TestApplicationInfo(bundleIdentifier: "ashi.com.newLearning.ai-concept-learning"))
        app.launch()
        XCTAssertTrue(app.homeScreen.navigationTitle.waitForExistence(timeout: 1.0))

        let firstItem = app.homeScreen.list.buttons["1"]
        XCTAssertTrue(firstItem.waitForExistence(timeout: 2.0))
        firstItem.tap()

        XCTAssertTrue(app.detailsScreen.navigationBar.waitForExistence(timeout: 2.0))
        app.detailsScreen.backButton.tap()
        XCTAssertTrue(app.homeScreen.navigationTitle.waitForExistence(timeout: 2.0))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
