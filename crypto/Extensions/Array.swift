//
//  Array.swift
//  crypto
//
//  Created by Marek Łabuz on 20/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import Foundation

extension Array where Element : Hashable {
  var unique: [Element] {
    return Array(Set(self))
  }
  func find(fn: (Element) -> Bool) -> Element? {
    let index = self.index(where: fn)
    if index == nil {
      return nil
    }
    return self[index!]
  }
  
  mutating func appendWith(condition: Bool, _ newElement: Element) {
    if condition {
      self.append(newElement)
    }
  }
}
