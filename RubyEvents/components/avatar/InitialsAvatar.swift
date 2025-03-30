//
//  InitialsAvatar.swift
//  RubyEvents
//
//  Created by Marco Roth on 15.01.2025.
//

import SwiftUI

struct InitialsAvatar: View {
  var initials: String
  var size: CGFloat = 50

  static func computedInitials(name: String) -> String {
    let parts = name.split(separator: " ")
    let startingLetters = parts.map { $0.prefix(1) }.joined()

    return String(startingLetters.prefix(3)).uppercased()
  }

  init(speaker: Speaker) {
    self.initials = Self.computedInitials(name: speaker.name)
  }

  init(name: String) {
    self.initials = Self.computedInitials(name: name)
  }

  init(initials: String) {
    self.initials = initials
  }

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let height = geometry.size.height

      ZStack {
        Circle().fill(.accent)

        Text(initials)
          .foregroundColor(.white)
          .bold()
          .font(.system(size: min(width, height) * 0.4))
          .lineLimit(1)
          .minimumScaleFactor(0.1)
      }
    }
  }
}

#Preview {
  VStack {
    InitialsAvatar(speaker: Speaker.withNoAvatar()).frame(width: 150, height: 150)
    InitialsAvatar(name: "Aaaron Patterson").frame(width: 100, height: 100)
    InitialsAvatar(initials: "AR").frame(width: 50, height: 50)
  }
}
