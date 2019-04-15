//
//  Aggergation.swift
//  crypto
//
//  Created by Marek Łabuz on 25/12/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import Foundation

enum Aggregation: String {
  case h3 = "H3"
  case h12 = "H12"
  case h24 = "DAY"
  case d7 = "WEEK"
  case d31 = "MONTH"
  case d90 = "D90"
  case d180 = "HALFYEAR"
  case d365 = "YEAR"
}
