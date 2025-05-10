//
//  HomeViewSkeleton.swift
//  RubyEvents
//
//  Created by Marco Roth on 31.03.2025.
//

import SwiftUI

struct HomeViewSkeleton: View {
  @State private var isAnimating = false
  
  var body: some View {
    GeometryReader { geometry in
      ScrollView() {
        RoundedRectangle(cornerRadius: 0)
          .fill(Color.gray.opacity(0.2))
          .frame(maxWidth: .infinity)
          .frame(height: (geometry.size.height / 5) * 3.5)
          .opacity(isAnimating ? 1 : 0.2)
          .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        
        VStack(spacing: 24) {
          ForEach(0..<2, id: \.self) { index in
            VStack(alignment: .leading, spacing: 12) {
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 150, height: 24)
                .padding(.horizontal)
                .opacity(isAnimating ? 0.5 : 0.5)
                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.1 * Double(index)), value: isAnimating)
              
              HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { itemIndex in
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 120)
                    .opacity(isAnimating ? 1 : 0.5)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.1 * Double(itemIndex)), value: isAnimating)
                }
              }
              .padding(.horizontal)
              
            }
          }
        }
        .padding(.top, 24)
      }
      .edgesIgnoringSafeArea(.top)
    }
    .onAppear {
      App.instance.hideNavigationBar()
      isAnimating = true
    }
  }
}

#Preview {
  HomeViewSkeleton()
}
