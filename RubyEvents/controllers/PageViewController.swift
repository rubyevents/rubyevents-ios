import SwiftUI
import UIKit

struct PageViewController<Page: View>: UIViewControllerRepresentable {
  var pages: [Page]
  
  func makeUIViewController(context: Context) -> UIPageViewController {
    let pageViewController = UIPageViewController(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal)
    
    
    return pageViewController
  }
  
  
  func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
    guard let firstPage = pages.first else { return }

    pageViewController.setViewControllers(
      [UIHostingController(rootView: firstPage)], direction: .forward, animated: true)
  }
}
