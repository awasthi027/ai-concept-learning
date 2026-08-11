//
//  AIWidgetBundle.swift
//  AIWidget
//
//  Created by Ashish Awasthi on 11/08/26.
//

import WidgetKit
import SwiftUI

@main
struct AIWidgetBundle: WidgetBundle {
    var body: some Widget {
        AIWidget()
        AIWidgetControl()
        AIWidgetLiveActivity()
    }
}
