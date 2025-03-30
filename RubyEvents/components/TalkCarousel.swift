//
//  TalkCarousel.swift
//  RubyEvents
//
//  Created by Marco Roth on 24.01.2025.
//

import SwiftUI
import HotwireNative

struct TalkCarousel: View {
  let title: String
  let talks: [Talk]
  let navigator: Navigator?
  let viewAllURL: URL?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(title)
          .font(.headline)
          .bold()

        Spacer()

        Button(action: { if viewAllURL != nil { navigator?.route(viewAllURL!) } }) {
          Text("View All")
            .font(.subheadline)
            .foregroundColor(.blue)
        }
      }
      .padding(.horizontal, 16)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(talks) { talk in
            TalkCard(
              talk: talk,
              navigator: navigator
            )
          }
        }
        .padding(.horizontal, 16)
      }
    }.padding(.bottom, 16)
  }
}

#Preview {
  TalkCarousel(
    title: "Test",
    talks: Talk.samples(),
    navigator: nil,
    viewAllURL: nil
  )
}
