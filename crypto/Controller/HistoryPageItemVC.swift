//
//  HistoryPageItemVC.swift
//  crypto
//
//  Created by Marek Łabuz on 21/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit
import Charts

class ChartXAxisFormatter: NSObject, IAxisValueFormatter {
  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    let date = Date(timeIntervalSince1970: value)
    let dateFormatter = DateFormatter()
    dateFormatter.locale = NSLocale.current
    dateFormatter.dateFormat = "yyyy-MM-dd\nHH:mm"
    return dateFormatter.string(from: date)
  }
}

class ChartYAxisFormatter: NSObject, IAxisValueFormatter {
  var currency: String
  
  init(currency: String) {
    self.currency = currency
    super.init()
  }
  
  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    return value.formatAsCurrency(code: currency)
  }
}

class HistoryPageItemVC: UIViewController, ChartViewDelegate {
  
  @IBOutlet var lineChartView: LineChartView!
  @IBOutlet var candleChartView: CandleStickChartView!
  @IBOutlet weak var segmentControl: UISegmentedControl!
  @IBOutlet weak var dataNotAvailable: UILabel!
  @IBOutlet weak var loader: UIActivityIndicatorView!
  @IBOutlet weak var selected: UILabel!
  
  var cryptocurrency: Cryptocurrency!
  var aggregation: Aggregation!
  var currency: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    initChart(lineChartView)
    initChart(candleChartView)
    
    lineChartView.delegate = self
    candleChartView.delegate = self
    
    NotificationCenter.default.addObserver(self, selector: #selector(rerenderChart(_:)), name: Notification.Name("CURRENCY_CHANGED"), object: nil)
  }
  
  @IBAction func onValueChange(_ sender: UISegmentedControl) {
    aggregation = StockService.instance.availableCharts[sender.selectedSegmentIndex]
    rerenderChart(nil)
  }
  
  @objc func rerenderChart(_ notification: Notification?) {
    loadingStart()
    guard let currency = notification?.object as? String ?? StockService.instance.currentCurrency else {
      self.loadingStop(error: true)
      return
    }
    StockService.instance.currentCurrency = currency
    StockService.instance.getHistoryData(type: aggregation, cryptocurrency: cryptocurrency, currencySymbol: currency, completion: { historyData in
      guard !historyData.isFetching && historyData.type == self.aggregation else { return }
      self.currency = currency
      if !historyData.isEmpty {
        self.loadingStop(error: false)
        self.drawChart(historyData: historyData, currency: currency)
      } else {
        self.loadingStop(error: true)
      }
    })
  }
  
  func loadingStart() {
    loader.isHidden = false
    loader.startAnimating()
    candleChartView.isHidden = true
    lineChartView.isHidden = true
    dataNotAvailable.isHidden = true
  }
  
  func loadingStop(error: Bool) {
    dataNotAvailable.isHidden = !error
    candleChartView.isHidden = error
    lineChartView.isHidden = error
    loader.stopAnimating()
    loader.isHidden = true
  }
  
  func getCandlestickBarWidths() -> [CGFloat] {
    return [1.5, 3.5]
  }
  
  func initChart(_ chart: ChartViewBase) {
    if let c = chart as? CandleStickChartView ?? chart as? LineChartView {
      c.leftAxis.enabled = false
      c.rightAxis.labelPosition = .insideChart
      c.rightAxis.labelFont = UIFont(name: "Avenir Next", size: 10)!
      c.rightAxis.labelTextColor = TEXT_COLOR
      c.rightAxis.yOffset = -5
      c.rightAxis.drawAxisLineEnabled = false
      c.rightAxis.gridColor = #colorLiteral(red: 0.8487040295, green: 0.8487040295, blue: 0.8487040295, alpha: 1)
      c.noDataText = ""
      c.scaleXEnabled = false
      c.scaleYEnabled = false
      c.pinchZoomEnabled = false
    }
    
    chart.chartDescription?.enabled = false
    
    chart.xAxis.labelPosition = .bottom
    chart.xAxis.setLabelCount(4, force: true)
    chart.xAxis.valueFormatter = ChartXAxisFormatter()
    chart.xAxis.avoidFirstLastClippingEnabled = true
    chart.xAxis.labelTextColor = TEXT_COLOR
    chart.xAxis.labelFont = UIFont(name: "Avenir Next", size: 10)!
    chart.xAxis.gridColor = #colorLiteral(red: 0.8487040295, green: 0.8487040295, blue: 0.8487040295, alpha: 1)
    
    chart.legend.textColor = TEXT_COLOR
    chart.legend.font = UIFont(name: "Avenir Next", size: 10)!
    chart.legend.yOffset = 0
    
    if let c = chart as? CandleStickChartView {
      c.legend.enabled = false
    } else {
      chart.extraBottomOffset = -20
    }
  }
  
  func drawChart(historyData: HistoryData, currency: String) {
    if !historyData.candlestick.isEmpty {
      candleChartView.rightAxis.valueFormatter = ChartYAxisFormatter(currency: currency)
      
      let barsWidths = getCandlestickBarWidths()
      
      let candlestick = CandleChartDataSet(values: historyData.candlestick, label: "Candlestick chart")
      candlestick.drawValuesEnabled = false
      candlestick.drawIconsEnabled = false
      candlestick.shadowWidth = barsWidths[0]
      candlestick.decreasingColor = RED
      candlestick.decreasingFilled = false
      candlestick.increasingColor = GREEN
      candlestick.increasingFilled = false
      candlestick.neutralColor = UIColor.lightGray
      candlestick.shadowColorSameAsCandle = true
      candlestick.highlightColor = #colorLiteral(red: 0.631372549, green: 0.1843137255, blue: 0.1450980392, alpha: 0.5)
      
      let candlestick2 = CandleChartDataSet(values: historyData.candlestick, label: "Candlestick chart")
      candlestick2.drawValuesEnabled = false
      candlestick2.drawIconsEnabled = false
      candlestick2.shadowColor = UIColor.clear
      candlestick2.shadowWidth = barsWidths[1]
      candlestick2.decreasingColor = RED
      candlestick2.decreasingFilled = false
      candlestick2.increasingColor = GREEN
      candlestick2.increasingFilled = false
      candlestick2.highlightColor = #colorLiteral(red: 0.631372549, green: 0.1843137255, blue: 0.1450980392, alpha: 0.5)
      
      let data = CandleChartData()
      data.addDataSet(candlestick)
      data.addDataSet(candlestick2)
      
      candleChartView.data = data
      candleChartView.isHidden = false
      lineChartView.isHidden = true
    } else {
      lineChartView.rightAxis.valueFormatter = ChartYAxisFormatter(currency: currency)
      let data = LineChartData()

      if cryptocurrency.high && !historyData.high.isEmpty {
        let high = LineChartDataSet(values: historyData.high, label: "High")
        high.highlightColor = #colorLiteral(red: 0.631372549, green: 0.1843137255, blue: 0.1450980392, alpha: 0.5)
        high.colors = [GREEN]
        high.drawCirclesEnabled = false
        high.drawValuesEnabled = false
        data.addDataSet(high)
      }
      
      if cryptocurrency.low && !historyData.low.isEmpty {
        let low = LineChartDataSet(values: historyData.low, label: "Low")
        low.highlightColor = #colorLiteral(red: 0.631372549, green: 0.1843137255, blue: 0.1450980392, alpha: 0.5)
        low.colors = [RED]
        low.drawCirclesEnabled = false
        low.drawValuesEnabled = false
        data.addDataSet(low)
      }
      
      if cryptocurrency.open && !historyData.open.isEmpty {
        let open = LineChartDataSet(values: historyData.open, label: "Open")
        open.highlightColor = #colorLiteral(red: 0.631372549, green: 0.1843137255, blue: 0.1450980392, alpha: 0.5)
        open.colors = [UIColor.lightGray]
        open.drawCirclesEnabled = false
        open.drawValuesEnabled = false
        data.addDataSet(open)
      }
      
      if cryptocurrency.close && !historyData.close.isEmpty {
        let close = LineChartDataSet(values: historyData.close, label: "Close")
        close.highlightColor = #colorLiteral(red: 0.631372549, green: 0.1843137255, blue: 0.1450980392, alpha: 0.5)
        close.colors = [BLUE]
        close.drawCirclesEnabled = false
        close.drawValuesEnabled = false
        data.addDataSet(close)
      }
      lineChartView.data = data
      candleChartView.isHidden = true
      lineChartView.isHidden = false
    }
  }
  
  func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
    if let currency = currency {
      let date = Date(timeIntervalSince1970: highlight.x)
      let dateFormatter = DateFormatter()
      dateFormatter.locale = NSLocale.current
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
      let x = dateFormatter.string(from: date)
      let y = highlight.y.formatAsCurrency(code: currency)
      selected.text = "\(x)   \(y)"
    }
  }
}
