//
//  LargeTitleComponent.swift
//  RubyEvents
//
//  Created by Marco Roth on 24.01.2025.
//

import HotwireNative
import UIKit

final class LargeTitleComponent: BridgeComponent {
  override class var name: String { "title" }

  override func onReceive(message: Message) {
    guard let viewController else { return }

    addTitle(via: message, to: viewController)
  }

  private var viewController: UIViewController? {
    delegate.destination as? UIViewController
  }

  private func addTitle(via message: Message, to viewController: UIViewController) {
    guard let data: MessageData = message.data() else { return }

    viewController.navigationItem.title = data.title
    viewController.navigationController?.navigationBar.prefersLargeTitles = true
    
    self.reply(to: "connect")
  }
}

private extension LargeTitleComponent {
  struct MessageData: Decodable {
    let title: String
  }
}

