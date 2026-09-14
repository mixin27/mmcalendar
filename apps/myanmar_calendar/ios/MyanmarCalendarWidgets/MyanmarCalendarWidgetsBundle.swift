//
//  MyanmarCalendarWidgetsBundle.swift
//  MyanmarCalendarWidgets
//
//  Created by Kyaw Zayar Tun on 12/09/2026.
//

import WidgetKit
import SwiftUI

@main
struct MyanmarCalendarWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CompactDateWidget()
        MoonPhaseWidget()
        FullCalendarWidget()
        MyanmarMonthWidget()
    }
}
