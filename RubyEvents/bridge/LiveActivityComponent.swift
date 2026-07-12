//
//  LiveActivityComponent.swift
//  RubyEvents
//

import Foundation
import HotwireNative
import UIKit

final class LiveActivityComponent: BridgeComponent {
  override class var name: String { "live-activity" }

  override func onReceive(message: Message) {
    switch message.event {
    case "status":
      replyStatus(to: message)

    case "start":
      guard let data: StartData = message.data() else { return }

      Task {
        await LiveActivityManager.shared.start(eventSlug: data.slug, eventName: data.name ?? "")

        if LiveActivityManager.shared.isRunning {
          UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        replyStatus(to: message)
      }

    case "stop":
      Task {
        await LiveActivityManager.shared.stop()
        replyStatus(to: message)
      }

    default:
      break
    }
  }

  private func replyStatus(to message: Message) {
    let data: StartData? = message.data()
    let active = data.map { LiveActivityManager.shared.isActive(eventSlug: $0.slug) } ?? false

    reply(to: message.event, with: StatusReply(active: active))
  }

  private struct StartData: Decodable {
    let slug: String
    let name: String?
  }

  private struct StatusReply: Encodable {
    let active: Bool
  }
}
