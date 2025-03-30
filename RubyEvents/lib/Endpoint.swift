import Foundation

struct Endpoint {
  static let development = URL(string: "http://172.20.4.17:3000")!
  static let staging = URL(string: "https://rubyvideo.dev")!
  static let production = URL(string: "https://rubyvideo.dev")!

  static func url(environment: Environment = .development) -> URL {
    switch environment {
    case .development: return development
    case .staging: return staging
    case .production: return production
    }
  }
}
