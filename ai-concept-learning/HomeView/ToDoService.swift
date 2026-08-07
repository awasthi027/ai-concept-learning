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
        case resourceNotFound
    }

    private let resourceName = "ToDos"
    private let resourceExtension = "plist"

    func getToDo() throws -> [ToDo] {
        guard let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: resourceExtension
        ) else {
            throw DataSourceError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        return try decoder.decode([ToDo].self, from: data)
    }
}
