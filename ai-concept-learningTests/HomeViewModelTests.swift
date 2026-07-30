//
//  HomeViewModelTests.swift
//  TestProject
//
//  Created by Ashish Awasthi on 30/07/26.
//


import Testing
@testable import ai_concept_learning
import Foundation

struct HomeViewModelTests {

    @Test("Test to Get JSON and validate values")
    @MainActor
    func validateValues() async throws {
        let viewModel = HomeViewModel(toDoServiceProtocol: TestDatalayer())
        await withCheckedContinuation { continuation in
            do {
                try viewModel.makeRequestToGetNetworkData()
                continuation.resume()
            } catch {
                print(error)
                continuation.resume()
            }
        }
        #expect(viewModel.list.count == 5)

    }
}

class TestDatalayer: ToDoServiceProtocol {
    func getToDo() throws -> [ToDo] {
        let dataString = """
        [
        { "id": 1, "title": "Scaffold anchor points", "status": "passed" },
        { "id": 2, "title": "Harness inspection - Zone B", "status": "pending" },
        { "id": 3, "title": "Electrical panel lockout", "status": "failed" },
        { "id": 4, "title": "Excavation shoring check", "status": "passed" },
        { "id": 5, "title": "Crane daily walkaround", "status": "pending" }]
      """
        do {
            let data = dataString.data(using: .utf8)!
            let decoder = JSONDecoder()
            let toDos: [ToDo] = try decoder.decode([ToDo].self, from: data)
            return toDos
        } catch let error {
           print("Error: \(error)")
            throw error
        }
    }
}
