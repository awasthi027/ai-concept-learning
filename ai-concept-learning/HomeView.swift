//
//  HomeView.swift
//  ai-concept-learning
//
//  Created by Ashish Awasthi on 17/07/26.
//

import SwiftUI
import Foundation

struct HomeView: View {

    let rowHeight: CGFloat = 40

    @StateObject var homeViewModel: HomeViewModel

    var body: some View {
        VStack {
            List(homeViewModel.list, id: \.id) { item in
                NavigationLink(value: item) {
                    ToDoRowView(toDo: item, rowHeight: rowHeight)
                }
                .accessibilityIdentifier("\(item.id)")
            }
            .accessibilityIdentifier("homeViewList")
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, rowHeight)
        }
        .navigationDestination(for: ToDo.self) { item in
            DetailsView(toDo: item)
        }
        .navigationTitle("Home")
        .task {
            await homeViewModel.loadData()
        }
    }
}

struct ToDoRowView: View {

    let toDo: ToDo
    let rowHeight: CGFloat

    var body: some View {
        HStack {
            Text("\(toDo.id)")
            Divider()
            Text(toDo.title)
            Divider()
            Text(toDo.status.rawValue)
        }
        .frame(height: rowHeight)
    }
}

#Preview {
    HomeView(homeViewModel: HomeViewModel(toDoService: LocalToDoDataSource()))
}
