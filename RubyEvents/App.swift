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
  
  private var currentUnreadMessagesCount: String?
  
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

      return .acceptCustom(viewController)
    default:
      return .accept
    }
  }
}
