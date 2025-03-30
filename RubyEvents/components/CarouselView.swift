import SwiftUI

struct CarouselView: View {
  let imagesNames: [String] = ["image1","image2","image3"]

  @State private var currentIndex = 0
  let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
  
  var body: some View {
    VStack(spacing:0){
      TabView(selection:$currentIndex){
        ForEach(0..<imagesNames.count,id: \.self){ imageIndex in
          AsyncImage(url: URL(string: imagesNames[imageIndex])) { image in
              image.resizable()
              .scaledToFill()
              .frame(height: 200)
              .cornerRadius(30)
              .clipped()
              .tag(imageIndex)
          } placeholder: {
            Color.white
          }
        }
      }
      .tabViewStyle(PageTabViewStyle())
      .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
    .onReceive(timer){_ in
      withAnimation {
        currentIndex = (currentIndex + 1) % imagesNames.count
      }
    }
  }
}
