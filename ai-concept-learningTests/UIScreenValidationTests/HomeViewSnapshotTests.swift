//
//  HomeViewSnapshotTests.swift
//  TestProject
//
//  Created by Ashish Awasthi on 30/07/26.
//

import Testing
import SwiftUI
@testable import ai_concept_learning

@MainActor
struct HomeViewSnapshotTests {

    @Test("TestToValidateHomeScreenUIChanges")
    func validateHomeScreen() async throws {
        let viewModel = HomeViewModel(toDoService: SnapshotDatalayer())
        try viewModel.makeRequestToGetNetworkData()

        let screen = NavigationStack {
            HomeView(homeViewModel: viewModel)
        }

        try SnapshotValidator.validate(screen, folder: "HomeView", name: "home_view.png")
    }

    @Test("TestToValidateDetailsScreenUIChanges")
    func validateDetailsScreen() async throws {
        let toDo = ToDo(id: 1, title: "Scaffold anchor points", status: .passed)

        let screen = NavigationStack {
            DetailsView(toDo: toDo)
        }

        try SnapshotValidator.validate(screen, folder: "DetailsView", name: "details_view.png")
    }
}

/// Deterministic data so snapshots stay stable across runs.
final class SnapshotDatalayer: ToDoServiceProtocol {
    func getToDo() throws -> [ToDo] {
        [
            ToDo(id: 1, title: "Scaffold anchor points", status: .passed),
            ToDo(id: 2, title: "Harness inspection - Zone B", status: .pending),
            ToDo(id: 3, title: "Electrical panel lockout", status: .failed),
            ToDo(id: 4, title: "Excavation shoring check", status: .passed),
            ToDo(id: 5, title: "Crane daily walkaround", status: .pending)
        ]
    }
}

