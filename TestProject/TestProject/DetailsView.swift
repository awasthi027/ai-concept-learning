//
//  DetailsView.swift
//  TestProject
//
//  Created by Ashish Awasthi on 30/07/26.
//

import SwiftUI

struct DetailsView: View {

    var toDo: ToDo
    
    var body: some View {
        VStack {
            Spacer()
            Text(toDo.title)
            Spacer()
        }
        .navigationTitle(toDo.title)
    }
}
