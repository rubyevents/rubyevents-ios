//
//  Speaker.swift
//  RubyEvents
//
//  Created by Marco Roth on 15.01.2025.
//

import Foundation

struct Speaker: Identifiable, Decodable {
  var id: Int64
  var name: String
  var slug: String
  var avatar_url: String?

  var profile_url: URL {
    Router.instance.speaker_url(slug: self.slug)
  }

  static func withAvatar() -> Self {
    Self(
      id: 1,
      name: "Aaron Patterson",
      slug: "aaron-patterson",
      avatar_url: "https://avatars.githubusercontent.com/u/3124?v=4"
    )
  }

  static func withNoAvatar() -> Self {
    Self(
      id: 1,
      name: "Aaron Patterson",
      slug: "aaron-patterson",
      avatar_url: nil
    )
  }

  static func samples() -> [Self] {
    [
      withAvatar(),
      withNoAvatar()
    ]
  }
}
