import Foundation

struct Endpoint {
  static let development = URL(string: "http://192.168.1.244:3000")!
  static let staging = URL(string: "https://staging.rubyvideo.dev")!
  static let production = URL(string: "https://rubyvideo.dev")!

  static func url(environment: Environment = .development) -> URL {
    switch environment {
    case .development: return development
    case .staging: return staging
    case .production: return production
    }
  }
}
