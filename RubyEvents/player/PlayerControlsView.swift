//
//  PlayerControlsView.swift
//  RubyEvents
//

import SwiftUI

struct PlayerControlsView: View {
  @ObservedObject var viewModel: PlayerViewModel
  let title: String
  let subtitle: String?
  let speakerName: String?
  let eventAvatarURL: URL?
  let isFullscreen: Bool
  var onToggleFullscreen: () -> Void
  var onDismiss: () -> Void

  @State private var controlsVisible = true
  @State private var hideTask: Task<Void, Never>?
  @State private var leftFlash = false
  @State private var rightFlash = false

  var body: some View {
    ZStack {
      HStack(spacing: 0) {
        skipZone(seconds: -10, systemImage: "gobackward.10", flashing: $leftFlash)
        skipZone(seconds: 10, systemImage: "goforward.10", flashing: $rightFlash)
      }

      if controlsVisible {
        Color.black.opacity(0.35)
          .allowsHitTesting(false)
          .transition(.opacity)
      }

      if controlsVisible {
        VStack(spacing: 0) {
          topBar
          Spacer()

          if !isLoading {
            centerTransport
          }

          Spacer()
          bottomInfoRow
        }
        .padding(isFullscreen ? 24 : 12)
        .padding(.bottom, isFullscreen ? 18 : 12)
        .transition(.opacity)
      }

      if controlsVisible {
        scrubber
          .padding(.horizontal, 8)
          .padding(.bottom, isFullscreen ? 24 : -6)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: controlsVisible)
    .onAppear { scheduleAutoHide() }
    .onChange(of: viewModel.isPlaying) { _ in scheduleAutoHide() }
    .onChange(of: isFullscreen) { _ in
      hideTask?.cancel()
      controlsVisible = true
      scheduleAutoHide()
    }
  }

  private var topBar: some View {
    HStack(alignment: .top) {
      if isFullscreen {
        HStack(spacing: 10) {
          if let eventAvatarURL {
            AsyncImage(url: eventAvatarURL) { image in
              image.resizable().scaledToFill()
            } placeholder: {
              RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15))
            }
            .frame(width: 34, height: 34)
            .clipShape(RoundedRectangle(cornerRadius: 6))
          }

          VStack(alignment: .leading, spacing: 2) {
            Text(title)
              .font(.headline)
              .foregroundStyle(.white)
              .lineLimit(1)

            if let speakerName, !speakerName.isEmpty {
              Text(speakerName)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
            } else if let subtitle {
              Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
            }
          }
        }
      } else {
        Button(action: onDismiss) {
          Image(systemName: "chevron.down")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 38, height: 38)
            .background(.ultraThinMaterial, in: Circle())
            .environment(\.colorScheme, .dark)
        }
        .buttonStyle(.plain)
      }

      Spacer()

      HStack(spacing: 12) {
        RoutePickerView()
          .frame(width: 28, height: 28)

        Button(action: onToggleFullscreen) {
          Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 38, height: 38)
            .background(.ultraThinMaterial, in: Circle())
            .environment(\.colorScheme, .dark)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var centerTransport: some View {
    HStack(spacing: 40) {
      transportButton(icon: "gobackward.10", iconSize: 26, diameter: 60) {
        viewModel.skip(by: -10); scheduleAutoHide()
      }

      transportButton(icon: viewModel.isPlaying ? "pause.fill" : "play.fill", iconSize: 34, diameter: 74) {
        viewModel.togglePlay(); scheduleAutoHide()
      }

      transportButton(icon: "goforward.10", iconSize: 26, diameter: 60) {
        viewModel.skip(by: 10); scheduleAutoHide()
      }
    }
  }

  private func transportButton(icon: String, iconSize: CGFloat, diameter: CGFloat, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: iconSize, weight: .regular))
        .foregroundStyle(.white)
        .frame(width: diameter, height: diameter)
        .background(.ultraThinMaterial, in: Circle())
        .environment(\.colorScheme, .dark)
    }
    .buttonStyle(.plain)
  }

  private var isLoading: Bool {
    viewModel.isBuffering || viewModel.isSeeking
  }

  private var bottomInfoRow: some View {
    HStack {
      Text("\(timeString(viewModel.currentTime)) / \(timeString(viewModel.duration))")
        .font(.footnote.monospacedDigit())
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .environment(\.colorScheme, .dark)

      Spacer()

      Button(action: { viewModel.cycleRate(); scheduleAutoHide() }) {
        Text(rateLabel(viewModel.rate))
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 5)
          .background(.ultraThinMaterial, in: Capsule())
          .environment(\.colorScheme, .dark)
      }
      .buttonStyle(.plain)
    }
  }

  private var scrubber: some View {
    GeometryReader { geo in
      let width = geo.size.width
      let duration = max(viewModel.duration, 0.001)
      let progress = min(max(viewModel.currentTime / duration, 0), 1)
      let playheadX = width * progress
      let thumb: CGFloat = viewModel.isScrubbing ? 15 : 12

      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.white.opacity(0.28))
          .frame(height: 3)

        Capsule()
          .fill(Color.white)
          .frame(width: playheadX, height: 3)

        Circle()
          .fill(Color.blue)
          .frame(width: thumb, height: thumb)
          .offset(x: playheadX - thumb / 2)
          .animation(.easeOut(duration: 0.12), value: viewModel.isScrubbing)
      }
      .frame(width: width, height: thumb)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      .contentShape(Rectangle())
      .highPriorityGesture(
        DragGesture(minimumDistance: 4)
          .onChanged { value in
            hideTask?.cancel()
            viewModel.isScrubbing = true
            let ratio = min(max(value.location.x / width, 0), 1)
            viewModel.currentTime = ratio * duration
          }
          .onEnded { value in
            let ratio = min(max(value.location.x / width, 0), 1)
            viewModel.seek(to: ratio * duration)
            viewModel.isScrubbing = false
            scheduleAutoHide()
          }
      )
    }
    .frame(height: 34)
  }

  private func skipZone(seconds: Double, systemImage: String, flashing: Binding<Bool>) -> some View {
    Color.clear
      .contentShape(Rectangle())
      .overlay {
        Image(systemName: systemImage)
          .font(.system(size: 38))
          .foregroundStyle(.white)
          .padding(22)
          .background(Circle().fill(Color.black.opacity(0.35)))
          .opacity(flashing.wrappedValue ? 1 : 0)
      }
      .onTapGesture(count: 2) {
        viewModel.skip(by: seconds)
        flash(flashing)
      }
      .onTapGesture {
        toggleControls()
      }
  }

  private func flash(_ binding: Binding<Bool>) {
    withAnimation(.easeIn(duration: 0.1)) { binding.wrappedValue = true }
    Task {
      try? await Task.sleep(nanoseconds: 450_000_000)
      withAnimation(.easeOut(duration: 0.2)) { binding.wrappedValue = false }
    }
  }

  private func toggleControls() {
    controlsVisible.toggle()
    if controlsVisible { scheduleAutoHide() }
  }

  private func scheduleAutoHide() {
    hideTask?.cancel()
    guard viewModel.isPlaying else { return }
    hideTask = Task {
      try? await Task.sleep(nanoseconds: 3_500_000_000)
      guard !Task.isCancelled else { return }
      controlsVisible = false
    }
  }

  private func rateLabel(_ rate: Float) -> String {
    if rate == rate.rounded() {
      return "\(Int(rate))x"
    }
    return "\(rate)x"
  }

  private func timeString(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "00:00" }
    let total = Int(seconds)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let secs = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }
    return String(format: "%02d:%02d", minutes, secs)
  }
}
