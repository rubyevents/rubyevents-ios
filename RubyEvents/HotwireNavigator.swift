import HotwireNative
import Foundation
import UIKit
import WebKit
import YouTubePlayerKit

class HotwireNavigator {
  static let instance = HotwireNavigator()

  let sharedProcessPool = WKProcessPool()
  let router = Router(environment: .development)

  var window: UIWindow?
  var navigator: Navigator!
  var pathConfiguration: PathConfiguration

  private init(){
    self.pathConfiguration = PathConfiguration(sources: [
      .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!),
      .server(router.pathConfigurationURL())
    ])

    configureHotwire()
    self.navigator = Navigator(pathConfiguration: pathConfiguration, delegate: self)
  }

  func configureHotwire() {
    let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    let uniqueDeviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""

    Hotwire.config.userAgent = "Hotwire Native iOS; app_version: \(versionNumber); unique_device_id: \(uniqueDeviceId);"

    Hotwire.registerBridgeComponents([
      ButtonComponent.self
    ])

    Hotwire.config.makeCustomWebView = { configuration in
      configuration.processPool = self.sharedProcessPool
      configuration.defaultWebpagePreferences?.preferredContentMode = .mobile
      configuration.allowsInlineMediaPlayback = true

      let webView = WKWebView(frame: .zero, configuration: configuration)
      webView.allowsLinkPreview = false

      if #available(iOS 16.4, *) {
        webView.isInspectable = true
      }

      Bridge.initialize(webView)

      return webView
    }
  }

  func didStart(url: URL?, window: UIWindow?) {
    self.window = window
    self.window?.rootViewController = HotwireNavigator.instance.navigator.rootViewController

    navigator.route(router.rootURL())
    Appearance.configure()
  }
}

extension HotwireNavigator: NavigatorDelegate {
  func handle(proposal: VisitProposal) -> ProposalResult {
    switch proposal.viewController {
    case "player":
      let youTubePlayer = YouTubePlayer(
        source: .video(id: "psL_5RIBqnY"),
        configuration: .init(
          fullscreenMode: .system,
          autoPlay: true,
          showControls: false,
          useModestBranding: true,
          playInline: true,
          showRelatedVideos: false
        )
      )

      let playerViewController = YouTubePlayerViewController(
        player: youTubePlayer
      )

      return .acceptCustom(playerViewController)
    default:
      return .accept
    }
  }
}
