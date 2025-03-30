//
//  TabBarController.swift
//  RubyEvents
//
//  Created by Marco Roth on 11.01.2025.
//

import HotwireNative
import UIKit

struct TabBarConfigurationItem {
  let title: String
  let icon: String
  let url: URL
  let position: Int
}

struct TabBarConfiguration {
  let items: [TabBarConfigurationItem]
}

class TabBarController: UITabBarController {
  var app: App
  var configuration: TabBarConfiguration?
  var navigators: [Navigator] = []
  var isSetup: Bool = false

  init(app: App) {
    self.app = app
    super.init(nibName: nil, bundle: nil)
  }

  func fixedTabBarItemFrom(item: TabBarConfigurationItem) -> FixedTabBarItem {
    FixedTabBarItem(
      title: item.title,
      image: UIImage(systemName: item.icon),
      tag: item.position
    )
  }

  func reloadAllTabs() {
    self.navigators.forEach { navigator in
      reloadTab(navigator: navigator)
    }
  }

  func reloadTab(title: String) {
    if let navigator = app.navigatorFor(title: title) {
      reloadTab(navigator: navigator)
    }
  }

  func reloadTab(navigator: Navigator) {
    navigator.rootViewController.popToRootViewController(animated: false)
    navigator.activeWebView.reload()
  }

  func navigatorFor(title: String) -> Navigator? {
    let index = configuration?.items.firstIndex { $0.self.title == title }

    guard let index else { return nil }

    return navigators[index]
  }

  var currentTab: String? {
    self.tabBar.selectedItem?.title
  }

  func hideTabBar() {
    self.tabBar.isHidden = true
  }

  func showTabBar() {
    self.tabBar.isHidden = false
  }

  func setupTabs() {
    setup(
      configuration: TabBarConfiguration(
        items: [
          TabBarConfigurationItem(
            title: "Home",
            icon: "house",
            url: Router.instance.home_url(),
            position: 0
          ),
          TabBarConfigurationItem(
            title: "Events",
            icon: "calendar",
            url: Router.instance.events_url(),
            position: 1
          ),
          TabBarConfigurationItem(
            title: "Talks",
            icon: "music.mic",
            url: Router.instance.talks_url(),
            position: 2
          ),
          TabBarConfigurationItem(
            title: "Speakers",
            icon: "person.fill",
            url: Router.instance.speakers_url(),
            position: 3
          )
        ]
      )
    )
  }

  func setup(configuration: TabBarConfiguration) {
    guard !isSetup else { return }

    self.configuration = configuration

    var tabBarItems: [FixedTabBarItem] = []

    configuration.items.forEach { item in
      let navigator = Navigator(delegate: app)
      self.navigators.append(navigator)

      navigator.route(item.url)

      tabBarItems.append(fixedTabBarItemFrom(item: item))
    }

    viewControllers = navigators.map(\.rootViewController)

    tabBarItems.enumerated().forEach { index, item in
      if let viewController = self.viewControllers?[index] {
//        viewController.tabBarController?.tabBar.tintColor = .white
//        viewController.tabBarController?.tabBar.barTintColor = .black
        viewController.tabBarItem = item
      }
    }

    let navigationBarAppearance = UINavigationBarAppearance()
    navigationBarAppearance.configureWithDefaultBackground()

    UINavigationBar.appearance().standardAppearance = navigationBarAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    UINavigationBar.appearance().isOpaque = false
    UINavigationBar.appearance().isTranslucent = true

    navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]

    self.isSetup = true
  }

  func reset() {
    self.isSetup = false
    self.configuration = nil
    self.navigators = []
    self.viewControllers = nil
    self.selectedIndex = 0
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

//    self.tabBar.backgroundColor = .white
//    self.tabBar.barStyle = .default
//    self.tabBar.isTranslucent = false
//    self.tabBar.isOpaque = false
//    self.tabBar.barTintColor = .white
//    self.tabBar.tintColor = .gray
  }
}
