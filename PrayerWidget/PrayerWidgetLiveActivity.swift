//
//  PrayerWidgetLiveActivity.swift
//  PrayerWidget
//
//  Created by Admin on 14/04/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PrayerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct PrayerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerWidgetAttributes.self) { context in
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
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension PrayerWidgetAttributes {
    fileprivate static var preview: PrayerWidgetAttributes {
        PrayerWidgetAttributes(name: "World")
    }
}

extension PrayerWidgetAttributes.ContentState {
    fileprivate static var smiley: PrayerWidgetAttributes.ContentState {
        PrayerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: PrayerWidgetAttributes.ContentState {
         PrayerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: PrayerWidgetAttributes.preview) {
   PrayerWidgetLiveActivity()
} contentStates: {
    PrayerWidgetAttributes.ContentState.smiley
    PrayerWidgetAttributes.ContentState.starEyes
}
