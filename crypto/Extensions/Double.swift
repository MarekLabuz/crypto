//
//  Double.swift
//  crypto
//
//  Created by Marek Łabuz on 20/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

extension Double {
  func getRound() -> Double {
    var value = self
    var counter = 0
    while abs(value) < 1 && value != 0 {
      counter += 1
      value *= 10
    }
    let precision = pow(Double(10), Double(counter + 2))
    return (self * precision).rounded() / precision
  }
  
  func formatAsCurrency(code: String) -> String {
    let formatter = NumberFormatter()
    formatter.currencyCode = code
    formatter.numberStyle = .currency
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 20
    formatter.minimumIntegerDigits = 1
    return formatter.string(from: NSNumber(value: self.getRound())) ?? "NA"
  }
  
  func formatAsCurrency(symbol: String) -> String {
    let formatter = NumberFormatter()
    formatter.currencySymbol = symbol
    formatter.numberStyle = .currency
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 20
    formatter.minimumIntegerDigits = 1
    return formatter.string(from: NSNumber(value: self.getRound())) ?? "NA"
  }
  
  func formatDoubleLocale() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale.current
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 20
    formatter.minimumIntegerDigits = 1
    formatter.groupingSeparator = ""
    return formatter.string(from: NSNumber(value: self.getRound())) ?? "NA"
  }
  
  func formatPercentage() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    formatter.minimumIntegerDigits = 1
    return (self < 0 ? "" : "+") + (formatter.string(from: NSNumber(value: self / 100)) ?? "NA")
  }
  
  var color: UIColor {
    return self < 0 ? RED : GREEN
  }
}
