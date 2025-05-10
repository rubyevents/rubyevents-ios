import Foundation
import HotwireNative

extension HotwireTab {
  static let all: [HotwireTab] = {
    let tabs: [HotwireTab] = [
      .home,
      .events,
      .talks,
      .speakers
    ]
    
    return tabs
  }()
  
  static let home = HotwireTab(
    title: "Home",
    image: .init(systemName: "house")!,
    url: Router.instance.home_url()
  )
  
  static let events = HotwireTab(
    title: "Events",
    image: .init(systemName: "calendar")!,
    url: Router.instance.events_url()
  )
  
  static let talks = HotwireTab(
    title: "Talks",
    image: .init(systemName: "music.mic")!,
    url: Router.instance.talks_url()
  )
  
  static let speakers = HotwireTab(
    title: "Speakers",
    image: .init(systemName: "person.fill")!,
    url: Router.instance.speakers_url()
  )
}
