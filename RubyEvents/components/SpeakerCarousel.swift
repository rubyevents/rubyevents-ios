//
//  UserCarousel.swift
//  RubyEvents
//
//  Created by Marco Roth on 27.03.2025.
//

import SwiftUI
import HotwireNative

struct SpeakerCarousel: View {
  let title: String
  let speakers: [Speaker]
  let navigator: Navigator?
  let viewAllURL: URL?
  
  func navigateToProfile(speaker: Speaker) {
    let proposal = VisitProposal(
      url: speaker.profile_url,
      options: VisitOptions(),
      properties: ["tabs": false]
    )

    navigator?.route(proposal)
  }


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
        HStack(spacing: 8) {
          ForEach(speakers) { speaker in
            Button(action: { navigateToProfile(speaker: speaker) }) {
              VStack(alignment: .center) {
                  Avatar(
                    speaker: speaker
                  ).frame(width: 100, height: 100)
                    .padding(5)
                  
                  Text(speaker.name)
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 120, alignment: .center)
              }
              .frame(width: 120)
            }
          }
        }
        .padding(.horizontal, 16)
      }
    }.padding(.bottom, 16)
  }
}

#Preview {
  SpeakerCarousel(
    title: "Active Speakers",
    speakers: Speaker.samples() + Speaker.samples(),
    navigator: nil,
    viewAllURL: nil
  )
}
