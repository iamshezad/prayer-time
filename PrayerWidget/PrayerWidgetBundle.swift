//
//  PrayerWidgetBundle.swift
//  PrayerWidget
//
//  Created by Admin on 14/04/24.
//

import WidgetKit
import SwiftUI

@main
struct PrayerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerWidget()
        PrayerWidgetLiveActivity()
    }
}
