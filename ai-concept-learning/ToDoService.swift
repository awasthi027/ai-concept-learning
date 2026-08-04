//
//  ToDoService.swift
//  ai-concept-learning
//
//  Created by Ashish Awasthi on 17/07/26.
//

import Foundation

protocol ToDoServiceProtocol {
    func getToDo() throws -> [ToDo]
}

final class LocalToDoDataSource: ToDoServiceProtocol {

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
