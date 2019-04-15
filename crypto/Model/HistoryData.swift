//
//  HistoryItem.swift
//  crypto
//
//  Created by Marek Łabuz on 21/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import Foundation
import Charts
import SwiftyJSON

struct HistoryData {
  var type: Aggregation
  var lastFetched: Double
  var high = [ChartDataEntry]()
  var low = [ChartDataEntry]()
  var open = [ChartDataEntry]()
  var close = [ChartDataEntry]()
  var candlestick = [CandleChartDataEntry]()
  var isFetching: Bool
  
  var isEmpty: Bool {
    return candlestick.isEmpty && high.isEmpty && low.isEmpty && open.isEmpty && close.isEmpty
  }
  
  init(type: Aggregation, data: [JSON], cryptocurrency: Cryptocurrency, lastFetched: Double, isFetching: Bool) {
    self.lastFetched = lastFetched
    self.isFetching = isFetching
    self.type = type
    data.forEach { item in
      if let timestamp = item["timestamp"].double {
        let open = item["open"].double
        let close = item["close"].double
        let high = item["high"].double
        let low = item["low"].double
        
        if cryptocurrency.candlestickChart {
          guard open != nil && close != nil && high != nil && low != nil else { return }
          candlestick.append(CandleChartDataEntry(x: timestamp, shadowH: high!, shadowL: low!, open: open!, close: close!))
          return
        }
        
        if open != nil {
          self.open.append(ChartDataEntry(x: timestamp, y: open!))
        }
        if close != nil {
          self.close.append(ChartDataEntry(x: timestamp, y: close!))
        }
        if high != nil {
          self.high.append(ChartDataEntry(x: timestamp, y: high!))
        }
        if low != nil {
          self.low.append(ChartDataEntry(x: timestamp, y: low!))
        }
      }
    }
  }
}
