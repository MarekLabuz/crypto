//
//  SearchCurrencyTableViewCell.swift
//  crypto
//
//  Created by Marek Łabuz on 07/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class SearchCurrencyTableViewCell: UITableViewCell {
  
  @IBOutlet weak var symbol: UILabel!
  @IBOutlet weak var name: UILabel!
  
  func setupView(cryptocurrencySimple: CryptocurrencySimple) {
    symbol.text = cryptocurrencySimple.symbol
    name.text = cryptocurrencySimple.name
  }
}
