//
//  AppIntent.swift
//  AIWidget
//
//  Created by Ashish Awasthi on 11/08/26.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription {
        IntentDescription("Shows a random product from the Explore tab.")
    }
}
