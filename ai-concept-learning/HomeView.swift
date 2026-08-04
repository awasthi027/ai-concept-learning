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
    let nameURL: URL = URL(string: "https://jsonplaceholder.typicode.com/todos")!
    @StateObject var homeViewModel: HomeViewModel

    var body: some View {
        VStack {
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
        .onAppear() {
            Task {
                do {
                    try homeViewModel.makeRequestToGetNetworkData()
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
   // HomeView(homeViewModel: HomeViewModel())
}


