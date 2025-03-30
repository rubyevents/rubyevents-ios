import Foundation
import SwiftUI

struct Event: Hashable, Identifiable, Decodable {
  var id: Int64
  var name: String
  var slug: String
  var location: String
  var start_date: String
  var end_date: String
  var card_image_url: String?
  var featured_image_url: String?
  var featured_background: String
  var featured_color: String
  var url: URL

  var featureImage: Image? {
    featured_image_url != nil ? Image(featured_image_url!) : nil
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case name
    case slug
    case location
    case start_date
    case end_date
    case card_image_url
    case featured_image_url
    case featured_background
    case featured_color
    case url
  }

  init(
     id: Int64,
     name: String,
     slug: String,
     location: String,
     start_date: String,
     end_date: String,
     card_image_url: String? = nil,
     featured_image_url: String? = nil,
     featured_background: String = "#FFFFFF",
     featured_color: String = "#000000",
     url: URL
   ) {
     self.id = id
     self.name = name
     self.slug = slug
     self.location = location
     self.start_date = start_date
     self.end_date = end_date
     self.card_image_url = card_image_url
     self.featured_image_url = featured_image_url
     self.featured_background = featured_background
     self.featured_color = featured_color
     self.url = url
   }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(Int64.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    slug = try container.decode(String.self, forKey: .slug)

    location = try container.decodeIfPresent(String.self, forKey: .location) ?? "TBD"
    start_date = try container.decodeIfPresent(String.self, forKey: .start_date) ?? ""
    end_date = try container.decodeIfPresent(String.self, forKey: .end_date) ?? ""
    card_image_url = try container.decodeIfPresent(String.self, forKey: .card_image_url)
    featured_image_url = try container.decodeIfPresent(String.self, forKey: .featured_image_url)
    featured_background = try container.decodeIfPresent(String.self, forKey: .featured_background) ?? "#FFFFFF"
    featured_color = try container.decodeIfPresent(String.self, forKey: .featured_color) ?? "#000000"

    do {
      url = try container.decode(URL.self, forKey: .url)
    } catch {
      url = Router.instance.root_url().appending(path: "/events/\(id)")
    }
  }

  static var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
    return .useDefaultKeys
  }

  func formatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    return formatter
  }

  func startDate() -> Date? {
    return formatter().date(from: start_date)
  }

  func endDate() -> Date? {
    return formatter().date(from: end_date)
  }

  func dateString() -> String {
    let startDate = startDate()
    let endDate = endDate()

    guard let startDate = startDate else {
      return "Date TBD"
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM dd, yyyy"

    if let endDate = endDate {
      if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
        return formatter.string(from: startDate)
      } else {
        return formatter.string(from: startDate) + " - " + formatter.string(from: endDate)
      }
    }

    return formatter.string(from: startDate)
  }

  static func samples() -> [Event] {
    return [
      blueRidgeRuby(),
      rubyConf2024(),
      railsConf2024(),
      railsWorld2024()
    ]
  }

  static func blueRidgeRuby() -> Event {
    return Event(
      id: 1,
      name: "Blue Ridge Ruby 2024",
      slug: "blue-ridge-ruby-2024",
      location: "Asheville, NC",
      start_date: "2024-05-30",
      end_date: "2024-05-31",
      featured_image_url: "https://www.rubyvideo.dev/assets/events/blue-ridge-ruby/blue-ridge-ruby-2024/featured-d3f11d02.webp",
      featured_background: "#E1EFFA",
      featured_color: "#0C2866",
      url: Router.instance.root_url().appending(path: "/events/blue-ridge-ruby-2024")
    )
  }

  static func rubyConf2024() -> Event {
    return Event(
      id: 2,
      name: "RubyConf 2024",
      slug: "rubyconf-2024",
      location: "Chicago, IL",
      start_date: "2024-11-13",
      end_date: "2024-11-15",
      featured_image_url: "https://www.rubyvideo.dev/assets/events/rubyconf/rubyconf-2024/featured-a6512cb9.webp",
      featured_background: "#05061C",
      featured_color: "#FFFFFF",
      url: Router.instance.root_url().appending(path: "/events/rubyconf-2024")
    )
  }

  static func railsConf2024() -> Event {
    return Event(
      id: 3,
      name: "RailsConf 2024",
      slug: "rails-conf-2024",
      location: "Detroit, MI",
      start_date: "2024-05-07",
      end_date: "2024-05-09",
      featured_image_url: "https://www.rubyvideo.dev/assets/events/railsconf/railsconf-2024/featured-977c1ad4.webp",
      featured_background: "#231F20",
      featured_color: "#FFFFFF",
      url: Router.instance.root_url().appending(path: "/events/railsconf-2024")
    )
  }

  static func railsWorld2024() -> Event {
    return Event(
      id: 4,
      name: "Rails World 2024",
      slug: "rails-world-2024",
      location: "Toronto, Canada",
      start_date: "2024-09-23",
      end_date: "2024-09-24",
      featured_image_url: "https://www.rubyvideo.dev/assets/events/rails-world/rails-world-2024/featured-01bba711.webp",
      featured_background: "#4E2A73",
      featured_color: "#FFFFFF",
      url: Router.instance.root_url().appending(path: "/events/rails-world-2024")
    )
  }
}
