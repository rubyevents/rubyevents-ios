//
//  LiveActivityManager.swift
//  RubyEvents
//

import ActivityKit
import Foundation
import UIKit

struct LiveScheduleResponse: Decodable {
  struct EventInfo: Decodable {
    let name: String
    let slug: String
    let avatar_url: String?
    let featured_background: String?
    let featured_color: String?
  }

  let event: EventInfo
  let time_zone: String?
  let sessions: [LiveSession]
}

struct LiveTalk: Decodable {
  let title: String?
  let speakers: [String]?
  let speaker_avatars: [String]?
  let track: String?
  let track_color: String?
}

struct LiveSession: Decodable {
  let talks: [LiveTalk]?
  let start_at: String?
  let end_at: String?
  let date: String?

  var startDate: Date? { start_at.flatMap { ISO8601DateFormatter().date(from: $0) } }
  var endDate: Date? { end_at.flatMap { ISO8601DateFormatter().date(from: $0) } }
}

@MainActor
final class LiveActivityManager {
  static let shared = LiveActivityManager()
  static let didEndNotification = Notification.Name("LiveActivityManager.didEnd")

  private var activity: Activity<ScheduleActivityAttributes>?
  private var sessions: [LiveSession] = []
  private var eventSlug: String?
  private var advanceTimer: Timer?

  private init() {
    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { [weak self] _ in
      Task { await self?.refreshIfRunning() }
    }
  }

  private var systemActivities: [Activity<ScheduleActivityAttributes>] {
    Activity<ScheduleActivityAttributes>.activities
  }

  var isRunning: Bool { !systemActivities.isEmpty }
  var activeEventSlug: String? { systemActivities.first?.attributes.eventSlug }

  func isActive(eventSlug: String) -> Bool {
    systemActivities.contains { $0.attributes.eventSlug == eventSlug }
  }

  func start(eventSlug: String, eventName: String) async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    guard let response = await fetchSchedule(eventSlug: eventSlug) else { return }

    sessions = sortedSessions(response.sessions)

    self.eventSlug = eventSlug

    if let existing = systemActivities.first(where: { $0.attributes.eventSlug == eventSlug }) {
      activity = existing
      observeActivityState()

      await advance()

      return
    }

    await endActivities(exceptSlug: eventSlug)

    guard let state = await buildState() else { return }

    let attributes = ScheduleActivityAttributes(
      eventName: response.event.name,
      eventSlug: eventSlug,
      featuredBackground: response.event.featured_background ?? "#000000",
      featuredColor: response.event.featured_color ?? "#FFFFFF",
      eventAvatarFile: await cacheImage(from: response.event.avatar_url, as: "event-avatar"),
      scheduleURL: scheduleDeepLink(eventSlug: eventSlug)
    )

    do {
      activity = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: nextBoundary().addingTimeInterval(60)),
        pushType: nil
      )

      scheduleAdvance()
      observeActivityState()
    } catch {
      print("Live Activity start failed:", error)
    }
  }

  func stop() async {
    advanceTimer?.invalidate()
    advanceTimer = nil

    for activity in systemActivities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }

    activity = nil
    eventSlug = nil
    sessions = []

    NotificationCenter.default.post(name: Self.didEndNotification, object: nil)
  }

  private func endActivities(exceptSlug: String?) async {
    for activity in systemActivities where activity.attributes.eventSlug != exceptSlug {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }

  private func observeActivityState() {
    guard let activity else { return }

    Task { [weak self] in
      for await state in activity.activityStateUpdates {
        if state == .ended || state == .dismissed {
          self?.clearActiveState()
          NotificationCenter.default.post(name: Self.didEndNotification, object: nil)

          return
        }
      }
    }
  }

  private func clearActiveState() {
    advanceTimer?.invalidate()
    advanceTimer = nil
    activity = nil
    eventSlug = nil
    sessions = []
  }

  private func refreshIfRunning() async {
    guard let eventSlug = activeEventSlug else { return }

    if activity == nil {
      activity = systemActivities.first { $0.attributes.eventSlug == eventSlug }
      self.eventSlug = eventSlug
      observeActivityState()
    }

    if let response = await fetchSchedule(eventSlug: eventSlug) {
      sessions = sortedSessions(response.sessions)
    }

    await advance()
  }

  private func currentSession(_ now: Date = Date()) -> LiveSession? {
    sessions.first { session in
      guard let start = session.startDate, let end = session.endDate else { return false }
      return start <= now && now < end
    }
  }

  private func nextSession(_ now: Date = Date()) -> LiveSession? {
    sessions
      .filter { ($0.startDate ?? .distantPast) > now }
      .min { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
  }

  private func isTalkSession(_ session: LiveSession) -> Bool {
    (session.talks ?? []).contains { !($0.speakers ?? []).isEmpty }
  }

  private func nextTalkSession(_ now: Date = Date()) -> LiveSession? {
    sessions
      .filter { ($0.startDate ?? .distantPast) > now && isTalkSession($0) }
      .min { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
  }

  private func buildState(_ now: Date = Date()) async -> ScheduleActivityAttributes.ContentState? {
    let next = nextTalkSession(now)
    let nextTalk = next?.talks?.first { !($0.speakers ?? []).isEmpty } ?? next?.talks?.first

    if let current = currentSession(now), let start = current.startDate, let end = current.endDate {
      return .init(
        talks: await sessionTalks(current),
        sessionStart: start,
        sessionEnd: end,
        isLive: true,
        nextTitle: nextTalk?.title,
        nextSpeakers: nextTalk?.speakers?.joined(separator: ", "),
        nextTrack: nextTalk?.track,
        nextTrackColor: nextTalk?.track_color,
        nextSpeakerAvatarFile: await cacheImage(from: nextTalk?.speaker_avatars?.first, as: "next-speaker"),
        nextStart: next?.startDate
      )
    }

    if let next, let start = next.startDate, let end = next.endDate {
      return .init(
        talks: await sessionTalks(next),
        sessionStart: start,
        sessionEnd: end,
        isLive: false,
        nextTitle: nil,
        nextSpeakers: nil,
        nextTrack: nil,
        nextTrackColor: nil,
        nextSpeakerAvatarFile: nil,
        nextStart: nil
      )
    }

    return nil
  }

  private func sessionTalks(_ session: LiveSession) async -> [ScheduleActivityAttributes.SessionTalk] {
    var result: [ScheduleActivityAttributes.SessionTalk] = []

    for (index, talk) in (session.talks ?? []).enumerated() {
      result.append(.init(
        title: talk.title ?? "Session",
        speakers: talk.speakers?.joined(separator: ", ") ?? "",
        track: talk.track,
        trackColor: talk.track_color,
        avatarFile: await cacheImage(from: talk.speaker_avatars?.first, as: "talk-\(index)")
      ))
    }

    return result
  }

  private func scheduleDeepLink(eventSlug: String) -> String {
    let day = (currentSession() ?? nextSession() ?? sessions.first)?.date

    if let day {
      return "rubyevents://events/\(eventSlug)/schedule/day/\(day)"
    }

    return "rubyevents://events/\(eventSlug)/schedule"
  }

  private func nextBoundary(_ now: Date = Date()) -> Date {
    if let current = currentSession(now), let end = current.endDate { return end }
    if let next = nextSession(now), let start = next.startDate { return start }

    return now.addingTimeInterval(3600)
  }

  private func scheduleAdvance() {
    advanceTimer?.invalidate()

    let interval = max(nextBoundary().timeIntervalSinceNow + 1, 1)

    advanceTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
      Task { await self?.advance() }
    }
  }

  private func advance() async {
    guard let activity else { return }

    guard let state = await buildState() else {
      await stop()
      return
    }

    await activity.update(.init(state: state, staleDate: nextBoundary().addingTimeInterval(60)))

    scheduleAdvance()
  }

  private func sortedSessions(_ sessions: [LiveSession]) -> [LiveSession] {
    sessions.sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
  }

  private func fetchSchedule(eventSlug: String) async -> LiveScheduleResponse? {
    let endpoint = Router.instance.root_url()
      .appendingPathComponent("/hotwire/native/v1/events/\(eventSlug)/live_schedule.json")
      .absoluteString

    return try? await APIService.shared.fetchData(from: endpoint)
  }

  private func cacheImage(from urlString: String?, as name: String) async -> String? {
    guard let urlString, !urlString.isEmpty,
          let destination = LiveActivityShared.imageURL(for: "\(name).png") else { return nil }

    let absolute = urlString.hasPrefix("http")
      ? urlString
      : Router.instance.root_url().appendingPathComponent(urlString).absoluteString

    guard let url = URL(string: absolute) else { return nil }

    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      guard let png = Self.downscaledPNG(data, maxDimension: 120) else { return nil }

      try png.write(to: destination, options: .atomic)

      return "\(name).png"
    } catch {
      return nil
    }
  }

  private static func downscaledPNG(_ data: Data, maxDimension: CGFloat) -> Data? {
    guard let image = UIImage(data: data) else { return nil }

    let longest = max(image.size.width, image.size.height, 1)
    let scale = min(1, maxDimension / longest)
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }.pngData()
  }
}
