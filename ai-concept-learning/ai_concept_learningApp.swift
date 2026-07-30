//
//  ai_concept_learningApp.swift
//  ai-concept-learning
//
//  Created by Ashish Awasthi on 30/07/26.
//

import SwiftUI

@main
struct ai_concept_learningApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(homeViewModel: HomeViewModel(toDoServiceProtocol: DatalayerClass()))
            }
        }
    }
}
