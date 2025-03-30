//
//  Talk.swift
//  RubyEvents
//
//  Created by Marco Roth on 24.01.2025.
//

import Foundation

struct Talk: Identifiable, Decodable {
  let id: Int64
  let title: String
  let speakers: [Speaker]
  let duration_in_seconds: Int32?
  let event_name: String
  let url: URL?
  let thumbnail_url: URL?
  let slug: String

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case speakers
    case duration_in_seconds
    case event_name
    case url
    case thumbnail_url
    case slug
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(Int64.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)
    speakers = try container.decode([Speaker].self, forKey: .speakers)
    duration_in_seconds = try container.decodeIfPresent(Int32.self, forKey: .duration_in_seconds)
    event_name = try container.decode(String.self, forKey: .event_name)

    if let urlString = try container.decodeIfPresent(String.self, forKey: .url) {
      url = URL(string: urlString)
    } else {
      url = nil
    }

    if let thumbnailString = try container.decodeIfPresent(String.self, forKey: .thumbnail_url) {
      thumbnail_url = URL(string: thumbnailString)
    } else {
      thumbnail_url = nil
    }

    slug = try container.decode(String.self, forKey: .slug)
  }

  init(id: Int64, title: String, speakers: [Speaker], duration_in_seconds: Int32?, event_name: String, url: URL?, thumbnail_url: URL?, slug: String) {
    self.id = id
    self.title = title
    self.speakers = speakers
    self.duration_in_seconds = duration_in_seconds
    self.event_name = event_name
    self.url = url
    self.thumbnail_url = thumbnail_url
    self.slug = slug
  }

  func formatted_duration() -> String {
    guard let seconds = duration_in_seconds else {
      return ""
    }

    let totalSeconds = Int(seconds)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let remainingSeconds = totalSeconds % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
    } else {
      return String(format: "%d:%02d", minutes, remainingSeconds)
    }
  }

  static func samples() -> [Talk] {
    return [
      Talk(
        id: 1,
        title: "The present and future of SQLite on Rails",
        speakers: [
          Speaker(id: 101, name: "Stephen Margheim", slug: "stephen-margheim")
        ],
        duration_in_seconds: 1800, // 30 minutes
        event_name: "Ruby Türkiye Meetup January 2025",
        url: Router.instance.root_url().appending(path: "/talks/the-present-and-future-of-sqlite-on-rails"),
        thumbnail_url: URL(string: "https://media.kommunity.com/communities/ruby-turkiye/events/the-present-and-future-of-sqlite-on-rails-79926ab2/70489/stephen.png"),
        slug: "the-present-and-future-of-sqlite-on-rails"
      ),

      Talk(
        id: 2,
        title: "Express Your Ideas by Writing Your Own Gems",
        speakers: [
          Speaker(id: 102, name: "Kasper Timm Hansen", slug: "kasper-timm-hansen")
        ],
        duration_in_seconds: 2400, // 40 minutes
        event_name: "Ruby Banitsa Conf 2024",
        url: Router.instance.root_url().appending(path: "/talks/express-your-ideas-by-writing-your-own-gems"),
        thumbnail_url: URL(string: "https://pbs.twimg.com/media/GeMpS7LWsAAfR-6?format=jpg"),
        slug: "express-your-ideas-by-writing-your-own-gems"
      ),

      Talk(
        id: 3,
        title: "SF Bay Area Ruby Meetup - December 2024",
        speakers: [
          Speaker(id: 103, name: "Irina Nazarova", slug: "irina-nazarova"),
          Speaker(id: 104, name: "Tillman Elser", slug: "tillman-elser"),
          Speaker(id: 105, name: "Justin Bowen", slug: "justin-bowen")
        ],
        duration_in_seconds: 5400, // 90 minutes
        event_name: "SF Bay Area Ruby Meetup - December 2024",
        url: Router.instance.root_url().appending(path: "/talks/sf-bay-area-ruby-meetup-december-2024"),
        thumbnail_url: URL(string: "https://i.ytimg.com/vi/NU7ld8ERUFY/sddefault.jpg"),
        slug: "sf-bay-area-ruby-meetup-december-2024"
      ),

      Talk(
        id: 4,
        title: "Panel Discussion",
        speakers: [
          Speaker(id: 106, name: "Gautam Rege", slug: "gautam-rege"),
          Speaker(id: 107, name: "Dutta Deshmukh", slug: "dutta-deshmukh"),
          Speaker(id: 108, name: "Surbhi Gupta", slug: "surbhi-gupta")
        ],
        duration_in_seconds: 3600, // 60 minutes
        event_name: "RubyConf India 2024",
        url: Router.instance.root_url().appending(path: "/talks/panel-discussion-rubyconf-india-2024"),
        thumbnail_url: URL(string: "https://i.ytimg.com/vi/VIS42lVAwfw/sddefault.jpg"),
        slug: "panel-discussion-rubyconf-india-2024"
      ),

      Talk(
        id: 5,
        title: "Compose Software Like Nature Would",
        speakers: [
          Speaker(id: 109, name: "Ahmed Omran", slug: "ahmed-omran")
        ],
        duration_in_seconds: 1800, // 30 minutes
        event_name: "RubyConf 2024",
        url: Router.instance.root_url().appending(path: "/talks/compose-software-like-nature-would"),
        thumbnail_url: URL(string: "https://i.ytimg.com/vi/bVBAvCm2mCs/sddefault.jpg"),
        slug: "compose-software-like-nature-would"
      ),

      Talk(
        id: 6,
        title: "Code Review Automation: Getting Rid of \"You Forgot To...\" Comments",
        speakers: [
          Speaker(id: 110, name: "Egor Iskrenkov", slug: "egor-iskrenkov")
        ],
        duration_in_seconds: 2700, // 45 minutes
        event_name: "Madrid.rb November 2024",
        url: Router.instance.root_url().appending(path: "/talks/code-review-automation-getting-rid-of-you-forgot-to-comments"),
        thumbnail_url: URL(string: "https://i.ytimg.com/vi/NDlpphmB1VU/sddefault.jpg"),
        slug: "code-review-automation-getting-rid-of-you-forgot-to-comments"
      ),

      Talk(
        id: 7,
        title: "Hotwire Native: Turn Your Rails App into a Mobile App",
        speakers: [
          Speaker(id: 111, name: "Yaroslav Shmarov", slug: "yaroslav-shmarov")
        ],
        duration_in_seconds: 2400, // 40 minutes
        event_name: "Paris.rb Meetup",
        url: Router.instance.root_url().appending(path: "/talks/hotwire-native-turn-your-rails-app-into-a-mobile-app"),
        thumbnail_url: URL(string: "https://i.ytimg.com/vi/25vqzypzTkQ/sddefault.jpg"),
        slug: "hotwire-native-turn-your-rails-app-into-a-mobile-app"
      ),

      Talk(
        id: 8,
        title: "Parsing with Prism in Sorbet",
        speakers: [
          Speaker(id: 112, name: "Emily Samp", slug: "emily-samp")
        ],
        duration_in_seconds: 1800, // 30 minutes
        event_name: "WNB.rb Meetup October 2024",
        url: Router.instance.root_url().appending(path: "/talks/parsing-with-prism-in-sorbet"),
        thumbnail_url: URL(string: "https://i.ytimg.com/vi/rnGMDz-2YVE/sddefault.jpg"),
        slug: "parsing-with-prism-in-sorbet"
      ),

      Talk(
        id: 9,
        title: "omakaseしないためのrubocop.yml のつくりかた",
        speakers: [
          Speaker(id: 113, name: "Shu Oogawara", slug: "shu-oogawara")
        ],
        duration_in_seconds: 1500, // 25 minutes
        event_name: "Kaigi on Rails 2024",
        url: Router.instance.root_url().appending(path: "/talks/omakase-rubocop-yml"),
        thumbnail_url: URL(string: "https://i.ytimg.com/vi/ZFpL3-RdUys/sddefault.jpg"),
        slug: "omakase-rubocop-yml"
      ),

      Talk(
        id: 10,
        title: "Game Show and Closing Remarks",
        speakers: [
          Speaker(id: 114, name: "Spike Ilacqua", slug: "spike-ilacqua"),
          Speaker(id: 115, name: "Bekki Freeman", slug: "bekki-freeman")
        ],
        duration_in_seconds: 1800, // 30 minutes
        event_name: "Rocky Mountain Ruby 2024",
        url: Router.instance.root_url().appending(path: "/talks/game-show-and-closing-remarks"),
        thumbnail_url: URL(string: "https://i.ytimg.com/vi/YK-fnF-CNxc/sddefault.jpg"),
        slug: "game-show-and-closing-remarks"
      ),
    ]
  }
}
