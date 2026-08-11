//
//  AIWidgetLiveActivity.swift
//  AIWidget
//
//  Created by Ashish Awasthi on 11/08/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AIWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AIWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AIWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .keylineTint(Color.red)
        }
    }
}

extension AIWidgetAttributes {
    fileprivate static var preview: AIWidgetAttributes {
        AIWidgetAttributes(name: "World")
    }
}

extension AIWidgetAttributes.ContentState {
    fileprivate static var smiley: AIWidgetAttributes.ContentState {
        AIWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AIWidgetAttributes.ContentState {
         AIWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AIWidgetAttributes.preview) {
   AIWidgetLiveActivity()
} contentStates: {
    AIWidgetAttributes.ContentState.smiley
    AIWidgetAttributes.ContentState.starEyes
}
