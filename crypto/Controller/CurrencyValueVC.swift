//
//  CurrencyValueVC.swift
//  crypto
//
//  Created by Marek Łabuz on 14/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class CurrencyValueVC: UIViewController {
  
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var loader: UIActivityIndicatorView!
  
  @IBOutlet weak var price: UILabel!
  @IBOutlet weak var marketCap: UILabel!
  @IBOutlet weak var change24h: UILabel!
  @IBOutlet weak var volume24h: UILabel!
  @IBOutlet weak var high: UILabel!
  @IBOutlet weak var low: UILabel!
  @IBOutlet weak var open: UILabel!
  @IBOutlet weak var lastUpdate: UILabel!
  @IBOutlet weak var ask: UILabel!
  @IBOutlet weak var bid: UILabel!
  
  var cryptocurrency: Cryptocurrency!
  var currencySymbol: String!
  
  func timeAgoSinceDate(date: NSDate) -> String {
    let calendar = NSCalendar.current
    let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
    let now = NSDate()
    let earliest = now.earlierDate(date as Date)
    let latest = (earliest == now as Date) ? date : now
    let components = calendar.dateComponents(unitFlags, from: earliest as Date,  to: latest as Date)
    
    if (components.year! >= 2) {
      return "\(components.year!) years ago"
    } else if (components.year! >= 1){
      return "1 year ago"
    } else if (components.month! >= 2) {
      return "\(components.month!) months ago"
    } else if (components.month! >= 1){
      return "1 month ago"
    } else if (components.weekOfYear! >= 2) {
      return "\(components.weekOfYear!) weeks ago"
    } else if (components.weekOfYear! >= 1){
      return "1 week ago"
    } else if (components.day! >= 2) {
      return "\(components.day!) days ago"
    } else if (components.day! >= 1){
      return "1 day ago"
    } else if (components.hour! >= 2) {
      return "\(components.hour!) hours ago"
    } else if (components.hour! >= 1){
      return "1 hour ago"
    } else if (components.minute! >= 2) {
      return "\(components.minute!) minutes ago"
    } else if (components.minute! >= 1){
      return "1 minute ago"
    } else if (components.second! >= 3) {
      return "less than a minute ago"
    } else {
      return "just now"
    }
  }
  
  func adjust(_ label: UILabel) {
    label.minimumScaleFactor = 0.5
    label.adjustsFontSizeToFitWidth = true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    adjust(price)
    adjust(change24h)
    adjust(marketCap)
    adjust(open)
    adjust(high)
    adjust(low)
    adjust(ask)
    adjust(bid)
    adjust(volume24h)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    price.isHidden = true
    change24h.isHidden = true
    stackView.isHidden = true
    loader.isHidden = false
    loader.startAnimating()
    
    StockService.instance.getTicker(cryptocurrencySymbol: cryptocurrency.symbol!, exchangeId: cryptocurrency.exchangeId!, currencySymbol: currencySymbol, completion: { value in
      guard self.cryptocurrency.symbol == value.cryptocurrencySymbol, !value.isFetching else { return }
      
      self.price.text = value.price?.formatAsCurrency(code: value.currencySymbol) ?? "NA"
      
      self.marketCap.text = value.marketCap?.formatAsCurrency(code: value.currencySymbol) ?? "NA"
      if value.marketCap == nil { self.marketCap.textColor = UIColor.gray }
      
      self.change24h.text = "\(value.changePct24h?.formatPercentage() ?? "NA") (\(value.change24h?.formatAsCurrency(code: value.currencySymbol) ?? "NA"))"
      self.change24h.textColor = value.changePct24h?.color ?? UIColor.gray
      
      self.volume24h.text = value.volume?.formatAsCurrency(symbol: value.cryptocurrencySymbol) ?? "NA"
      if value.volume == nil { self.volume24h.textColor = UIColor.gray }
      
      self.high.text = value.high24h?.formatAsCurrency(code: value.currencySymbol) ?? "NA"
      if value.high24h == nil { self.high.textColor = UIColor.gray }
      
      self.ask.text = value.ask?.formatAsCurrency(code: value.currencySymbol) ?? "NA"
      if value.ask == nil { self.ask.textColor = UIColor.gray }
      
      self.bid.text = value.bid?.formatAsCurrency(code: value.currencySymbol) ?? "NA"
      if value.bid == nil { self.bid.textColor = UIColor.gray }
      
      self.low.text = value.low24h?.formatAsCurrency(code: value.currencySymbol) ?? "NA"
      if value.low24h == nil { self.low.textColor = UIColor.gray }

      self.open.text = value.open24h?.formatAsCurrency(code: value.currencySymbol) ?? "NA"
      if value.open24h == nil { self.open.textColor = UIColor.gray }

      self.lastUpdate.text = "Updated \(self.timeAgoSinceDate(date: NSDate(timeIntervalSince1970: TimeInterval(value.lastUpdated ?? Int(value.lastFetched)))))"
      
      self.price.isHidden = false
      self.change24h.isHidden = false
      self.stackView.isHidden = false
      self.loader.isHidden = true
      self.loader.stopAnimating()
      
    })
  }
  
  override func viewDidAppear(_ animated: Bool) {
    NotificationCenter.default.post(name: Notification.Name("CURRENCY_CHANGED"), object: self.currencySymbol)
  }
}
