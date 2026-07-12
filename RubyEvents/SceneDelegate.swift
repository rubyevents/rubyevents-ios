import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    App.instance.start(sceneDelegate: self)

    if let url = connectionOptions.urlContexts.first?.url ?? connectionOptions.userActivities.first?.webpageURL {
      routeAfterLaunch(url)
    }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url {
      App.instance.route(url)
    }
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if let url = userActivity.webpageURL {
      App.instance.route(url)
    }
  }

  private func routeAfterLaunch(_ url: URL) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      App.instance.route(url)
    }
  }
}
