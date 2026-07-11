//
//  App.swift
//  RubyEvents
//
//  Created by Marco Roth on 17.01.2025.
//

import HotwireNative
import SwiftUI
import UIKit

class App {
  static var instance = App()

  var isTabbed: Bool = true

  var sceneDelegate: SceneDelegate?

  lazy var navigator = Navigator(delegate: self)
  lazy var tabBarController = TabBarController(app: self)

  var navigators: [Navigator] {
    if isTabbed {
      return tabBarController.navigators
    }
    return [navigator]
  }

  var viewControllers: [UIViewController] {
    navigators.map(\.rootViewController)
  }

  var window: UIWindow? {
    sceneDelegate?.window
  }

  var isDebug: Bool {
#if DEBUG
    return true
#else
    return false
#endif
  }

  var isTestFlight: Bool {
    Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
  }

  var environment: Environment {
    if isDebug {
      return .development
    }

    if isTestFlight {
      return .staging
    }

    return .production
  }

  func start(sceneDelegate: SceneDelegate) {
    self.sceneDelegate = sceneDelegate
    self.tabBarController.setupTabs()

    switchToTabController()

    NextEventUpdater.refresh()
    NextEventUpdater.scheduleBackgroundRefresh()

    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { _ in
      NextEventUpdater.refresh()
    }
  }

  func switchToNavigationController() {
    sceneDelegate?.window?.rootViewController = navigator.rootViewController
    self.isTabbed = false
  }

  func switchToTabController() {
    sceneDelegate?.window?.rootViewController = tabBarController
    self.isTabbed = true
  }

  func navigatorFor(title: String) -> Navigator? {
    tabBarController.navigatorFor(title: title)
  }

  func route(_ url: URL) {
    let target = webURL(from: url)

    guard isTabbed else {
      navigator.route(target)
      return
    }

    if let index = tabBarController.configuration?.items.firstIndex(where: { $0.title == "Events" }) {
      tabBarController.selectedIndex = index
    }

    (navigatorFor(title: "Events") ?? tabBarController.currentNavigator)?.route(target)
  }

  private func webURL(from url: URL) -> URL {
    guard url.scheme == "rubyevents" else { return url }

    let path = "/\(url.host ?? "")\(url.path)"

    return Router.instance.root_url().appendingPathComponent(path)
  }
}

extension App: NavigatorDelegate {
  func handle(proposal: VisitProposal) -> ProposalResult {
    switch proposal.viewController {
    case "home":
      let viewController = UIHostingController(
        rootView: HomeView(
          navigator: App.instance.navigatorFor(title: "Home")
        )
      )

      App.instance.tabBarController.hideNavigationBarFor(title: "Home")

      return .acceptCustom(viewController)
    default:
      App.instance.tabBarController.showNavigationBarFor(title: "Home")

      return .accept
    }
  }
}
