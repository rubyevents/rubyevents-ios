//
//  SearchViewModel.swift
//  RubyEvents
//

import Combine
import Foundation
import Typesense

@MainActor
final class SearchViewModel: ObservableObject {
  @Published var query = ""
  @Published var talkResults: [Talk] = []
  @Published var speakerResults: [SearchSpeaker] = []
  @Published var eventResults: [SearchEvent] = []
  @Published var isSearching = false
  @Published var hasSearched = false
  @Published var errorMessage: String?

  var isEmpty: Bool { talkResults.isEmpty && speakerResults.isEmpty && eventResults.isEmpty }

  private var client: Client?
  private var config: SearchConfig?
  private var searchTask: Task<Void, Never>?
  private var cancellables = Set<AnyCancellable>()

  init() {
    $query
      .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
      .removeDuplicates()
      .sink { [weak self] value in self?.performSearch(value) }
      .store(in: &cancellables)
  }

  func loadConfigIfNeeded() async {
    guard client == nil else { return }

    let endpoint = Router.instance.root_url()
      .appendingPathComponent("/hotwire/native/v1/search_config.json")
      .absoluteString

    do {
      let config: SearchConfig = try await APIService.shared.fetchData(from: endpoint)
      self.config = config

      guard let key = config.search_api_key, !key.isEmpty else {
        errorMessage = "Search isn't configured on the server (missing search key)."
        return
      }
      let nodes = config.nodes.map { Node(host: $0.host, port: String($0.port), nodeProtocol: $0.protocol) }
      client = Client(config: Configuration(nodes: nodes, apiKey: key))
      errorMessage = nil
    } catch {
      errorMessage = "Couldn't load search config: \(error.localizedDescription)"
    }
  }

  private func performSearch(_ value: String) {
    searchTask?.cancel()

    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      talkResults = []
      speakerResults = []
      eventResults = []
      hasSearched = false
      return
    }

    searchTask = Task { [weak self] in await self?.search(trimmed) }
  }

  private func search(_ query: String) async {
    guard client != nil, config != nil else { return }

    isSearching = true
    defer { isSearching = false }

    async let talks = searchTalks(query)
    async let speakers = searchSpeakers(query)
    async let events = searchEvents(query)

    let (t, s, e) = await (talks, speakers, events)
    guard !Task.isCancelled else { return }

    talkResults = t
    speakerResults = s
    eventResults = e
    hasSearched = true
  }

  private let fetchLimit = 40

  private func searchTalks(_ query: String) async -> [Talk] {
    guard let client, let c = config?.talks else { return [] }
    do {
      let params = SearchParameters(
        q: query,
        queryBy: c.query_by,
        queryByWeights: c.query_by_weights, filterBy: c.filter_by,
        sortBy: "_text_match:desc,recency_score:desc,date_timestamp:desc",
        perPage: fetchLimit
      )
      let (result, _) = try await client.collection(name: c.collection).documents().search(params, for: SearchTalk.self)
      return (result?.hits ?? []).compactMap { $0.document?.toTalk() }
    } catch {
      return []
    }
  }

  private func searchSpeakers(_ query: String) async -> [SearchSpeaker] {
    guard let client, let c = config?.speakers else { return [] }
    do {
      let params = SearchParameters(q: query, queryBy: c.query_by, queryByWeights: c.query_by_weights, perPage: fetchLimit)
      let (result, _) = try await client.collection(name: c.collection).documents().search(params, for: SearchSpeaker.self)
      return (result?.hits ?? []).compactMap { $0.document }
    } catch {
      print("⚠️ Typesense speakers search failed:", error)
      return []
    }
  }

  private func searchEvents(_ query: String) async -> [SearchEvent] {
    guard let client, let c = config?.events else { return [] }
    do {
      let params = SearchParameters(q: query, queryBy: c.query_by, queryByWeights: c.query_by_weights, perPage: fetchLimit)
      let (result, _) = try await client.collection(name: c.collection).documents().search(params, for: SearchEvent.self)
      return (result?.hits ?? []).compactMap { $0.document }
    } catch {
      print("⚠️ Typesense events search failed:", error)
      return []
    }
  }
}
