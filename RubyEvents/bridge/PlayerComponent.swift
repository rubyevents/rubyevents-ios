//
//  PlayerComponent.swift
//  RubyEvents
//

import UIKit
import SwiftUI
import HotwireNative

final class PlayerComponent: BridgeComponent {
  override class var name: String { "player" }

  private weak var presentedController: UIViewController?

  override func onReceive(message: Message) {
    switch message.event {
    case "play":
      handlePlay(message: message)
    default:
      break
    }
  }

  private var viewController: UIViewController? {
    delegate.destination as? UIViewController
  }

  private func handlePlay(message: Message) {
    guard let data: PlayData = message.data() else { return }
    guard let url = URL(string: data.url) else { return }
    guard let viewController else { return }

    let params = PlayerParams(
      slug: data.slug,
      url: url,
      title: data.title ?? "",
      subtitle: data.subtitle,
      poster: data.poster.flatMap(URL.init(string:)),
      startAt: max(data.progressSeconds ?? 0, data.startSeconds ?? 0)
    )

    let screen = TalkPlayerScreen(
      params: params,
      navigator: App.instance.navigators.first,
      onProgress: { [weak self] seconds in
        self?.reply(to: "play", with: PlayProgress(progressSeconds: seconds))
      },
      onDismiss: { [weak self] in
        self?.presentedController?.dismiss(animated: true)
      }
    )

    let hosting = UIHostingController(rootView: screen)

    hosting.modalPresentationStyle = .overFullScreen
    hosting.view.backgroundColor = .clear
    presentedController = hosting

    topPresentedController(from: viewController).present(hosting, animated: true)
  }

  private func topPresentedController(from controller: UIViewController) -> UIViewController {
    var top = controller

    while let presented = top.presentedViewController, !(presented is UIHostingController<TalkPlayerScreen>) {
      top = presented
    }

    return top
  }
}

private extension PlayerComponent {
  struct PlayData: Decodable {
    let slug: String?
    let url: String
    let title: String?
    let subtitle: String?
    let poster: String?
    let startSeconds: Double?
    let progressSeconds: Double?
    let durationSeconds: Double?
  }

  struct PlayProgress: Encodable {
    let progressSeconds: Double
  }
}
