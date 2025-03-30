//
//  Avatar.swift
//  RubyEvents
//
//  Created by Marco Roth on 25.01.2025.
//

import SwiftUI

struct Avatar: View {
  var name: String
  var url: String?

  init(speaker: Speaker) {
    self.name = speaker.name
    self.url = speaker.avatar_url
  }

  init(name: String, url: String?) {
    self.name = name
    self.url = url
  }

  var hasImage: Bool {
    (url != nil && !url!.isEmpty)
  }

  var body: some View {
    if hasImage {
      ImageAvatar(name: name, url: url!)
    } else {
      InitialsAvatar(name: name)
    }
  }
}

#Preview {
  VStack {
    Avatar(speaker: Speaker.withAvatar())
      .frame(width: 100, height: 100)
      .padding(5)

    Avatar(speaker: Speaker.withNoAvatar())
      .frame(width: 100, height: 100)
      .padding(5)

    Avatar(name: "Aaron Patterson", url: "https://cdn.bsky.app/img/avatar/plain/did:plc:3n6tlxabmocwe3nyl4b3rtjk/bafkreifsxp2tv45kucvjsnqo26qtbrbu2kgvimiykpynptjg6eqen4lhge@jpeg")
      .frame(width: 100, height: 100)
      .padding(5)
  }
}
