//
//  NextEventUpdater.swift
//  RubyEvents
//

import BackgroundTasks
import Foundation
import UIKit
import WidgetKit

enum NextEventUpdater {
  static let backgroundTaskID = "org.rubyevents.RubyEvents.nextevent.refresh"

  static func refresh() {
    Task { await performRefresh() }
  }

  static func registerBackgroundTask() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskID, using: nil) { task in
      guard let refreshTask = task as? BGAppRefreshTask else { return }
      handle(refreshTask)
    }
  }

  static func scheduleBackgroundRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: backgroundTaskID)
    request.earliestBeginDate = Date().addingTimeInterval(4 * 3600) // no sooner than ~4h
    try? BGTaskScheduler.shared.submit(request)
  }

  private static func handle(_ task: BGAppRefreshTask) {
    scheduleBackgroundRefresh()

    let work = Task {
      await performRefresh()

      task.setTaskCompleted(success: true)
    }

    task.expirationHandler = { work.cancel() }
  }

  private static func performRefresh() async {
    struct Response: Decodable {
      let event: Payload?
      let upcoming: [UpcomingPayload]?
    }

    struct Payload: Decodable {
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
    }

    struct UpcomingPayload: Decodable {
      let name: String
      let slug: String
      let start_at: String?
      let featured_background: String?
      let featured_color: String?
      let avatar_url: String?
    }

    let endpoint = Router.instance.root_url()
      .appendingPathComponent("/hotwire/native/v1/next_event.json")

    print("📅 NextEvent: container=\(LiveActivityShared.containerURL?.path ?? "nil") fetching=\(endpoint.absoluteString)")

    var fetchRequest = URLRequest(url: endpoint)
    fetchRequest.timeoutInterval = 8

    guard let (data, _) = try? await URLSession.shared.data(for: fetchRequest) else {
      print("📅 NextEvent: FETCH FAILED (host unreachable?)")
      return
    }

    guard let response = try? JSONDecoder().decode(Response.self, from: data), let event = response.event else {
      print("📅 NextEvent: DECODE/NO EVENT. body=\(String(data: data, encoding: .utf8)?.prefix(200) ?? "")")
      return
    }

    print("📅 NextEvent: got '\(event.name)' — saving snapshot")

    async let featuredFile = saveImage(event.featured_url, as: "next-featured", maxDimension: 600)
    async let avatarFiles = saveAvatars(event.keynote_avatars)

    var upcomingItems: [UpcomingItem] = []

    for (index, item) in (response.upcoming ?? []).prefix(6).enumerated() {
      let avatarFile = await saveImage(item.avatar_url, as: "upcoming-avatar-\(index)", maxDimension: 120)

      upcomingItems.append(UpcomingItem(
        name: item.name,
        slug: item.slug,
        startAt: item.start_at.flatMap { ISO8601DateFormatter().date(from: $0) },
        featuredBackground: item.featured_background ?? "#000000",
        featuredColor: item.featured_color ?? "#FFFFFF",
        avatarFile: avatarFile
      ))
    }

    let snapshot = NextEventSnapshot(
      name: event.name,
      slug: event.slug,
      location: event.location,
      startAt: event.start_at.flatMap { ISO8601DateFormatter().date(from: $0) },
      endAt: event.end_at.flatMap { ISO8601DateFormatter().date(from: $0) },
      featuredBackground: event.featured_background ?? "#000000",
      featuredColor: event.featured_color ?? "#FFFFFF",
      bannerBackground: event.banner_background ?? "#081625",
      speakersCount: event.speakers_count ?? 0,
      participantsCount: event.participants_count ?? 0,
      featuredImageFile: await featuredFile,
      avatarFiles: await avatarFiles,
      upcoming: upcomingItems
    )

    NextEventStore.save(snapshot)
    WidgetCenter.shared.reloadAllTimelines()
    print("📅 NextEvent: saved (loaded back = \(NextEventStore.load() != nil)) + reloaded widgets")
  }

  private static func saveAvatars(_ urls: [String]?) async -> [String] {
    guard let urls else { return [] }
    let slice = Array(urls.prefix(3))

    return await withTaskGroup(of: (Int, String?).self) { group in
      for (index, urlString) in slice.enumerated() {
        group.addTask { (index, await saveImage(urlString, as: "next-avatar-\(index)", maxDimension: 120)) }
      }

      var indexed: [(Int, String)] = []

      for await (index, file) in group {
        if let file { indexed.append((index, file)) }
      }

      return indexed.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
  }

  private static func saveImage(_ urlString: String?, as name: String, maxDimension: CGFloat) async -> String? {
    guard let urlString, !urlString.isEmpty, let url = URL(string: urlString),
          let destination = LiveActivityShared.imageURL(for: "\(name).png") else { return nil }

    var request = URLRequest(url: url)
    request.timeoutInterval = 8

    guard let (data, _) = try? await URLSession.shared.data(for: request),
          let image = UIImage(data: data) else { return nil }

    let longest = max(image.size.width, image.size.height, 1)
    let scale = min(1, maxDimension / longest)
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

    let resized = UIGraphicsImageRenderer(size: size).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }

    guard let png = resized.pngData() else { return nil }

    try? png.write(to: destination, options: .atomic)

    return "\(name).png"
  }
}
