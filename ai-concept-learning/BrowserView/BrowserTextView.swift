//
//  BrowserTextView.swift
//  ai-concept-learning
//
//  Text-view route reached after choosing "Open in Text View": shows a message
//  and a tappable link that opens the target website in the chosen browser.
//

import SwiftUI

struct BrowserTextView: View {

    @StateObject var textViewModel: BrowserTextViewModel

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { textViewModel.errorMessage != nil },
            set: { if !$0 { textViewModel.errorMessage = nil } }
        )
    }

    var body: some View {
        VStack {
            BrowserLinkTextView(
                message: textViewModel.message
            ) {
                Task {
                    await textViewModel.openLink()
                }
            }
            .accessibilityIdentifier("browserTextView")
        }
        .padding()
        .navigationTitle(textViewModel.title)
        .alert("Unable to open browser", isPresented: isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(textViewModel.errorMessage ?? "")
        }
    }
}
