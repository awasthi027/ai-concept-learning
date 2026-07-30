//
//  TestProjectApp.swift
//  TestProject
//
//  Created by Ashish Awasthi on 17/07/26.
//

import SwiftUI

@main
struct TestProjectApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(homeViewModel: HomeViewModel(toDoServiceProtocol: DatalayerClass()))
            }
        }
    }
}
