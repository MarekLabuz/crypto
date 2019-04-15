//
//  CrytocurrecyCell.swift
//  crypto
//
//  Created by Marek Łabuz on 05/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class CrytocurrecyCell: UITableViewCell {
  
  @IBOutlet weak var symbol: UILabel!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var price: UILabel!
  @IBOutlet weak var change24h: UILabel!
  @IBOutlet weak var change24hSV: UIStackView!
  @IBOutlet weak var loader: UIActivityIndicatorView!
  @IBOutlet weak var valueSV: UIStackView!
  @IBOutlet weak var label24h: UILabel!
  
  func setupView(cryptocurrency: Cryptocurrency) {
    symbol.text = cryptocurrency.symbol
    name.text = cryptocurrency.name
    
    change24hSV.isHidden = false
    valueSV.isHidden = true
    loader.startAnimating()
    loader.isHidden = false
  
    price.minimumScaleFactor = 0.5
    price.adjustsFontSizeToFitWidth = true
    symbol.minimumScaleFactor = 0.5
    symbol.adjustsFontSizeToFitWidth = true
    name.minimumScaleFactor = 0.5
    name.adjustsFontSizeToFitWidth = true
    
    guard let currencySymbol = cryptocurrency.values?[0] as? String, let cryptocurrencySymbol = cryptocurrency.symbol, let exchangeId = cryptocurrency.exchangeId else { return }
    StockService.instance.getTicker(cryptocurrencySymbol: cryptocurrencySymbol, exchangeId: exchangeId, currencySymbol: currencySymbol, completion: { value in
      guard self.symbol.text == value.cryptocurrencySymbol, !value.isFetching else { return }
      
      self.price.text = value.price?.formatAsCurrency(code: value.currencySymbol) ?? "NA"
      if self.price.text == "NA" {
        self.price.textColor = UIColor.gray
      } else {
        self.price.textColor = #colorLiteral(red: 0.1215686275, green: 0.1215686275, blue: 0.1215686275, alpha: 1)
      }
      self.change24h.text = value.changePct24h?.formatPercentage() ?? "NA"
      self.change24h.textColor = value.changePct24h?.color
      if self.change24h.text == "NA" {
        self.change24hSV.isHidden = true
      }
      
      self.valueSV.isHidden = false
      self.loader.stopAnimating()
      self.loader.isHidden = true
    })
  }
}
