//
//  ToDoStatusAppEnum.swift
//  ai-concept-learning
//
//  A selectable status filter surfaced to Siri / Shortcuts as an App Intents enum.
//

import AppIntents

enum ToDoStatusFilter: String, AppEnum {

    case all
    case passed
    case pending
    case failed

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "To-Do Status")
    }

    static var caseDisplayRepresentations: [ToDoStatusFilter: DisplayRepresentation] {
        [
            .all: "All",
            .passed: "Passed",
            .pending: "Pending",
            .failed: "Failed"
        ]
    }

    func matches(_ status: ToDoStatus) -> Bool {
        switch self {
        case .all:
            return true
        case .passed:
            return status == .passed
        case .pending:
            return status == .pending
        case .failed:
            return status == .failed
        }
    }
}
