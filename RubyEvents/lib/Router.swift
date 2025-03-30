import Foundation

class Router {
  static let instance = Router()

  func root_url() -> URL {
    Endpoint.url(environment: App.instance.environment)
  }

  func path_configuration_url() -> URL {
    root_url().appendingPathComponent("/hotwire/native/v1/ios/path_configuration.json")
  }
  
  func home_url() -> URL {
    root_url().appendingPathComponent("/home")
  }
  
  func home_json_url() -> URL {
    root_url().appendingPathComponent("/hotwire/native/v1/home.json")
  }
  
  func talks_url() -> URL {
    return root_url().appending(path: "/talks")
  }
  
  func topics_url() -> URL {
    return root_url().appending(path: "/topics")
  }
  
  func events_url() -> URL {
    return root_url().appending(path: "/events")
  }
  
  func speakers_url() -> URL {
    return root_url().appending(path: "/speakers")
  }
  
  func speaker_url(slug: String) -> URL {
    root_url().appendingPathComponent("/speakers/\(slug)/")
  }
}
