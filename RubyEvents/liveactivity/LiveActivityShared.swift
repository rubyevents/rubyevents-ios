//
//  LiveActivityShared.swift
//  RubyEvents
//

import Foundation

enum LiveActivityShared {
  static let appGroupID = "group.org.rubyevents.RubyEvents"

  static var containerURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
  }

  static func imageURL(for filename: String) -> URL? {
    containerURL?.appendingPathComponent(filename)
  }
}
