//
//  TalkCard.swift
//  RubyEvents
//
//  Created by Marco Roth on 24.01.2025.
//

import SwiftUI
import HotwireNative

struct TalkCard: View {
  let talk: Talk
  var navigator: Navigator?

  var body: some View {
    Button(action: {
      if (talk.url != nil) {
        navigator?.route(talk.url!)
      }
    }) {
      VStack(alignment: .leading, spacing: 8) {
        ZStack(alignment: .bottomTrailing) {
          AsyncImage(url: talk.thumbnail_url) { image in
            image
              .resizable()
              .scaledToFill()
              .aspectRatio(16 / 9, contentMode: .fill)
          } placeholder: {
            Rectangle()
              .frame(maxWidth: .infinity, maxHeight: 160)
              .foregroundColor(Color(hex: "#EFEFEF"))
          }

          .frame(width: 200, height: 120)
          .border(.gray, width: 1)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .overlay(
            RoundedRectangle(cornerRadius: 13)
              .stroke(Color(hex: "#EFEFEF"), lineWidth: 1)
          )

          if (talk.duration_in_seconds != nil) {
            Text(talk.formatted_duration())
              .font(.caption2)
              .bold()
              .foregroundColor(.white)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.black.opacity(0.7))
              .cornerRadius(4)
              .padding(8)
          }
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(talk.title)
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.tail)
            .fontWeight(.medium)
            .foregroundStyle(.black)

          Text("\(talk.speakers[0].name) • \(talk.event_name)")
            .font(.caption2)
            .foregroundColor(.gray)
            .fontWeight(.regular)
            .truncationMode(.tail)
            .lineLimit(1)
        }
      }
      .frame(maxWidth: 200)
      .aspectRatio(16/9, contentMode: .fit)
    }
  }
}

#Preview {
  ForEach(Talk.samples(), id: \.id) { talk in
    TalkCard(talk: talk).padding()
  }
}
