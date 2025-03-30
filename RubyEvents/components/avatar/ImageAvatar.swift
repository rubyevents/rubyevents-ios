//
//  ImageAvatar.swift
//  RubyEvents
//
//  Created by Marco Roth on 15.01.2025.
//

import CachedAsyncImage
import SwiftUI

struct ImageAvatar: View {
  var name: String
  var url: String

  init(speaker: Speaker) {
    self.name = speaker.name
    self.url = speaker.avatar_url ?? ""
  }

  init(name: String, url: String) {
    self.name = name
    self.url = url
  }

  var fallback: some View {
    InitialsAvatar(name: name)
  }

  var placeholder: ((String) -> any View)? {
    { _ in fallback }
  }

  var image: (CPImage) -> any View {
    { image in
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .clipShape(Circle())
    }
  }

  var error: ((String, @escaping () -> Void) -> any View)? {
    { _, _ in
      fallback
    }
  }

  var body: some View {
    if url.isEmpty {
      fallback
    } else {
      CachedAsyncImage(
        url: url,
        placeholder: placeholder,
        image: image,
        error: error
      )
    }
  }
}

#Preview {
  VStack {
    ImageAvatar(speaker: Speaker.withAvatar())
      .frame(width: 100, height: 100)
      .padding(5)

    ImageAvatar(name: "Aaron Patterson", url: "https://cdn.bsky.app/img/avatar/plain/did:plc:3n6tlxabmocwe3nyl4b3rtjk/bafkreifsxp2tv45kucvjsnqo26qtbrbu2kgvimiykpynptjg6eqen4lhge@jpeg")
      .frame(width: 100, height: 100)
      .padding(5)
  }
}
