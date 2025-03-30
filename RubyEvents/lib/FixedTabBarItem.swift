//
//  FixedTabBarItem.swift
//  RubyEvents
//
//  Created by Marco Roth on 11.01.2025.
//

import UIKit

class FixedTabBarItem: UITabBarItem {
  override var title: String? {
    didSet {
      // Prevent the title from changing after initial setup
      if oldValue != nil {
        super.title = oldValue
      }
    }
  }
}
