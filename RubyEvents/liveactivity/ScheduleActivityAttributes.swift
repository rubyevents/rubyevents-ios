//
//  ScheduleActivityAttributes.swift
//  RubyEvents
//

import ActivityKit
import Foundation

struct ScheduleActivityAttributes: ActivityAttributes {
  public struct SessionTalk: Codable, Hashable {
    var title: String
    var speakers: String
    var track: String?
    var trackColor: String? // hex
    var avatarFile: String?
  }

  public struct ContentState: Codable, Hashable {
    var talks: [SessionTalk]
    var sessionStart: Date
    var sessionEnd: Date
    var isLive: Bool
    var nextTitle: String?
    var nextSpeakers: String?
    var nextTrack: String?
    var nextTrackColor: String?
    var nextSpeakerAvatarFile: String?
    var nextStart: Date?
  }

  var eventName: String
  var eventSlug: String
  var featuredBackground: String // hex
  var featuredColor: String // hex
  var eventAvatarFile: String?
  var scheduleURL: String
}
