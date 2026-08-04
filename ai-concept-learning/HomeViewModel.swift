//
//  HomeViewModel.swift
//  TestProject
//
//  Created by Ashish Awasthi on 17/07/26.
//



enum Result: String, Codable {
    case passed
    case pending
    case failed
}

struct ToDo: Codable, Hashable {
    let id: Int
    let title: String
    let status: Result
}

import Combine
import Foundation
class HomeViewModel: ObservableObject {

    @Published var list: [ToDo] = []
    @Published var errorMessage: String?
    var toDoServiceProtocol: ToDoServiceProtocol

    init(toDoServiceProtocol: ToDoServiceProtocol) {
        self.toDoServiceProtocol = toDoServiceProtocol
    }

    func makeRequestToGetNetworkData() throws  {
        do {
            list = try toDoServiceProtocol.getToDo()
        } catch let error {
           throw error
        }
    }

    @MainActor
    func loadData() async {
        do {
            list = try toDoServiceProtocol.getToDo()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

protocol ToDoServiceProtocol {
    func getToDo() throws -> [ToDo]
}

class ToDoNetworkServic: ToDoServiceProtocol {
    var toProtocol: ToDoServiceProtocol
    init(toProtocol: ToDoServiceProtocol) {
        self.toProtocol = toProtocol
    }

    func getToDo() throws -> [ToDo]  {
        try toProtocol.getToDo()
    }
}


class DatalayerClass: ToDoServiceProtocol {
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
