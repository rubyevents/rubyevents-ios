import SwiftUI

struct PageView<Page: View>: View {
  var pages: [Page]
  
  var body: some View {
    PageViewController(pages: pages).aspectRatio(2 / 3, contentMode: .fit)
  }
}

#Preview {
  PageView<FeaturedCard>(pages: [FeaturedCard(event: Event.blueRidgeRuby())])
}


