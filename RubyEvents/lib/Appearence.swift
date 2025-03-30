import UIKit

struct Appearance {
  static func configure() {
    configureNavigationBar()
  }

  private static func configureNavigationBar() {
    let navigationBarAppearance = UINavigationBarAppearance()
    navigationBarAppearance.configureWithDefaultBackground()
    navigationBarAppearance.backgroundColor = .clear

    UINavigationBar.appearance().standardAppearance = navigationBarAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    UINavigationBar.appearance().isOpaque = false
    UINavigationBar.appearance().isTranslucent = false
    UINavigationBar.appearance().tintColor = .black

    navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
  }
}
