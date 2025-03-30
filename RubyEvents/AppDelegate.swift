//
//  AppDelegate.swift
//  RubyEvents
//
//  Created by Marco Roth on 06.01.2025.
//

import HotwireNative
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    let uniqueDeviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""

    Hotwire.config.applicationUserAgentPrefix = "Hotwire Native iOS; app_version: \(versionNumber); unique_device_id: \(uniqueDeviceId);"

    Hotwire.registerBridgeComponents([
      ButtonComponent.self
    ])

    Hotwire.config.showDoneButtonOnModals = true
    Hotwire.config.debugLoggingEnabled = true

    Hotwire.loadPathConfiguration(from: [
      .server(Router.instance.path_configuration_url()),
      .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!)
    ])

    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
}
