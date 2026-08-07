//
//  ToDoNavigator.swift
//  ai-concept-learning
//
//  Shared routing state that App Intents use to drive in-app navigation.
//

import Combine
import SwiftUI

enum AppTab: Hashable {
    case home
    case explore
}

final class ToDoNavigator: ObservableObject {

    static let shared = ToDoNavigator()

    @Published var selectedTab: AppTab = .home
    @Published var path = NavigationPath()
    @Published var explorePath = NavigationPath()

    private init() {}

    @MainActor
    func showToDoList() {
        selectedTab = .home
        path = NavigationPath()
    }

    @MainActor
    func showExplore() {
        selectedTab = .explore
        explorePath = NavigationPath()
    }

    @MainActor
    func open(product: RemoteContent) {
        selectedTab = .explore
        explorePath = NavigationPath()
        explorePath.append(product)
    }
}
