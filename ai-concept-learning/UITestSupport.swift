//
//  UITestSupport.swift
//  ai-concept-learning
//
//  Detects UI-test launches so the app can run deterministically offline
//  (stubbed Explore data, no live network) during automated UI tests.
//

#if DEBUG
import Foundation

enum UITestSupport {

    static let launchArgument = "-uiTesting"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }
}
#endif
