//
//  NextEventWidget.swift
//  RubyEventsWidgets
//

import AppIntents
import SwiftUI
import UIKit
import WidgetKit

enum NextEventDisplayMode: String, AppEnum {
  case countdown
  case list

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Display")
  }

  static var caseDisplayRepresentations: [NextEventDisplayMode: DisplayRepresentation] {
    [
      .countdown: DisplayRepresentation(title: "Countdown"),
      .list: DisplayRepresentation(title: "Upcoming list")
    ]
  }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Next Ruby Event" }

  static var description: IntentDescription {
    IntentDescription("Countdown to the next event, or a list of upcoming events (medium size).")
  }

  @Parameter(title: "Display", default: NextEventDisplayMode.countdown)
  var mode: NextEventDisplayMode
}

struct NextEvent: Decodable {
  let name: String
  let slug: String
  let location: String?
  let start_at: String?
  let end_at: String?
  let featured_background: String?
  let featured_color: String?
  let banner_background: String?
  let featured_url: String?
  let keynote_avatars: [String]?
  let speakers_count: Int?
  let participants_count: Int?

  var startDate: Date? { start_at.flatMap { ISO8601DateFormatter().date(from: $0) } }
  var endDate: Date? { end_at.flatMap { ISO8601DateFormatter().date(from: $0) } }
}

struct UpcomingRow {
  let name: String
  let slug: String
  let startDate: Date?
  let featuredBackground: String
  let featuredColor: String
  let avatar: UIImage?
}

struct NextEventEntry: TimelineEntry {
  let date: Date
  let event: NextEvent?
  let image: UIImage?
  let avatars: [UIImage]
  let upcoming: [UpcomingRow]
  let mode: NextEventDisplayMode
}

struct NextEventProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> NextEventEntry {
    NextEventEntry(date: Date(), event: .preview, image: nil, avatars: [], upcoming: [], mode: .countdown)
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> NextEventEntry {
    currentEntry(mode: configuration.mode)
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<NextEventEntry> {
    let reload = Calendar.current.nextDate(
      after: Date(), matching: DateComponents(hour: 0, minute: 5), matchingPolicy: .nextTime
    ) ?? Date().addingTimeInterval(6 * 3600)

    return Timeline(entries: [currentEntry(mode: configuration.mode)], policy: .after(reload))
  }

  private func currentEntry(mode: NextEventDisplayMode) -> NextEventEntry {
    guard let snapshot = NextEventStore.load() else {
      return NextEventEntry(date: Date(), event: nil, image: nil, avatars: [], upcoming: [], mode: mode)
    }

    let upcoming = snapshot.upcoming.map { item in
      UpcomingRow(
        name: item.name,
        slug: item.slug,
        startDate: item.startAt,
        featuredBackground: item.featuredBackground,
        featuredColor: item.featuredColor,
        avatar: NextEventStore.image(item.avatarFile)
      )
    }

    return NextEventEntry(
      date: Date(),
      event: NextEvent(snapshot),
      image: NextEventStore.image(snapshot.featuredImageFile),
      avatars: snapshot.avatarFiles.compactMap { NextEventStore.image($0) },
      upcoming: upcoming,
      mode: mode
    )
  }
}

private func hexColor(_ hex: String?) -> Color {
  guard let hex else { return .black }
  let string = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex

  guard string.count == 6, let value = UInt64(string, radix: 16) else { return .black }

  return Color(
    red: Double((value >> 16) & 0xFF) / 255,
    green: Double((value >> 8) & 0xFF) / 255,
    blue: Double(value & 0xFF) / 255
  )
}

struct NextEventWidgetView: View {
  let entry: NextEventEntry
  @SwiftUI.Environment(\.widgetFamily) private var family

  var body: some View {
    if entry.mode == .list, !entry.upcoming.isEmpty {
      listLayout()
    } else if let event = entry.event, let start = event.startDate {
      eventView(event, start)
    } else {
      emptyView
    }
  }

  private func listLayout() -> some View {
    let isSmall = family == .systemSmall
    let rows = Array(entry.upcoming.prefix(isSmall ? 5 : 3))

    return VStack(alignment: .leading, spacing: isSmall ? 3 : 6) {
      if !isSmall {
        Text("UPCOMING RUBY EVENTS")
          .font(.caption2.weight(.bold))
          .foregroundStyle(.secondary)
          .padding(.bottom, 4)
      }

      ForEach(rows.indices, id: \.self) { i in
        if i > 0 { Divider() }
        upcomingRow(rows[i], compact: isSmall)
      }

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .modifier(WidgetContainerBackground(color: Color(.systemBackground), contentPadding: isSmall ? 11 : 14))
  }

  private func upcomingRow(_ row: UpcomingRow, compact: Bool) -> some View {
    let accent = hexColor(row.featuredBackground)
    let size: CGFloat = compact ? 23 : 30

    let days = row.startDate.map {
      max(0, Calendar.current.dateComponents(
        [.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: $0)
      ).day ?? 0)
    }

    return Link(destination: URL(string: "rubyevents://events/\(row.slug)")!) {
      HStack(spacing: compact ? 8 : 10) {
        Group {
          if let avatar = row.avatar {
            Image(uiImage: avatar).resizable().scaledToFill()
          } else {
            accent.overlay(Image(systemName: "calendar").font(.caption2).foregroundStyle(.white))
          }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 6 : 7))

        Text(row.name)
          .font((compact ? Font.caption : Font.subheadline).weight(.medium))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Spacer(minLength: 4)

        if let days {
          if compact {
            Text("\(days)d")
              .font(.system(size: 15, weight: .bold, design: .rounded))
              .foregroundStyle(.primary)
          } else {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
              Text("\(days)").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.primary)
              Text(days == 1 ? "day" : "days").font(.caption2).foregroundStyle(.secondary)
            }
          }
        }
      }
    }
  }

  private func eventView(_ event: NextEvent, _ start: Date) -> some View {
    let foreground = hexColor(event.featured_color)

    return Group {
      if family == .systemSmall {
        smallLayout(event, start, foreground)
      } else {
        mediumLayout(event, start, foreground)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .widgetURL(URL(string: "rubyevents://events/\(event.slug)"))
    .modifier(WidgetContainerBackground(
      color: hexColor(event.featured_background),
      image: family == .systemSmall ? nil : entry.image,
      imageWidth: 152,
      imageHeight: 88,
      contentPadding: family == .systemSmall ? 12 : 16
    ))
  }

  private func smallLayout(_ event: NextEvent, _ start: Date, _ fg: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Spacer(minLength: 0)
      Text(event.name)
        .font(.headline)
        .foregroundStyle(fg)
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      if let location = shortLocation(event.location) {
        Text(location)
          .font(.caption)
          .foregroundStyle(fg.opacity(0.7))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }

      Spacer().frame(height: 10)
      countdown(to: start, foreground: fg, compact: true)
      dateLabel(start, event.endDate, fg)
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func shortLocation(_ location: String?) -> String? {
    guard let location, !location.isEmpty else { return nil }

    return location.split(separator: ",").prefix(2)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .joined(separator: ", ")
  }

  private func mediumLayout(_ event: NextEvent, _ start: Date, _ fg: Color) -> some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text("NEXT RUBY EVENT").font(.caption2.weight(.bold)).foregroundStyle(fg.opacity(0.7))
        Text(event.name).font(.headline).foregroundStyle(fg).lineLimit(2)
        locationLabel(event, fg)
        Spacer(minLength: 6)
        countdown(to: start, foreground: fg, compact: false)
        dateLabel(start, event.endDate, fg)
      }

      if !entry.avatars.isEmpty || (event.participants_count ?? 0) > 0 {
        Spacer(minLength: 0)
        attendeePanel(event, fg)
      }
    }
  }

  @ViewBuilder
  private func locationLabel(_ event: NextEvent, _ fg: Color) -> some View {
    if let location = event.location, !location.isEmpty {
      Text(location).font(.caption).foregroundStyle(fg.opacity(0.7)).lineLimit(1)
    }
  }

  private func dateLabel(_ start: Date, _ end: Date?, _ fg: Color) -> some View {
    Text(dateRangeText(start, end))
      .font(.caption2)
      .foregroundStyle(fg.opacity(0.7))
      .lineLimit(1)
      .minimumScaleFactor(0.8)
  }

  private func dateRangeText(_ start: Date, _ end: Date?) -> String {
    if let end, !Calendar.current.isDate(start, inSameDayAs: end) {
      let formatter = DateIntervalFormatter()
      formatter.dateStyle = .long
      formatter.timeStyle = .none

      return formatter.string(from: start, to: end)
    }

    return start.formatted(.dateTime.month(.wide).day().year())
  }

  private func countdown(to start: Date, foreground fg: Color, compact: Bool) -> some View {
    let days = max(0, Calendar.current.dateComponents(
      [.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: start)
    ).day ?? 0)

    return Group {
      if days == 0 {
        Text("Today").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(fg)
      } else if compact {
        VStack(alignment: .leading, spacing: -4) {
          Text("\(days)").font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(fg)
          Text(days == 1 ? "DAY TO GO" : "DAYS TO GO")
            .font(.caption2.weight(.semibold)).foregroundStyle(fg.opacity(0.75))
        }
      } else {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text("\(days)").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(fg)
          Text(days == 1 ? "day to go" : "days to go")
            .font(.subheadline.weight(.medium)).foregroundStyle(fg.opacity(0.75))
        }
      }
    }
  }

  private func attendeePanel(_ event: NextEvent, _ fg: Color) -> some View {
    let extra = max(0, (event.participants_count ?? 0) - entry.avatars.count)

    return VStack(alignment: .trailing, spacing: 6) {
      Spacer(minLength: 0)
      avatarStack(extra: extra, fg: fg, bg: hexColor(event.featured_background))
      Text("known participants")
        .font(.caption2).foregroundStyle(fg.opacity(0.7)).lineLimit(1)
    }
  }

  private func avatarStack(extra: Int, fg: Color, bg: Color) -> some View {
    let diameter: CGFloat = 34

    return HStack(spacing: -11) {
      ForEach(entry.avatars.indices, id: \.self) { i in
        Image(uiImage: entry.avatars[i]).resizable().scaledToFill()
          .frame(width: diameter, height: diameter)
          .clipShape(Circle())
          .overlay(Circle().strokeBorder(fg.opacity(0.9), lineWidth: 1.5))
      }

      if extra > 0 {
        Text("+\(extra)")
          .font(.caption2.weight(.bold))
          .foregroundStyle(bg)
          .frame(width: diameter, height: diameter)
          .background(Circle().fill(fg))
          .overlay(Circle().strokeBorder(bg, lineWidth: 1.5))
      }
    }
  }

  private var emptyView: some View {
    VStack(spacing: 4) {
      Image(systemName: "calendar")
        .font(.title)
        .foregroundStyle(.secondary)

      Text("No upcoming events")
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Text("grp: \(LiveActivityShared.containerURL?.lastPathComponent.prefix(8) ?? "nil")")
        .font(.system(size: 9)).foregroundStyle(.secondary)

      Text("store: \(NextEventStore.load() != nil ? "found" : "missing")")
        .font(.system(size: 9)).foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .modifier(WidgetContainerBackground(color: Color(.systemBackground)))
  }
}

private struct WidgetContainerBackground: ViewModifier {
  let color: Color
  var image: UIImage?
  var imageWidth: CGFloat = 120
  var imageHeight: CGFloat = 72
  var contentPadding: CGFloat = 16

  @ViewBuilder private var backgroundView: some View {
    color.overlay(alignment: .topTrailing) {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: imageWidth, maxHeight: imageHeight)
          .padding(.top, 12)
          .padding(.trailing, 10)
      }
    }
  }

  func body(content: Content) -> some View {
    if #available(iOS 17.0, *) {
      content.padding(contentPadding).containerBackground(for: .widget) { backgroundView }
    } else {
      content.padding(contentPadding).background(backgroundView)
    }
  }
}

struct NextEventWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: "NextEventWidget", intent: ConfigurationAppIntent.self, provider: NextEventProvider()) { entry in
      NextEventWidgetView(entry: entry)
    }
    .configurationDisplayName("Next Ruby Event")
    .description("Countdown to the next Ruby event, or a list of upcoming ones (medium).")
    .supportedFamilies([.systemSmall, .systemMedium])
    .contentMarginsDisabled()
  }
}

extension NextEvent {
  init(_ snapshot: NextEventSnapshot) {
    self.init(
      name: snapshot.name,
      slug: snapshot.slug,
      location: snapshot.location,
      start_at: snapshot.startAt.map { ISO8601DateFormatter().string(from: $0) },
      end_at: snapshot.endAt.map { ISO8601DateFormatter().string(from: $0) },
      featured_background: snapshot.featuredBackground,
      featured_color: snapshot.featuredColor,
      banner_background: snapshot.bannerBackground,
      featured_url: nil,
      keynote_avatars: nil,
      speakers_count: snapshot.speakersCount,
      participants_count: snapshot.participantsCount
    )
  }

  static var preview: NextEvent {
    NextEvent(
      name: "RubyConf 2026",
      slug: "rubyconf-2026",
      location: "Las Vegas, NV",
      start_at: "2026-07-14T09:00:00-07:00",
      end_at: "2026-07-16T09:00:00-07:00",
      featured_background: "#303A32",
      featured_color: "#E3ECDB",
      banner_background: "#303A32",
      featured_url: nil,
      keynote_avatars: [],
      speakers_count: 62,
      participants_count: 68
    )
  }
}
