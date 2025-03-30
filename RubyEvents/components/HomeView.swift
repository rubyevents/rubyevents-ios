//
//  HomeView.swift
//  RubyEvents
//
//  Created by Marco Roth on 24.01.2025.
//

import SwiftUI
import HotwireNative

struct HomeView: View {
  @State private var featured: [Event] = []
  @State private var talks: [HomeList<Talk>] = []
  @State private var events: [HomeList<Event>] = []
  @State private var speakers: [HomeList<Speaker>] = []
  
  @State private var isLoading: Bool = true
  @State private var errorMessage: String? = nil
  @State private var hasLoadedInitialData: Bool = false
  
  var navigator: Navigator?
  
  var body: some View {
    GeometryReader { geometry in
      if isLoading {
        ProgressView("Loading events...").frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = errorMessage {
        VStack {
          Text("Error loading data")
            .font(.headline)
          Text(error)
            .font(.subheadline)
            .foregroundColor(.red)
          Button("Retry") {
            fetchData()
          }
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          FeaturedCarousel(events: featured, navigator: navigator)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: (geometry.size.height / 5) * 3.5)
          
          VStack(spacing: 24) {
            ForEach(talks, id: \.name) { list in
              TalkCarousel(
                title: list.name,
                talks: list.items,
                navigator: navigator,
                viewAllURL: URL(string: list.url)
              )
            }
            
            ForEach(events, id: \.name) { list in
              EventCarousel(
                title: list.name,
                events: list.items,
                navigator: navigator,
                viewAllURL: URL(string: list.url)
              )
            }
            
            ForEach(speakers, id: \.name) { list in
              SpeakerCarousel(
                title: list.name,
                speakers: list.items,
                navigator: navigator,
                viewAllURL: URL(string: list.url)
              )
            }
            
          }
          .padding(.top, 24)
        }
        .edgesIgnoringSafeArea(.top)
      }
    }
    .onAppear {
      navigator?.rootViewController.navigationBar.isHidden = true
      
      if !hasLoadedInitialData {
        fetchData()
        hasLoadedInitialData = true
      }
    }.onDisappear {
      navigator?.rootViewController.navigationBar.isHidden = false
    }
  }
  
  private func fetchData() {
    isLoading = true
    errorMessage = nil
    
    APIService.shared
      .fetchData(from: Router.instance.home_json_url().absoluteString) { (
        result: Result<HomeViewResponse, NetworkError>
      ) in
        DispatchQueue.main.async {
          isLoading = false
          
          switch result {
          case .success(let response):
            featured = response.featured
            events = response.events
            talks = response.talks
            speakers = response.speakers
          case .failure(let error):
            self.errorMessage = error.localizedDescription
          }
        }
      }
  }
  
  private func refreshData() async {
    do {
      let response: HomeViewResponse = try await APIService.shared.fetchData(from: Router.instance.home_json_url().absoluteString)
      featured = response.featured
      events = response.events
      talks = response.talks
      speakers = response.speakers
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

#Preview {
  HomeView()
}
