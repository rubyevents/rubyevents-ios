//
//  EventResponse.swift
//  RubyEvents
//
//  Created by Marco Roth on 28.03.2025.
//

struct HomeList<T : Decodable>: Decodable {
  let name: String
  let items: [T]
  let url: String
}

struct HomeViewResponse: Decodable {
  let featured: [Event]
  let events: [HomeList<Event>]
  let talks: [HomeList<Talk>]
  let speakers: [HomeList<Speaker>]
}
