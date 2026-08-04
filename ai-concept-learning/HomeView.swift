//
//  ContentView.swift
//  TestProject
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
            if let errorMessage = homeViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            List(self.homeViewModel.list, id:\.id) { item in
                NavigationLink(value: item) {
                    HStack {
                        Text("\(item.id)")
                        Divider()
                        Text("\(item.title)")
                        Divider()
                        Text("\(item.status.rawValue)")
                    }
                    .frame(height: rowHeight)
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


#Preview {
    HomeView(homeViewModel: HomeViewModel(toDoService: LocalToDoDataSource()))
}


