//
//  HomeView.swift
//  ai-concept-learning
//
//  Created by Ashish Awasthi on 17/07/26.
//

import SwiftUI

struct HomeView: View {

    let rowHeight: CGFloat = 40

    @StateObject var homeViewModel: HomeViewModel

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { homeViewModel.errorMessage != nil },
            set: { if !$0 { homeViewModel.errorMessage = nil } }
        )
    }

    var body: some View {
        ToDoListView(toDos: homeViewModel.list, rowHeight: rowHeight)
            .navigationDestination(for: ToDo.self) { item in
                DetailsView(toDo: item)
            }
            .navigationTitle("Home")
            .task {
                await homeViewModel.loadData()
            }
            .alert("Unable to load to-dos", isPresented: isShowingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(homeViewModel.errorMessage ?? "")
            }
    }
}

struct ToDoListView: View {

    let toDos: [ToDo]
    let rowHeight: CGFloat

    var body: some View {
        List(toDos, id: \.id) { item in
            NavigationLink(value: item) {
                ToDoRowView(toDo: item, rowHeight: rowHeight)
            }
            .accessibilityIdentifier("\(item.id)")
        }
        .accessibilityIdentifier("homeViewList")
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, rowHeight)
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
