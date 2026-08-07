//
//  HomeViewModel.swift
//  ai-concept-learning
//
//  Created by Ashish Awasthi on 17/07/26.
//

import Combine
import Foundation

class HomeViewModel: ObservableObject {

    @Published var list: [ToDo] = []
    @Published var errorMessage: String?
    private let toDoService: ToDoServiceProtocol

    init(toDoService: ToDoServiceProtocol) {
        self.toDoService = toDoService
    }

    @MainActor
    func loadToDoSync() throws {
        list = try toDoService.getToDo()
    }

    @MainActor
    func loadData() async {
        do {
            list = try toDoService.getToDo()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
