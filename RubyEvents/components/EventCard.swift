//
//  EventCard.swift
//  RubyEvents
//
//  Created by Marco Roth on 29.03.2025.
//

import SwiftUI
import HotwireNative

struct EventCard: View {
  let event: Event
  var navigator: Navigator?
  
  var body: some View {
    Button(action: {
      if (event.url != nil) {
        navigator?.route(event.url)
      }
    }) {
      VStack(alignment: .leading, spacing: 8) {
        ZStack(alignment: .bottomTrailing) {
          if (event.card_image_url != nil) {
            AsyncImage(url: URL(string: event.card_image_url!)) { image in
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
          } else {
            Text("No Image")
          }
          
          Text(event.location)
            .font(.caption2)
            .bold()
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.7))
            .cornerRadius(4)
            .padding(8)
        }
        
        VStack(alignment: .leading, spacing: 4) {
          Text(event.name)
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.tail)
            .fontWeight(.medium)
            .foregroundStyle(.black)
          
          Text(event.dateString())
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
  ForEach(Event.samples(), id: \.id) { event in
    EventCard(event: event).padding()
  }
}
