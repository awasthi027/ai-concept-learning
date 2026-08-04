//
//  ToDo.swift
//  ai-concept-learning
//
//  Created by Ashish Awasthi on 17/07/26.
//

import Foundation

enum ToDoStatus: String, Codable {
    case passed
    case pending
    case failed
}

struct ToDo: Codable, Hashable {
    let id: Int
    let title: String
    let status: ToDoStatus
}
