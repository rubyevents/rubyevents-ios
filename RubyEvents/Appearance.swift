import UIKit

struct Appearance {
  static func configure() {
    configureNavigationBar()
    configureTabBar()
  }
  
  private static func configureNavigationBar() {
    let navigationBarAppearance = UINavigationBarAppearance()
    navigationBarAppearance.configureWithDefaultBackground()
    UINavigationBar.appearance().standardAppearance = navigationBarAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    UINavigationBar.appearance().isOpaque = false
    UINavigationBar.appearance().isTranslucent = true
    navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
    
  }
  
  private static func configureTabBar() {
    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithDefaultBackground()
    tabBarAppearance.backgroundColor = UIColor.white
    UITabBar.appearance().standardAppearance = tabBarAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    UITabBar.appearance().isOpaque = true
    UITabBar.appearance().isTranslucent = false
    UITabBar.appearance().tintColor = .red
    UITabBar.appearance().unselectedItemTintColor = .black
  }
}
