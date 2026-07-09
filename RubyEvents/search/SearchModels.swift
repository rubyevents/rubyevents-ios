//
//  SearchModels.swift
//  RubyEvents
//

import Foundation

// Config from /hotwire/native/v1/search_config.json

struct SearchConfig: Decodable {
  struct Node: Decodable {
    let host: String
    let port: Int
    let `protocol`: String
  }

  struct CollectionConfig: Decodable {
    let collection: String
    let query_by: String
    let query_by_weights: String?
    let filter_by: String?
  }

  let nodes: [Node]
  let nearest_node: Node?
  let search_api_key: String?
  let per_page: Int?
  let talks: CollectionConfig
  let speakers: CollectionConfig
  let events: CollectionConfig
}

struct SearchTalk: Codable {
  let id: String?
  let title: String
  let slug: String
  let thumbnail_url: String?
  let duration_in_seconds: Int32?
  let video_provider: String?
  let video_id: String?
  let event_name: String?
  let speakers: [SearchDocSpeaker]?

  struct SearchDocSpeaker: Codable {
    let id: Int64?
    let name: String
    let slug: String
  }

  private var derivedVideoURL: String? {
    switch video_provider {
    case "mp4": return video_id
    case "youtube": return video_id.map { "https://www.youtube.com/watch?v=\($0)" }
    case "vimeo": return video_id.map { "https://vimeo.com/video/\($0)" }
    default: return nil
    }
  }

  func toTalk() -> Talk {
    Talk(
      id: Int64(id ?? "") ?? 0,
      title: title,
      speakers: (speakers ?? []).map { Speaker(id: $0.id ?? 0, name: $0.name, slug: $0.slug, avatar_url: nil) },
      duration_in_seconds: duration_in_seconds,
      event_name: event_name ?? "",
      url: Router.instance.root_url().appendingPathComponent("/talks/\(slug)"),
      thumbnail_url: thumbnail_url.flatMap { URL(string: $0) },
      slug: slug
      // TODO: native player — add when the player branch's Talk model is integrated:
      // , video_provider: video_provider, video_id: video_id, video_url: derivedVideoURL
    )
  }
}

struct SearchSpeaker: Codable {
  let id: String?
  let name: String
  let slug: String
  let avatar_url: String?
  let github_handle: String?

  var avatarURL: URL? { avatar_url.flatMap { URL(string: $0) } }
  var profileURL: URL { Router.instance.speaker_url(slug: slug) }
}

struct SearchEvent: Codable {
  let id: String?
  let name: String
  let slug: String
  let city: String?
  let country_name: String?
  let avatar_url: String?
  let start_date_timestamp: Int64?
  let end_date_timestamp: Int64?

  var eventURL: URL { Router.instance.root_url().appendingPathComponent("/events/\(slug)") }

  var avatarURL: URL? {
    guard let avatar_url, !avatar_url.isEmpty else { return nil }
    if avatar_url.hasPrefix("http") { return URL(string: avatar_url) }

    return URL(string: Router.instance.root_url().appendingPathComponent(avatar_url).absoluteString)
  }

  var locationText: String? {
    let parts = [city, country_name].compactMap { $0 }.filter { !$0.isEmpty }

    return parts.isEmpty ? nil : parts.joined(separator: ", ")
  }

  var dateText: String? {
    guard let start = start_date_timestamp, start > 0 else { return nil }
    let startDate = Date(timeIntervalSince1970: TimeInterval(start))

    let full = DateFormatter()
    full.dateFormat = "MMM d, yyyy"

    if let end = end_date_timestamp, end > 0 {
      let endDate = Date(timeIntervalSince1970: TimeInterval(end))

      if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
        return full.string(from: startDate)
      }

      let short = DateFormatter()
      short.dateFormat = "MMM d"

      return "\(short.string(from: startDate)) – \(full.string(from: endDate))"
    }

    return full.string(from: startDate)
  }

  var subtitle: String? {
    [dateText, locationText].compactMap { $0 }.first.flatMap { _ in
      [dateText, locationText].compactMap { $0 }.joined(separator: " · ")
    }
  }
}
