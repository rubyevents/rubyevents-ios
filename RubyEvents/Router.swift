import Foundation

class Router {
  var environment: Environment

  init(environment: Environment) {
    self.environment = environment
  }

  func rootURL() -> URL {
    return Endpoint.url(environment: environment)
  }

  func pathConfigurationURL() -> URL {
    return rootURL().appending(path: "/path-configuration.json")
  }
}
