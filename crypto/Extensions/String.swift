//
//  String.swift
//  crypto
//
//  Created by Marek Łabuz on 01/12/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import Foundation

func getCountryCode(countryId: String) -> String {
  switch countryId {
  case "UK":
    return "GB"
  default:
    return countryId
  }
}

extension String {
  var emojiFlag: String {
    var s = ""
    for v in getCountryCode(countryId: self).unicodeScalars {
      s.unicodeScalars.append(UnicodeScalar(127397 + v.value)!)
    }
    return String(s)
  }
}
