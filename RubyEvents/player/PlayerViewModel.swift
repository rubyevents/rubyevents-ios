//
//  PlayerViewModel.swift
//  RubyEvents
//

import AVKit
import UIKit
import Combine
import Foundation
import MediaPlayer
import YouTubePlayerKit

final class PlayerViewModel: NSObject, ObservableObject {
  @Published var isPlaying = false
  @Published var isBuffering = true
  @Published var currentTime: Double = 0
  @Published var duration: Double = 0
  @Published var isScrubbing = false
  @Published var rate: Float = 1.0

  let player: AVPlayer
  let rateOptions: [Float] = [1.0, 1.25, 1.5, 1.75, 2.0]

  var onProgress: ((Double) -> Void)?

  private var timeObserver: Any?
  private var statusObservation: NSKeyValueObservation?
  private var pipController: AVPictureInPictureController?
  private var lastReportedProgress: Double = 0
  private var hasStarted = false
  @Published private(set) var isSeeking = false

  private let nowPlayingTitle: String?
  private var nowPlayingArtist: String?
  private let nowPlayingArtworkURL: URL?

  let youtubePlayer: YouTubePlayer?
  var isYouTube: Bool { youtubePlayer != nil }

  private var cancellables = Set<AnyCancellable>()

  init(url: URL?, title: String?, subtitle: String?, poster: URL? = nil, startAt: Double = 0, youtubeVideoID: String? = nil) {
    nowPlayingTitle = title
    nowPlayingArtist = subtitle
    nowPlayingArtworkURL = poster

    if let youtubeVideoID {
      var configuration = YouTubePlayer.Configuration()

      configuration.autoPlay = true
      configuration.showControls = false
      configuration.showCaptions = false
      configuration.showFullscreenButton = false
      configuration.showRelatedVideos = false
      configuration.useModestBranding = true

      youtubePlayer = YouTubePlayer(source: .video(id: youtubeVideoID), configuration: configuration)
    } else {
      youtubePlayer = nil
    }

    if let url {
      let item = AVPlayerItem(url: url)
      item.externalMetadata = Self.metadata(title: title, subtitle: subtitle)
      player = AVPlayer(playerItem: item)
    } else {
      player = AVPlayer()
    }

    super.init()

    if let youtubePlayer {
      isBuffering = true
      observeYouTube(youtubePlayer)
    }

    guard player.currentItem != nil else {
      if youtubePlayer == nil { isBuffering = false }
      return
    }

    if startAt > 1 {
      player.seek(to: CMTime(seconds: startAt, preferredTimescale: 600))
    }

    addTimeObserver()

    statusObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
      let status = player.timeControlStatus

      DispatchQueue.main.async {
        self?.isBuffering = (status == .waitingToPlayAtSpecifiedRate)
        self?.isPlaying = (status == .playing)
      }
    }
  }

  func start() {
    guard !hasStarted else { return }
    guard isYouTube || player.currentItem != nil else { return }

    hasStarted = true

    configureAudioSession()
    setupRemoteCommands()
    loadArtwork()

    if isYouTube {
      isPlaying = true
    } else {
      player.playImmediately(atRate: rate)
      isPlaying = true
    }

    updateNowPlayingInfo()
  }

  func teardown() {
    reportProgress(force: true)
    
    if let youtubePlayer {
      Task { try? await youtubePlayer.pause() }
    }
    
    player.pause()
    removeTimeObserver()
    statusObservation?.invalidate()
    statusObservation = nil
    pipController = nil
    teardownRemoteCommands()
    
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  deinit {
    statusObservation?.invalidate()
    removeTimeObserver()
  }

  func togglePlay() {
    if isPlaying {
      pause()
    } else {
      play()
    }
  }

  func play() {
    configureAudioSession()

    if let youtubePlayer {
      Task { try? await youtubePlayer.play() }
    } else {
      player.playImmediately(atRate: rate)
    }

    isPlaying = true
    updateNowPlayingInfo()
  }

  func pause() {
    if let youtubePlayer {
      Task { try? await youtubePlayer.pause() }
    } else {
      player.pause()
    }

    isPlaying = false
    updateNowPlayingInfo()
  }

  func skip(by seconds: Double) {
    let upperBound = duration > 0 ? duration : currentTime + seconds

    seek(to: max(0, min(currentTime + seconds, upperBound)))
  }

  func seek(to seconds: Double) {
    currentTime = seconds
    isSeeking = true
    updateNowPlayingInfo()

    if let youtubePlayer {
      Task { try? await youtubePlayer.seek(to: Measurement(value: seconds, unit: UnitDuration.seconds), allowSeekAhead: true) }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.isSeeking = false }
      return
    }

    player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
      DispatchQueue.main.async { self?.isSeeking = false }
    }
  }

  func updateNowPlaying(artist: String) {
    nowPlayingArtist = artist
    updateNowPlayingInfo()
  }

  func cycleRate() {
    let index = rateOptions.firstIndex(of: rate) ?? 0
    rate = rateOptions[(index + 1) % rateOptions.count]

    if let youtubePlayer {
      Task { try? await youtubePlayer.set(playbackRate: Double(rate)) }
    } else if player.timeControlStatus == .playing {
      player.rate = rate
    }

    updateNowPlayingInfo()
  }

  private func observeYouTube(_ youtubePlayer: YouTubePlayer) {
    youtubePlayer.playbackStatePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        guard let self else { return }
        self.isPlaying = (state == .playing)
        self.isBuffering = (state == .buffering)
      }
      .store(in: &cancellables)

    youtubePlayer.currentTimePublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] measurement in
        guard let self, !self.isScrubbing, !self.isSeeking else { return }
        self.currentTime = measurement.converted(to: .seconds).value
        self.reportProgress(force: false)
      }
      .store(in: &cancellables)

    youtubePlayer.durationPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] measurement in
        let seconds = measurement.converted(to: .seconds).value
        if seconds.isFinite, seconds > 0 { self?.duration = seconds }
      }
      .store(in: &cancellables)
  }

  func setupPictureInPicture(with layer: AVPlayerLayer) {
    guard AVPictureInPictureController.isPictureInPictureSupported(), pipController == nil else { return }

    pipController = AVPictureInPictureController(playerLayer: layer)
    pipController?.canStartPictureInPictureAutomaticallyFromInline = true
  }

  private func addTimeObserver() {
    let interval = CMTime(seconds: 0.5, preferredTimescale: 600)

    timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      guard let self else { return }

      let playing = self.player.timeControlStatus == .playing

      if self.isPlaying != playing {
        self.isPlaying = playing
      }

      if let itemDuration = self.player.currentItem?.duration.seconds,
         itemDuration.isFinite, itemDuration > 0, self.duration != itemDuration {
        self.duration = itemDuration
        self.updateNowPlayingInfo()
      }

      if !self.isScrubbing, !self.isSeeking, time.seconds.isFinite {
        self.currentTime = time.seconds
      }

      self.reportProgress(force: false)
    }
  }

  private func removeTimeObserver() {
    if let timeObserver {
      player.removeTimeObserver(timeObserver)

      self.timeObserver = nil
    }
  }

  private func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      // Inline playback still works, we just won't get background audio
    }
  }

  private func setupRemoteCommands() {
    let center = MPRemoteCommandCenter.shared()

    center.playCommand.addTarget { [weak self] _ in self?.play(); return .success }
    center.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
    center.togglePlayPauseCommand.addTarget { [weak self] _ in self?.togglePlay(); return .success }

    center.skipForwardCommand.preferredIntervals = [10]
    center.skipForwardCommand.addTarget { [weak self] _ in self?.skip(by: 10); return .success }

    center.skipBackwardCommand.preferredIntervals = [10]
    center.skipBackwardCommand.addTarget { [weak self] _ in self?.skip(by: -10); return .success }

    center.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let self, let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

      self.seek(to: event.positionTime)

      return .success
    }
  }

  private func teardownRemoteCommands() {
    let center = MPRemoteCommandCenter.shared()

    [
      center.playCommand,
      center.pauseCommand,
      center.togglePlayPauseCommand,
      center.skipForwardCommand,
      center.skipBackwardCommand,
      center.changePlaybackPositionCommand
    ].forEach { $0.removeTarget(nil) }
  }

  private func updateNowPlayingInfo() {
    var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

    info[MPMediaItemPropertyTitle] = nowPlayingTitle ?? ""

    if let nowPlayingArtist { info[MPMediaItemPropertyArtist] = nowPlayingArtist }
    if duration > 0 { info[MPMediaItemPropertyPlaybackDuration] = duration }

    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(rate) : 0.0

    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  private func loadArtwork() {
    guard let url = nowPlayingArtworkURL else { return }

    URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data, let image = UIImage(data: data) else { return }

      let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }

      DispatchQueue.main.async {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyArtwork] = artwork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
      }
    }.resume()
  }

  private func reportProgress(force: Bool) {
    guard currentTime.isFinite else { return }

    if force || currentTime - lastReportedProgress >= 10 {
      lastReportedProgress = currentTime
      onProgress?(currentTime)
    }
  }

  private static func metadata(title: String?, subtitle: String?) -> [AVMetadataItem] {
    var items: [AVMetadataItem] = []

    if let title {
      items.append(metadataItem(.commonIdentifierTitle, value: title))
    }

    if let subtitle, !subtitle.isEmpty {
      items.append(metadataItem(.commonIdentifierArtist, value: subtitle))
    }

    return items
  }

  private static func metadataItem(_ identifier: AVMetadataIdentifier, value: String) -> AVMetadataItem {
    let item = AVMutableMetadataItem()

    item.identifier = identifier
    item.value = value as NSString
    item.extendedLanguageTag = "und"

    return item
  }
}
