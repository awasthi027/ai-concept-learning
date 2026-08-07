//
//  ToDoAppShortcuts.swift
//  ai-concept-learning
//
//  Zero-setup phrases so users can invoke the app's intents from Siri and
//  Spotlight immediately after install.
//

import AppIntents

struct ToDoAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenToDoListIntent(),
            phrases: [
                "Open my to-do list in \(.applicationName)",
                "Open \(.applicationName) to-do list"
            ],
            shortTitle: "Open To-Do List",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: ListToDosIntent(),
            phrases: [
                "List my to-dos in \(.applicationName)",
                "Show all to-dos in \(.applicationName)"
            ],
            shortTitle: "List To-Dos",
            systemImageName: "list.bullet"
        )
        AppShortcut(
            intent: CountToDosIntent(),
            phrases: [
                "Count my to-dos in \(.applicationName)",
                "How many to-dos do I have in \(.applicationName)"
            ],
            shortTitle: "Count To-Dos",
            systemImageName: "number"
        )
        AppShortcut(
            intent: OpenExploreTabIntent(),
            phrases: [
                "Open Explore in \(.applicationName)",
                "Show explore in \(.applicationName)"
            ],
            shortTitle: "Open Explore",
            systemImageName: "globe"
        )
        AppShortcut(
            intent: OpenFirstProductIntent(),
            phrases: [
                "Open first product in \(.applicationName)",
                "Open a product in \(.applicationName)"
            ],
            shortTitle: "Open First Product",
            systemImageName: "shippingbox"
        )
        AppShortcut(
            intent: ShowRandomProductIntent(),
            phrases: [
                "Show random product in \(.applicationName)",
                "Show a product in \(.applicationName)"
            ],
            shortTitle: "Show Random Product",
            systemImageName: "photo"
        )
    }
}
