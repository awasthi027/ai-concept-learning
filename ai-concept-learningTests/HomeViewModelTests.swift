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

    @Test("Test to Get JSON and count the values")
    @MainActor
    func validateCounts() async throws {
        let viewModel = HomeViewModel(toDoService: TestDatalayer())
        await withCheckedContinuation { continuation in
            do {
                try viewModel.loadToDoSync()
                continuation.resume()
            } catch {
                print(error)
                continuation.resume()
            }
        }
        #expect(viewModel.list.count == 5)

    }

    @Test("Test to Get JSON and validate values")
    @MainActor
    func validateValues() async throws {
        let viewModel = HomeViewModel(toDoService: TestDatalayer())
        await withCheckedContinuation { continuation in
            do {
                try viewModel.loadToDoSync()
                continuation.resume()
            } catch {
                print(error)
                continuation.resume()
            }
        }

        guard let firstItem = viewModel.list.first else {
            #expect(viewModel.list.count > 0)
            return
        }
        #expect(firstItem.id == 1)
        #expect(firstItem.title == "Scaffold anchor points")
        #expect(firstItem.status == .passed)
    }
}

class TestDatalayer: ToDoServiceProtocol {

    private enum DataSourceError: Error {
        case invalidEncoding
    }

    func getToDo() throws -> [ToDo] {
        let dataString = """
        [
        { "id": 1, "title": "Scaffold anchor points", "status": "passed" },
        { "id": 2, "title": "Harness inspection - Zone B", "status": "pending" },
        { "id": 3, "title": "Electrical panel lockout", "status": "failed" },
        { "id": 4, "title": "Excavation shoring check", "status": "passed" },
        { "id": 5, "title": "Crane daily walkaround", "status": "pending" }]
        """
        guard let data = dataString.data(using: .utf8) else {
            throw DataSourceError.invalidEncoding
        }
        let decoder = JSONDecoder()
        return try decoder.decode([ToDo].self, from: data)
    }
}
