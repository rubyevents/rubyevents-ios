//
//  RoutePickerView.swift
//  RubyEvents
//

import AVKit
import SwiftUI

struct RoutePickerView: UIViewRepresentable {
  var tintColor: UIColor = .white

  func makeUIView(context: Context) -> AVRoutePickerView {
    let view = AVRoutePickerView()
    view.tintColor = tintColor
    view.activeTintColor = .systemBlue
    view.prioritizesVideoDevices = true
    return view
  }

  func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
    uiView.tintColor = tintColor
  }
}
