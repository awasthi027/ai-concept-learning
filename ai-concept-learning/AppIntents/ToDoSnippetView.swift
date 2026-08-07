//
//  ToDoSnippetView.swift
//  ai-concept-learning
//
//  Visual list snippet shown by ListToDosIntent in Siri / Shortcuts results.
//

import SwiftUI

struct ToDoSnippetView: View {

    let toDos: [ToDoEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if toDos.isEmpty {
                Text("No to-dos found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(toDos) { toDo in
                    ToDoSnippetRow(toDo: toDo)
                }
            }
        }
        .padding()
    }
}

struct ToDoSnippetRow: View {

    let toDo: ToDoEntity

    var body: some View {
        HStack {
            Text(toDo.title)
            Spacer()
            Text(toDo.status.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
