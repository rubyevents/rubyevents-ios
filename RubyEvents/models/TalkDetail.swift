//
//  TalkDetail.swift
//  RubyEvents
//

import Foundation

struct TalkDetailResponse: Decodable {
  let talk: TalkDetail
}

struct TalkDetail: Decodable {
  let id: Int64?
  let slug: String
  let title: String
  let description: String?
  let summary: String?
  let formatted_date: String?
  let kind: String?
  let video_provider: String
  let video_url: String?
  let thumbnail_url: String?
  let duration_in_seconds: Int32?
  let event: TalkEvent?
  let speakers: [TalkSpeaker]
  let related_talks: [Talk]?

  var videoURL: URL? {
    guard let video_url else { return nil }
    return URL(string: video_url)
  }

  var thumbnailURL: URL? {
    guard let thumbnail_url else { return nil }
    return URL(string: thumbnail_url)
  }

  var seriesName: String? {
    event?.series?.name ?? event?.name
  }

  var speakerNames: String {
    speakers.map(\.name).joined(separator: ", ")
  }
}

struct TalkEvent: Decodable {
  let slug: String?
  let name: String?
  let series: TalkSeries?
  let avatar_url: String?
  let start_date: String?
  let end_date: String?
  let location: String?

  var avatarURL: URL? {
    guard let avatar_url else { return nil }
    return URL(string: avatar_url)
  }

  var dateText: String? {
    guard let start_date else { return nil }

    let parser = DateFormatter()
    parser.locale = Locale(identifier: "en_US_POSIX")
    parser.dateFormat = "yyyy-MM-dd"
   
    guard let startDate = parser.date(from: start_date) else { return nil }

    let full = DateFormatter()
    full.dateFormat = "MMM d, yyyy"

    if let end_date, let endDate = parser.date(from: end_date), Calendar.current.startOfDay(for: endDate) != Calendar.current.startOfDay(for: startDate) {
      let short = DateFormatter()
      short.dateFormat = "MMM d"
     
      return "\(short.string(from: startDate)) – \(full.string(from: endDate))"
    }

    return full.string(from: startDate)
  }
}

struct TalkSeries: Decodable {
  let id: Int64?
  let name: String?
  let slug: String?
}

struct TalkSpeaker: Decodable, Identifiable {
  let id: Int64
  let name: String
  let slug: String
  let bio: String?
  let avatar_url: String?
  let github_handle: String?

  var avatarURL: URL? {
    guard let avatar_url else { return nil }
    return URL(string: avatar_url)
  }
}
