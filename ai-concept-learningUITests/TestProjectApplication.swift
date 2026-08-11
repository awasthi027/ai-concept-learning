//
//  TestProjectApplication.swift
//  TestProject
//
//  Created by Ashish Awasthi on 30/07/26.
//
import XCTest

struct TestApplicationInfo {
    let bundleIdentifier: String

    init(bundleIdentifier: String = "ashi.com.newLearning.ai-concept-learning") {
        self.bundleIdentifier = bundleIdentifier
    }
}

final class TestApplication: XCUIApplication {

    let applicationInfo: TestApplicationInfo

    init(applicationInfo: TestApplicationInfo) {
        self.applicationInfo = applicationInfo
        super.init()
    }

    /// Launches the app and tolerates a failed first launch on a cold CI
    /// simulator (which surfaces as "no process ID" / launch timeouts) by
    /// terminating and relaunching once before failing the test.
    func launchReliably(timeout: TimeInterval = 30.0) {
        launchArguments.append("-uiTesting")
        launch()
        if waitForRunning(timeout: timeout) {
            return
        }
        terminate()
        launch()
        _ = waitForRunning(timeout: timeout)
    }

    private func waitForRunning(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if state == .runningForeground {
                return true
            }
            _ = tabBars.firstMatch.waitForExistence(timeout: 1.0)
        }
        return state == .runningForeground
    }

    var homeScreen: HomeScreen {
        HomeScreen(application: self)
    }
    
    var detailsScreen: DetailsScreen {
        DetailsScreen(application: self)
    }

    var exploreScreen: ExploreScreen {
        ExploreScreen(application: self)
    }
}
