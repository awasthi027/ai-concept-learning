//
//  BrowserLinkTextView.swift
//  ai-concept-learning
//
//  UIKit-backed UITextView that renders a message followed by a tappable link.
//  Tapping the link is intercepted so the URL opens in the chosen target
//  browser instead of the default handler.
//

import SwiftUI
import UIKit

struct BrowserLinkTextView: UIViewRepresentable {

    let message: String
    let onOpen: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onOpen: onOpen)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = IntrinsicTextView()
       // textView.text = text
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.accessibilityIdentifier = "browserTextView"
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.onOpen = onOpen
        textView.text = message
        print("Message: \(message)")
       // textView.attributedText = makeAttributedText()
    }

//    private func makeAttributedText() -> NSAttributedString {
//        let font = UIFont.preferredFont(forTextStyle: .body)
//        let result = NSMutableAttributedString(
//            string: "\(message)\n\n",
//            attributes: [.font: font, .foregroundColor: UIColor.label]
//        )
//        result.append(
//            NSAttributedString(
//                string: linkText,
//                attributes: [.font: font, .link: url]
//            )
//        )
//        return result
//    }

    final class Coordinator: NSObject, UITextViewDelegate {

        var onOpen: () -> Void

        init(onOpen: @escaping () -> Void) {
            self.onOpen = onOpen
        }

        func textView(
            _ textView: UITextView,
            primaryActionFor textItem: UITextItem,
            defaultAction: UIAction
        ) -> UIAction? {
            UIAction { [onOpen] _ in
                onOpen()
            }
        }
    }
}


private class IntrinsicTextView: UITextView {

    //Intrinsic height is needed for UITextView so a private subclass is used.
    public override var bounds: CGRect {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    override public var intrinsicContentSize: CGSize {
        let size = sizeThatFits(CGSize(width: self.bounds.width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(size.height))
    }

}
