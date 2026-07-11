//
//  RubyEventsWidgetsLiveActivity.swift
//  RubyEventsWidgets
//

import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

private typealias Talk = ScheduleActivityAttributes.SessionTalk

private func sharedImage(_ filename: String?) -> Image? {
  guard let filename,
        let url = LiveActivityShared.imageURL(for: filename),
        let uiImage = UIImage(contentsOfFile: url.path) else { return nil }

  return Image(uiImage: uiImage)
}

private func hexColor(_ hex: String?) -> Color {
  guard let hex else { return .gray }

  let string = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex

  guard string.count == 6, let value = UInt64(string, radix: 16) else { return .gray }

  return Color(
    red: Double((value >> 16) & 0xFF) / 255,
    green: Double((value >> 8) & 0xFF) / 255,
    blue: Double(value & 0xFF) / 255
  )
}

private func darkerColor(_ hex: String, by factor: Double = 0.2) -> Color {
  let string = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
  guard string.count == 6, let value = UInt64(string, radix: 16) else { return .black }
  let scale = 1 - factor

  return Color(
    red: Double((value >> 16) & 0xFF) / 255 * scale,
    green: Double((value >> 8) & 0xFF) / 255 * scale,
    blue: Double(value & 0xFF) / 255 * scale
  )
}

private func timeRange(_ start: Date, _ end: Date) -> String {
  "\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))"
}

@ViewBuilder
private func trackBadge(_ track: String?, _ colorHex: String?) -> some View {
  if let track, !track.isEmpty {
    Text(track)
      .font(.caption2.weight(.bold))
      .padding(.horizontal, 6)
      .padding(.vertical, 1)
      .background(hexColor(colorHex))
      .foregroundStyle(.white)
      .clipShape(Capsule())
  }
}

@ViewBuilder
private func avatarCircle(_ filename: String?, size: CGFloat, border: Color) -> some View {
  if let avatar = sharedImage(filename) {
    avatar.resizable().scaledToFill()
      .frame(width: size, height: size)
      .clipShape(Circle())
      .overlay(Circle().strokeBorder(border, lineWidth: 0.5))
  }
}

struct RubyEventsWidgetsLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ScheduleActivityAttributes.self) { context in
      LiveActivityLockScreen(context: context)
        .activityBackgroundTint(hexColor(context.attributes.featuredBackground))
        .activitySystemActionForegroundColor(hexColor(context.attributes.featuredColor))
    } dynamicIsland: { context in
      let accent = hexColor(context.attributes.featuredColor)
      let talks = context.state.talks

      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          if let avatar = sharedImage(context.attributes.eventAvatarFile) {
            avatar.resizable().scaledToFill()
              .frame(width: 38, height: 38)
              .clipShape(RoundedRectangle(cornerRadius: 8))
          } else {
            Label("LIVE", systemImage: "record.circle.fill")
              .font(.caption2.weight(.semibold)).foregroundStyle(.red)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          if context.state.isLive {
            Text(timerInterval: context.state.sessionStart...context.state.sessionEnd, countsDown: true)
              .font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 56)
          }
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(talks.first?.title ?? "Session")
              .font(.subheadline.weight(.semibold)).lineLimit(2)
            Text(timeRange(context.state.sessionStart, context.state.sessionEnd))
              .font(.caption2).foregroundStyle(.secondary)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<min(talks.count, 2), id: \.self) { i in
              HStack(spacing: 6) {
                trackBadge(talks[i].track, talks[i].trackColor)
                avatarCircle(talks[i].avatarFile, size: 16, border: .clear)
                Text(talks.count > 1 ? talks[i].title : talks[i].speakers)
                  .font(.caption).foregroundStyle(.secondary).lineLimit(1)
              }
            }
            if talks.count > 2 {
              Text("+\(talks.count - 2) more").font(.caption2).foregroundStyle(.secondary)
            }
            if let next = context.state.nextTitle {
              Text("Up next: \(next)").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
          }
        }
      } compactLeading: {
        Image(systemName: "record.circle.fill").foregroundStyle(.red)
      } compactTrailing: {
        if context.state.isLive {
          Text(timerInterval: context.state.sessionStart...context.state.sessionEnd, countsDown: true)
            .font(.caption2.monospacedDigit()).frame(width: 40)
        }
      } minimal: {
        Image(systemName: "record.circle.fill").foregroundStyle(.red)
      }
      .keylineTint(accent)
    }
  }
}

struct LiveActivityLockScreen: View {
  let context: ActivityViewContext<ScheduleActivityAttributes>

  private var background: Color { hexColor(context.attributes.featuredBackground) }
  private var foreground: Color { hexColor(context.attributes.featuredColor) }

  private var visibleTalks: [Talk] { Array(context.state.talks.prefix(2)) }
  private var extraTalks: Int { max(0, context.state.talks.count - 2) }

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: context.state.talks.count > 1 ? .center : .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 6) {
          eventAvatar

          VStack(alignment: .leading, spacing: 1) {
            Text("\(context.state.sessionStart.formatted(date: .omitted, time: .shortened)) –")
              .font(.caption2)
              .foregroundStyle(foreground.opacity(0.8))
              .lineLimit(1)
            Text(context.state.sessionEnd.formatted(date: .omitted, time: .shortened))
              .font(.caption2)
              .foregroundStyle(foreground.opacity(0.55))
              .lineLimit(1)

            if context.state.isLive {
              Text(timerInterval: context.state.sessionStart...context.state.sessionEnd, countsDown: true)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .padding(.top, 8)
            }
          }
        }
        .frame(width: 62, alignment: .leading)

        VStack(alignment: .leading, spacing: 10) {
          ForEach(visibleTalks.indices, id: \.self) { i in
            if i > 0 {
              Rectangle()
                .fill(foreground.opacity(0.18))
                .frame(height: 0.5)
            }
            talkBlock(visibleTalks[i])
          }
          if extraTalks > 0 {
            Text("+\(extraTalks) more")
              .font(.caption2.weight(.medium))
              .foregroundStyle(foreground.opacity(0.6))
          }
        }

        Spacer(minLength: 0)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(background)

      if let next = context.state.nextTitle {
        Group {
          if context.state.talks.count <= 1 {
            upNextFull(next)
          } else {
            upNextCompact(next)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, context.state.talks.count <= 1 ? 12 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(darkerColor(context.attributes.featuredBackground))
      }
    }
    .widgetURL(URL(string: context.attributes.scheduleURL))
  }

  private func talkBlock(_ talk: Talk) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(talk.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(foreground)
        .lineLimit(context.state.talks.count > 1 ? 1 : 2)

      if !talk.speakers.isEmpty || !(talk.track ?? "").isEmpty {
        HStack(spacing: 6) {
          if !talk.speakers.isEmpty {
            avatarCircle(talk.avatarFile, size: 18, border: foreground.opacity(0.25))

            Text(talk.speakers).font(.caption).foregroundStyle(foreground.opacity(0.85)).lineLimit(1)
          }

          Spacer(minLength: 4)
          trackBadge(talk.track, talk.trackColor)
        }
      }
    }
  }

  private func upNextCompact(_ next: String) -> some View {
    HStack(alignment: .center, spacing: 8) {
      Text("UP NEXT")
        .font(.caption2.weight(.bold))
        .foregroundStyle(foreground.opacity(0.55))

      avatarCircle(context.state.nextSpeakerAvatarFile, size: 16, border: foreground.opacity(0.25))

      Text(next).font(.caption2).foregroundStyle(foreground.opacity(0.85)).lineLimit(1)

      Spacer(minLength: 4)

      trackBadge(context.state.nextTrack, context.state.nextTrackColor)

      if let start = context.state.nextStart {
        Text(start.formatted(date: .omitted, time: .shortened))
          .font(.caption2.monospacedDigit()).foregroundStyle(foreground.opacity(0.85))
      }
    }
    .frame(height: 20)
  }

  private func upNextFull(_ next: String) -> some View {
    HStack(alignment: .center, spacing: 12) {
      if sharedImage(context.state.nextSpeakerAvatarFile) != nil {
        avatarCircle(context.state.nextSpeakerAvatarFile, size: 40, border: foreground.opacity(0.25))
      }

      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text("UP NEXT")
            .font(.caption2.weight(.bold))
            .foregroundStyle(foreground.opacity(0.55))
          trackBadge(context.state.nextTrack, context.state.nextTrackColor)

          Spacer(minLength: 4)

          if let start = context.state.nextStart {
            Text(start.formatted(date: .omitted, time: .shortened))
              .font(.caption.monospacedDigit()).foregroundStyle(foreground.opacity(0.85))
          }
        }

        Text(next)
          .font(.subheadline.weight(.semibold)).foregroundStyle(foreground).lineLimit(1)

        if let speakers = context.state.nextSpeakers, !speakers.isEmpty {
          Text(speakers)
            .font(.caption).foregroundStyle(foreground.opacity(0.8)).lineLimit(1)
        }
      }
    }
  }

  @ViewBuilder
  private var eventAvatar: some View {
    if let avatar = sharedImage(context.attributes.eventAvatarFile) {
      avatar.resizable().scaledToFill()
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(foreground.opacity(0.25), lineWidth: 1))
    } else {
      Image(systemName: "record.circle.fill")
        .font(.title2).foregroundStyle(.red).frame(width: 46, height: 46)
    }
  }
}

extension ScheduleActivityAttributes {
  fileprivate static var preview: ScheduleActivityAttributes {
    ScheduleActivityAttributes(
      eventName: "Rails World 2025",
      eventSlug: "rails-world-2025",
      featuredBackground: "#3B1D62",
      featuredColor: "#FFFFFF",
      eventAvatarFile: nil,
      scheduleURL: "rubyevents://events/rails-world-2025/schedule/day/2025-09-04"
    )
  }
}

extension ScheduleActivityAttributes.ContentState {
  fileprivate static var sample: ScheduleActivityAttributes.ContentState {
    .init(
      talks: [
        .init(title: "Multi-Tenant Rails", speakers: "Mike Dalessio", track: "Track 1", trackColor: "#DC2626", avatarFile: nil),
        .init(title: "Startup Speed, Enterprise Scale", speakers: "Austin Story", track: "Track 2", trackColor: "#2563EB", avatarFile: nil)
      ],
      sessionStart: .now,
      sessionEnd: .now.addingTimeInterval(45 * 60),
      isLive: true,
      nextTitle: "SQLite Replication with Beamer",
      nextSpeakers: "Kevin McConnell",
      nextTrack: "Track 1",
      nextTrackColor: "#DC2626",
      nextSpeakerAvatarFile: nil,
      nextStart: .now.addingTimeInterval(45 * 60)
    )
  }
}

#Preview("Live Activity", as: .content, using: ScheduleActivityAttributes.preview) {
  RubyEventsWidgetsLiveActivity()
} contentStates: {
  ScheduleActivityAttributes.ContentState.sample
}
