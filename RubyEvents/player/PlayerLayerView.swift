//
//  PlayerLayerView.swift
//  RubyEvents
//

import AVKit
import SwiftUI

struct PlayerLayerView: UIViewRepresentable {
  let player: AVPlayer
  var onLayerReady: ((AVPlayerLayer) -> Void)?

  func makeUIView(context: Context) -> PlayerContainerView {
    let view = PlayerContainerView()
    view.playerLayer.player = player
    view.playerLayer.videoGravity = .resizeAspect
    view.backgroundColor = .black
    onLayerReady?(view.playerLayer)
    return view
  }

  func updateUIView(_ uiView: PlayerContainerView, context: Context) {
    uiView.playerLayer.player = player
  }
}

final class PlayerContainerView: UIView {
  override static var layerClass: AnyClass { AVPlayerLayer.self }

  var playerLayer: AVPlayerLayer {
    layer as! AVPlayerLayer
  }
}
