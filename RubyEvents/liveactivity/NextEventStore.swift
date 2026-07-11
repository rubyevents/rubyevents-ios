//
//  NextEventStore.swift
//  RubyEvents
//

import Foundation
import UIKit

struct NextEventSnapshot: Codable {
  var name: String
  var slug: String
  var location: String?
  var startAt: Date?
  var endAt: Date?
  var featuredBackground: String
  var featuredColor: String
  var bannerBackground: String
  var speakersCount: Int
  var participantsCount: Int
  var featuredImageFile: String?
  var avatarFiles: [String]
  var upcoming: [UpcomingItem]
}

struct UpcomingItem: Codable {
  var name: String
  var slug: String
  var startAt: Date?
  var featuredBackground: String
  var featuredColor: String
  var avatarFile: String?
}

enum NextEventStore {
  private static let filename = "next_event.json"

  static func save(_ snapshot: NextEventSnapshot) {
    guard let url = LiveActivityShared.imageURL(for: filename),
          let data = try? JSONEncoder().encode(snapshot) else { return }

    try? data.write(to: url, options: .atomic)
  }

  static func load() -> NextEventSnapshot? {
    guard let url = LiveActivityShared.imageURL(for: filename),
          let data = try? Data(contentsOf: url) else { return nil }

    return try? JSONDecoder().decode(NextEventSnapshot.self, from: data)
  }

  static func image(_ filename: String?) -> UIImage? {
    guard let filename, let url = LiveActivityShared.imageURL(for: filename) else { return nil }

    return UIImage(contentsOfFile: url.path)
  }
}
