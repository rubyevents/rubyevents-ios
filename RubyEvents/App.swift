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
  lazy var tabBarController = HotwireTabBarController(navigatorDelegate: self)
  
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
    window?.rootViewController = tabBarController
    Appearance.configure()
    tabBarController.load(HotwireTab.all)
  }
  
  func hideNavigationBar() {
    tabBarController.activeNavigator.rootViewController.navigationBar.isHidden = true
  }
  
  func showNavigationBar() {
    tabBarController.activeNavigator.rootViewController.navigationBar.isHidden = false
  }
}

extension App: NavigatorDelegate {
  func handle(proposal: VisitProposal, from navigator: Navigator) -> ProposalResult {
    switch proposal.viewController {
    case "home":
      let viewController = UIHostingController(
        rootView: HomeView(
          navigator: tabBarController.activeNavigator
        )
      )
      hideNavigationBar()
      return .acceptCustom(viewController)
    default:
      showNavigationBar()
      return .accept
    }
  }
}
