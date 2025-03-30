//
//  EventCarousel.swift
//  RubyEvents
//
//  Created by Marco Roth on 24.01.2025.
//

import SwiftUI
import HotwireNative

struct NoAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1 : 1) // No scaling
            .animation(nil, value: configuration.isPressed) // Disable animation
    }
}


struct FeaturedCarousel: View {
  var events: [Event]
  var navigator: Navigator?

  var body: some View {
    TabView {
      ForEach(events) { event in
        Button(action: {
          navigator?.route(event.url)
        }) {
          FeaturedCard(
            event: event,
            navigator: navigator
          )
        }.buttonStyle(NoAnimationButtonStyle())
      }
    }
    .tabViewStyle(
      PageTabViewStyle(indexDisplayMode: .always)
    )
    .animation(.easeInOut, value: events)
    .edgesIgnoringSafeArea(.all)
  }
}

#Preview {
  FeaturedCarousel(events: [
    Event.blueRidgeRuby(),
    Event.railsConf2024(),
    Event.railsWorld2024(),
    Event.rubyConf2024()
  ])
}
