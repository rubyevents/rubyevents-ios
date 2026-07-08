//
//  TalkPlayerScreen.swift
//  RubyEvents
//

import AVKit
import HotwireNative
import SwiftUI
import UIKit
import YouTubePlayerKit

struct PlayerParams {
  let slug: String?
  let url: URL?
  let title: String
  let subtitle: String?
  let poster: URL?
  let startAt: Double

  var statusLabel: String? = nil
  var youtubeVideoID: String? = nil
}

struct TalkPlayerScreen: View {
  @StateObject private var viewModel: PlayerViewModel
  @State private var detail: TalkDetail?
  @State private var isFullscreen = false
  @State private var showDescriptionSheet = false
  @State private var descriptionSheetFraction: CGFloat = 0.7
  @State private var dragOffset: CGFloat = 0

  @SwiftUI.Environment(\.verticalSizeClass) private var verticalSizeClass: UserInterfaceSizeClass?

  private var dragProgress: CGFloat {
    min(max(dragOffset / 300, 0), 1)
  }

  private let params: PlayerParams
  private let navigator: Navigator?
  private let onProgress: (Double) -> Void
  private let onDismiss: () -> Void

  init(params: PlayerParams, navigator: Navigator?, onProgress: @escaping (Double) -> Void, onDismiss: @escaping () -> Void, previewDetail: TalkDetail? = nil) {
    self.params = params
    self.navigator = navigator
    self.onProgress = onProgress
    self.onDismiss = onDismiss
    _detail = State(initialValue: previewDetail)
    _viewModel = StateObject(wrappedValue: PlayerViewModel(
      url: params.url,
      title: params.title,
      subtitle: params.subtitle,
      poster: params.poster,
      startAt: params.startAt,
      youtubeVideoID: params.youtubeVideoID
    ))
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        Color.black.opacity(1 - dragProgress).ignoresSafeArea()

        VStack(spacing: 0) {
          playerArea
            .frame(
              width: geo.size.width,
              height: isFullscreen ? geo.size.height : geo.size.width * 9.0 / 16.0
            )
            .gesture(dismissDragGesture)
            .zIndex(1)

          if !isFullscreen {
            ScrollView {
              detailContent
                .padding(.top, 16)
            }
            .background(Color(.systemBackground))
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .offset(y: dragOffset)
      }
      .onAppear {
        let full = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
        let videoBottom = geo.safeAreaInsets.top + geo.size.width * 9.0 / 16.0

        if full > 0 {
          descriptionSheetFraction = max(0.4, min(0.95, 1 - videoBottom / full))
        }
      }
    }
    .ignoresSafeArea(edges: isFullscreen ? .all : [])
    .task { await loadDetail() }
    .onChange(of: verticalSizeClass) { sizeClass in
      isFullscreen = (sizeClass == .compact)
    }
    .onAppear {
      viewModel.onProgress = onProgress
      viewModel.start()
    }
    .onDisappear { viewModel.teardown() }
  }

  private var dismissDragGesture: some Gesture {
    DragGesture(minimumDistance: 10, coordinateSpace: .global)
      .onChanged { value in
        guard !isFullscreen else { return }

        let translation = value.translation

        if translation.height > 0, translation.height > abs(translation.width) {
          dragOffset = translation.height
        }
      }
      .onEnded { _ in
        guard !isFullscreen else { return }

        if dragOffset > 120 {
          onDismiss()
        } else {
          withAnimation(.spring()) { dragOffset = 0 }
        }
      }
  }

  private func toggleFullscreen() {
    let goingFullscreen = !isFullscreen

    isFullscreen = goingFullscreen
    requestOrientation(goingFullscreen ? .landscapeRight : .portrait)
  }

  private func requestOrientation(_ mask: UIInterfaceOrientationMask) {
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first else { return }

    scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
  }

  private var playerArea: some View {
    ZStack {
      Color.black

      if params.url == nil && params.youtubeVideoID == nil {
        statusPlaceholder
      } else {
        if let youtubePlayer = viewModel.youtubePlayer {
          YouTubePlayerView(youtubePlayer)
            .allowsHitTesting(false)

          VStack(spacing: 0) {
            Rectangle()
              .fill(Color.black)
              .frame(height: 46)

            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
              .frame(height: 34)

            Spacer(minLength: 0)
          }
          .allowsHitTesting(false)
        } else {
          PlayerLayerView(player: viewModel.player) { layer in
            viewModel.setupPictureInPicture(with: layer)
          }
        }

        if let poster = params.poster, viewModel.currentTime == 0, !viewModel.isPlaying {
          AsyncImage(url: poster) { image in
            image.resizable().scaledToFit()
          } placeholder: {
            Color.black
          }
        }

        PlayerControlsView(
          viewModel: viewModel,
          title: detail?.title ?? params.title,
          subtitle: detail?.seriesName ?? params.subtitle,
          speakerName: detail?.speakerNames,
          eventAvatarURL: detail?.event?.avatarURL,
          isFullscreen: isFullscreen,
          onToggleFullscreen: toggleFullscreen,
          onDismiss: onDismiss
        )

        if (viewModel.isBuffering || viewModel.isSeeking) && !viewModel.isScrubbing {
          ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
            .scaleEffect(1.4)
            .allowsHitTesting(false)
        }
      }
    }
  }

  private var statusPlaceholder: some View {
    ZStack {
      if let poster = params.poster {
        AsyncImage(url: poster) { image in
          image.resizable().scaledToFit()
        } placeholder: {
          Color.black
        }
      }

      Color.black.opacity(0.55)

      VStack(spacing: 8) {
        Image(systemName: "clock")
          .font(.system(size: 34))
          .foregroundStyle(.white)

        Text(params.statusLabel ?? "")
          .font(.headline)
          .foregroundStyle(.white)
      }

      VStack {
        HStack {
          Button(action: onDismiss) {
            Image(systemName: "chevron.down")
              .font(.title3.weight(.semibold))
              .foregroundStyle(.white)
              .padding(10)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          Spacer()
        }

        Spacer()
      }
      .padding(4)
    }
  }

  private var detailContent: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(detail?.title ?? params.title)
        .font(.title2.bold())
        .foregroundStyle(.primary)

      HStack(spacing: 12) {
        if let date = detail?.formatted_date {
          Text(date)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        if let kind = detail?.kind, !kind.isEmpty {
          badge(kind.replacingOccurrences(of: "_", with: " ").uppercased())
        }
      }

      Divider()

      if let speaker = detail?.speakers.first {
        speakerRow(speaker)
      }

      if let descriptionText = [detail?.summary, detail?.description].compactMap({ $0 }).first(where: { !$0.isEmpty }) {
        descriptionSection(descriptionText)
      }

      if let event = detail?.event, event.name != nil {
        eventCard(event)
      }

      if let related = detail?.related_talks, !related.isEmpty {
        Text("Recommended")
          .font(.title3.bold())
          .padding(.top, 8)

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 16) {
            ForEach(related) { talk in
              TalkCard(talk: talk, navigator: navigator)
            }
          }
          .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 40)
  }

  private func badge(_ text: String) -> some View {
    Text(text)
      .font(.caption2.weight(.semibold))
      .tracking(0.5)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .overlay(
        Capsule().stroke(Color(.separator), lineWidth: 1)
      )
  }

  private func speakerRow(_ speaker: TalkSpeaker) -> some View {
    Button(action: { openSpeaker(speaker) }) {
      HStack(spacing: 10) {
        AsyncImage(url: speaker.avatarURL) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Circle().fill(Color(.secondarySystemBackground))
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 1) {
          let extra = (detail?.speakers.count ?? 0) - 1

          Text(extra > 0 ? "\(speaker.name) +\(extra)" : speaker.name)
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(1)

          if let handle = speaker.github_handle, !handle.isEmpty {
            Text("@\(handle)")
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Spacer()
      }
    }
    .buttonStyle(.plain)
  }

  private func eventCard(_ event: TalkEvent) -> some View {
    Button(action: { openEvent(event) }) {
      HStack(spacing: 12) {
        AsyncImage(url: event.avatarURL) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemBackground))
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 2) {
          Text("Recorded at")
            .font(.caption)
            .foregroundStyle(.secondary)

          Text(event.name ?? "")
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(2)

          let meta = [event.dateText, event.location].compactMap { $0 }.joined(separator: " · ")

          if !meta.isEmpty {
            Text(meta)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(12)
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
  }

  private func openEvent(_ event: TalkEvent) {
    guard let slug = event.slug else { return }
    let url = Router.instance.root_url().appendingPathComponent("/events/\(slug)")
    onDismiss()
    navigator?.route(url)
  }

  private func descriptionSection(_ text: String) -> some View {
    Button(action: { showDescriptionSheet = true }) {
      VStack(alignment: .leading, spacing: 8) {
        Text(text)
          .font(.body)
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
          .lineLimit(3)

        Text("VIEW MORE")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.blue)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .sheet(isPresented: $showDescriptionSheet) {
      descriptionSheet(text)
    }
  }

  private func descriptionSheet(_ text: String) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Description")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()

      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text(detail?.title ?? params.title)
            .font(.title3.bold())
            .foregroundStyle(.primary)

          Text(text).font(.body).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color(.systemBackground))
    .presentationDetents([.fraction(descriptionSheetFraction), .large])
    .presentationDragIndicator(.visible)
  }

  private func openSpeaker(_ speaker: TalkSpeaker) {
    let url = Router.instance.speaker_url(slug: speaker.slug)
    onDismiss()
    navigator?.route(url)
  }

  private func loadDetail() async {
    guard detail == nil else { return }
    guard let slug = params.slug, !slug.isEmpty else { return }
    let endpoint = Router.instance.root_url()
      .appendingPathComponent("/talks/\(slug).json")
      .absoluteString

    do {
      let response: TalkDetailResponse = try await APIService.shared.fetchData(from: endpoint)
      detail = response.talk

      let parts = [response.talk.speakerNames, response.talk.event?.name]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
      if !parts.isEmpty {
        viewModel.updateNowPlaying(artist: parts.joined(separator: " - "))
      }
    } catch {
      // Keep the bridged fallback metadata already shown; detail is best-effort.
    }
  }
}

#Preview {
  let speaker = TalkSpeaker(
    id: 1,
    name: "Aaron Patterson",
    slug: "aaron-patterson",
    bio: nil,
    avatar_url: "https://avatars.githubusercontent.com/u/3124?v=4",
    github_handle: "tenderlove"
  )

  let event = TalkEvent(
    slug: "rubyconf-2024",
    name: "RubyConf 2024",
    series: nil,
    avatar_url: nil,
    start_date: "2024-10-01",
    end_date: "2024-10-03",
    location: "Chicago, IL"
  )

  let detail = TalkDetail(
    id: 1,
    slug: "the-life-of-a-ruby-object",
    title: "The Life of a Ruby Object",
    description: "A deep dive into how Ruby objects are allocated, live, and are eventually collected — with plenty of live demos and a few surprises along the way.",
    summary: "A deep dive into how Ruby objects are allocated, live, and are eventually collected.",
    formatted_date: "October 1, 2024",
    kind: "talk",
    video_provider: "mp4",
    video_url: "https://assets.lrug.org/videos/2020/february/elena-tanasoiu-you-dont-know-what-you-dont-know-lrug-feb-2020.mp4",
    thumbnail_url: nil,
    duration_in_seconds: 1800,
    event: event,
    speakers: [speaker],
    related_talks: Talk.samples()
  )

  let params = PlayerParams(
    slug: detail.slug,
    url: URL(string: detail.video_url!)!,
    title: detail.title,
    subtitle: event.name,
    poster: nil,
    startAt: 0
  )

  return TalkPlayerScreen(
    params: params,
    navigator: nil,
    onProgress: { _ in },
    onDismiss: {},
    previewDetail: detail
  )
}
