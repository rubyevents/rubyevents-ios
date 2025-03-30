//
//  TestSwif.swift
//  RubyEvents
//
//  Created by Marco Roth on 31.01.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
      List {
        Text("Item 1").contextMenu { menuItems }
        Text("Item 2").contextMenu { menuItems }
        Text("Item 3").contextMenu { menuItems }
        Text("Item 4").contextMenu { menuItems }
        Text("Item 5").contextMenu { menuItems }
      }
    }
    
    var menuItems: some View {
        Group {
            Button("Action 1", action: {})
            Button("Action 2", action: {})
            Button("Action 3", action: {})
        }
    }
}

#Preview {
  ContentView()
}
