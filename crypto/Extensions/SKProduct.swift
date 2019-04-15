//
//  SKProduct.swift
//  crypto
//
//  Created by Marek Łabuz on 11/02/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import Foundation
import StoreKit

extension SKProduct {
  
  func localizedPrice() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = self.priceLocale
    return formatter.string(from: self.price)!
  }
  
}
