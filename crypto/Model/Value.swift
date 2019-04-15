//
//  Value.swift
//  crypto
//
//  Created by Marek Łabuz on 13/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import Foundation

struct Value {
  let cryptocurrencySymbol: String
  let exchangeId: String
  let currencySymbol: String
  
  var price: Double?
  
  var low24h: Double?
  var open24h: Double?
  var high24h: Double?
  
  var ask: Double?
  var bid: Double?
  
  var marketCap: Double?
  
  var change24h: Double?
  var changePct24h: Double?
  
  var volume: Double?
  
  var lastUpdated: Int?
  let lastFetched: Double
  
  var isFetching: Bool
}
