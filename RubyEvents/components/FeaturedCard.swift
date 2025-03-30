import SwiftUI
import HotwireNative

struct FeaturedCard: View {
  var event: Event
  var navigator: Navigator?
  
  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        VStack() {
          Spacer().frame(height: geometry.size.height / 6)
            
          if event.featured_image_url != nil {
            AsyncImage(url: URL(string: event.featured_image_url!)) { image in
              image.resizable().background() {
                Color(hex: event.featured_background)
              }.aspectRatio(16 / 9, contentMode: .fit)
            } placeholder: {
              Color(hex: event.featured_background)
            }
          } else {
            Text("No Image")
          }
            
          TextOverlay(event: event, navigator: navigator)
        }
        .background(Color(hex: event.featured_background))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }.edgesIgnoringSafeArea(.all)
    }
  }
}

//struct TextOverlay: View {
//  var event: Event
//    
//  var background: LinearGradient {
//    .linearGradient(
//      Gradient(colors: [Color(hex: event.background)]),
//      startPoint: .bottom,
//      endPoint: .center
//    )
//  }
//
//  var body: some View {
//    ZStack(alignment: .bottomLeading) {
//      // gradient
//      background
//      
//      VStack(alignment: .center) {
//        Text(event.name).font(.title).bold().padding(.bottom, 10)
//        Text(event.location + " • " + event.dateString())
//          .font(.caption)
//          .lineLimit(1)
//          .foregroundStyle(.secondary)
//      }.padding()
//    }.foregroundStyle(Color(hex: event.color))
//  }
//}

struct TextOverlay: View {
  var event: Event
  let navigator: Navigator?

  var background: LinearGradient {
    .linearGradient(
      Gradient(colors: [Color(hex: event.featured_background), .black.opacity(0.5)]),
      startPoint: .top,
      endPoint: .bottom
    )
  }

  var body: some View {
    ZStack {
      background

      VStack(spacing: 12) {
        Text(event.name)
          .font(.title2)
          .bold()
          .foregroundColor(Color(hex: event.featured_color))

        Text("\(event.location) • \(event.dateString())")
          .font(.caption)
          .foregroundColor(Color(hex: event.featured_color))
          .opacity(0.6)
          .bold(true)

        Button(action: {
          navigator?.route(event.url)
        }) {
          Text("Explore Talks")
            .font(.caption)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white)
            .foregroundColor(.black)
            .clipShape(Capsule())
            .bold()
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
      }
      .padding()
      .multilineTextAlignment(.center)
    }
  }
}

#Preview {
  FeaturedCard(event: Event.blueRidgeRuby())
}

#Preview {
  FeaturedCard(event: Event.railsConf2024())
}

#Preview {
  FeaturedCard(event: Event.rubyConf2024())
}

#Preview {
  FeaturedCard(event: Event.railsWorld2024())
}
