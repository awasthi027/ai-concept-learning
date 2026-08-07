//
//  TestProjectApplication.swift
//  TestProject
//
//  Created by Ashish Awasthi on 30/07/26.
//
import XCTest

struct TestApplicationInfo {
    let bundleIdentifier: String

    init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
    }
}

final class TestApplication: XCUIApplication {

    let applicationInfo: TestApplicationInfo

    init(applicationInfo: TestApplicationInfo) {
        self.applicationInfo = applicationInfo
        super.init(bundleIdentifier: applicationInfo.bundleIdentifier)
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
