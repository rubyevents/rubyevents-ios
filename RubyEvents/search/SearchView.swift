//
//  SearchView.swift
//  RubyEvents
//

import HotwireNative
import SwiftUI

enum SearchScope: String, CaseIterable, Identifiable {
  case all, speakers, events, talks

  var id: String { rawValue }

  var title: String {
    switch self {
    case .all: return "All"
    case .speakers: return "Speakers"
    case .events: return "Events"
    case .talks: return "Talks"
    }
  }
}

struct SearchView: View {
  @StateObject private var viewModel = SearchViewModel()
  var navigator: Navigator?
  var onDismiss: () -> Void

  @State private var scope: SearchScope = .all
  @FocusState private var searchFocused: Bool

  private var showSpeakers: Bool { scope == .all || scope == .speakers }
  private var showEvents: Bool { scope == .all || scope == .events }
  private var showTalks: Bool { scope == .all || scope == .talks }

  private var visibleResultsEmpty: Bool {
    (!showSpeakers || viewModel.speakerResults.isEmpty)
      && (!showEvents || viewModel.eventResults.isEmpty)
      && (!showTalks || viewModel.talkResults.isEmpty)
  }

  private let previewLimit = 4
  private var displayedSpeakers: [SearchSpeaker] { scope == .all ? Array(viewModel.speakerResults.prefix(previewLimit)) : viewModel.speakerResults }
  private var displayedEvents: [SearchEvent] { scope == .all ? Array(viewModel.eventResults.prefix(previewLimit)) : viewModel.eventResults }
  private var displayedTalks: [Talk] { scope == .all ? Array(viewModel.talkResults.prefix(previewLimit)) : viewModel.talkResults }

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          if showSpeakers, !viewModel.speakerResults.isEmpty {
            sectionHeader("Speakers", total: viewModel.speakerResults.count, seeAll: .speakers)
            ForEach(displayedSpeakers, id: \.slug) { speaker in
              SpeakerResultRow(speaker: speaker, onSelect: { route(speaker.profileURL) })
              Divider().padding(.leading, 68)
            }
          }

          if showEvents, !viewModel.eventResults.isEmpty {
            sectionHeader("Events", total: viewModel.eventResults.count, seeAll: .events)
            ForEach(displayedEvents, id: \.slug) { event in
              EventResultRow(event: event, onSelect: { route(event.eventURL) })
              Divider().padding(.leading, 16)
            }
          }

          if showTalks, !viewModel.talkResults.isEmpty {
            sectionHeader("Talks", total: viewModel.talkResults.count, seeAll: .talks)
            ForEach(displayedTalks) { talk in
              TalkResultRow(talk: talk, navigator: navigator)
              Divider().padding(.leading, 16)
            }
          }
        }
      }
      .overlay {
        if visibleResultsEmpty {
          emptyState
        }
      }
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: onDismiss) {
            Image(systemName: "xmark.circle.fill")
              .font(.title3)
              .foregroundStyle(.secondary, Color(.tertiarySystemFill))
          }
          .accessibilityLabel("Close")
        }
      }
      .searchable(
        text: $viewModel.query,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: "Search talks, speakers, events"
      )
      .searchScopes($scope) {
        ForEach(SearchScope.allCases) { scope in
          Text(scope.title).tag(scope)
        }
      }
      .modifier(SearchAutoFocus(focused: $searchFocused))
      .autocorrectionDisabled()
      .textInputAutocapitalization(.never)
    }
    .task { await viewModel.loadConfigIfNeeded() }
    .onAppear {
      searchFocused = true
    }
  }

  private func route(_ url: URL) {
    onDismiss()
    navigator?.route(url)
  }

  private func sectionHeader(_ title: String, total: Int, seeAll: SearchScope) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(.headline)
        .foregroundStyle(.primary)

      Spacer()

      if scope == .all, total > previewLimit {
        Button("See all \(total)") {
          withAnimation { scope = seeAll }
        }
        .font(.subheadline)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 8)
  }

  @ViewBuilder
  private var emptyState: some View {
    if let error = viewModel.errorMessage {
      VStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle")
          .font(.largeTitle)
          .foregroundStyle(.orange)
        Text("Search unavailable")
          .font(.headline)
        Text(error)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
      }
    } else if viewModel.isSearching {
      ProgressView()
    } else if viewModel.hasSearched {
      emptyMessage("No results", subtitle: "Try a different search")
    } else {
      emptyMessage("Search Ruby talks", subtitle: "By title, speaker, event, topic…")
    }
  }

  private func emptyMessage(_ title: String, subtitle: String) -> some View {
    VStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      Text(title).font(.headline)
      Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
    }
  }
}

private struct SpeakerResultRow: View {
  let speaker: SearchSpeaker
  var onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 12) {
        Avatar(name: speaker.name, url: speaker.avatar_url)
          .frame(width: 40, height: 40)
          .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(speaker.name)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
          if let handle = speaker.github_handle, !handle.isEmpty {
            Text("@\(handle)")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Spacer(minLength: 0)
        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

private struct EventResultRow: View {
  let event: SearchEvent
  var onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 12) {
        AsyncImage(url: event.avatarURL) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Image(systemName: "calendar")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 2) {
          Text(event.name)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
          if let subtitle = event.subtitle {
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Spacer(minLength: 0)
        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

private struct SearchAutoFocus: ViewModifier {
  var focused: FocusState<Bool>.Binding

  func body(content: Content) -> some View {
    if #available(iOS 18.0, *) {
      content.searchFocused(focused)
    } else {
      content
    }
  }
}

private struct TalkResultRow: View {
  let talk: Talk
  var navigator: Navigator?

  // TODO: native player — re-enable when the player branch is integrated.
  // @State private var showPlayer = false

  var body: some View {
    Button(action: {
      // TODO: native player — when integrated, prefer:
      //   if talk.opensNativeScreen { showPlayer = true } else if let url = talk.url { navigator?.route(url) }
      if let url = talk.url {
        navigator?.route(url)
      }
    }) {
      HStack(spacing: 12) {
        AsyncImage(url: talk.thumbnail_url) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Rectangle().fill(Color(.secondarySystemBackground))
        }
        .frame(width: 120, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 4) {
          Text(talk.title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          Text(talk.speakers.first.map { "\($0.name) • \(talk.event_name)" } ?? talk.event_name)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    // TODO: native player — re-enable when the player branch is integrated.
    // .fullScreenCover(isPresented: $showPlayer) {
    //   if let params = talk.playerParams {
    //     TalkPlayerScreen(
    //       params: params,
    //       navigator: navigator,
    //       onProgress: { _ in },
    //       onDismiss: { showPlayer = false }
    //     )
    //   }
    // }
  }
}
