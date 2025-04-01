import Foundation

struct Endpoint {
  static let development = URL(string: "http://172.20.4.17:3000")!
  static let staging = URL(string: "https://www.rubyevents.org")!
  static let production = URL(string: "https://www.rubyevents.org")!

  static func url(environment: Environment = .development) -> URL {
    switch environment {
    case .development: return development
    case .staging: return staging
    case .production: return production
    }
  }
}
