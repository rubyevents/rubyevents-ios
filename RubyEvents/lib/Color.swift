import SwiftUI

extension Color {
  init(hex: String) {
    var string = hex
    
    if string.hasPrefix("#") {
      string.removeFirst()
    }
    
    if string.count == 3 {
      string = String(repeating: string[string.startIndex], count: 2)
        + String(repeating: string[string.index(string.startIndex, offsetBy: 1)], count: 2)
        + String(repeating: string[string.index(string.startIndex, offsetBy: 2)], count: 2)
    } else if !string.count.isMultiple(of: 2) || string.count > 8 {
      self.init(.red)
    }
    
    guard let color = UInt64(string, radix: 16) else {
      self.init(.yellow)
      return
    }

    if string.count == 2 {
      let gray = Double(Int(color) & 0xFF) / 255
      
      self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: 1)
      
    } else if string.count == 4 {
      let gray = Double(Int(color >> 8) & 0x00FF) / 255
      let alpha = Double(Int(color) & 0x00FF) / 255
      
      self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: alpha)
      
    } else if string.count == 6 {
      let red = Double(Int(color >> 16) & 0x0000FF) / 255
      let green = Double(Int(color >> 8) & 0x0000FF) / 255
      let blue = Double(Int(color) & 0x0000FF) / 255
      
      self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
      
    } else if string.count == 8 {
      let red = Double(Int(color >> 24) & 0x000000FF) / 255
      let green = Double(Int(color >> 16) & 0x000000FF) / 255
      let blue = Double(Int(color >> 8) & 0x000000FF) / 255
      let alpha = Double(Int(color) & 0x000000FF) / 255
    
      self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
      
    } else {
      self.init(.blue)
    }
  }
}
