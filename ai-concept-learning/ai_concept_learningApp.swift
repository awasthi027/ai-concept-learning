//
//  ai_concept_learningApp.swift
//  ai-concept-learning
//
//  Created by Ashish Awasthi on 30/07/26.
//

import SwiftUI

@main
struct ai_concept_learningApp: App {

    @StateObject private var navigator = ToDoNavigator.shared

    var body: some Scene {
        WindowGroup {
            TabView(selection: $navigator.selectedTab) {
                NavigationStack(path: $navigator.path) {
                    HomeView(
                        homeViewModel: HomeViewModel(toDoService: LocalToDoDataSource())
                    )
                }
                .tabItem {
                    Label("Home", systemImage: "checklist")
                }
                .tag(AppTab.home)
                .accessibilityIdentifier("homeTab")

                NavigationStack(path: $navigator.explorePath) {
                    ExploreView(exploreViewModel: Self.makeExploreViewModel())
                }
                .tabItem {
                    Label("Explore", systemImage: "globe")
                }
                .tag(AppTab.explore)
                .accessibilityIdentifier("exploreTab")
            }
            .accessibilityIdentifier("appTabView")
        }
    }

    private static func makeExploreViewModel() -> ExploreViewModel {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(StubRemoteContentService.launchArgument) {
            return ExploreViewModel(remoteService: StubRemoteContentService())
        }
        #endif
        return ExploreViewModel()
    }
}
