//
//  RubyEventsWidgetsBundle.swift
//  RubyEventsWidgets
//
//  Created by Marco Roth on 09.07.2026.
//

import WidgetKit
import SwiftUI

@main
struct RubyEventsWidgetsBundle: WidgetBundle {
  var body: some Widget {
    NextEventWidget()
    RubyEventsWidgetsLiveActivity()
  }
}
