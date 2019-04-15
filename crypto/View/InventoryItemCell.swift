//
//  InventoryTableViewCell.swift
//  crypto
//
//  Created by Marek Łabuz on 08/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class InventoryItemCell: UITableViewCell {
  
  @IBOutlet weak var symbol: UILabel!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var equation: UILabel!
  @IBOutlet weak var gain: UILabel!
  @IBOutlet weak var loader: UIActivityIndicatorView!
  @IBOutlet weak var gainStackView: UIStackView!
  @IBOutlet weak var percentage: UILabel!
  
  func setupView(inventoryItem: InventoryItem) {
    symbol.text = inventoryItem.symbol
    name.text = inventoryItem.name
    gainStackView.isHidden = true
    loader.isHidden = false
    loader.startAnimating()
    
    symbol.adjustsFontSizeToFitWidth = true
    symbol.minimumScaleFactor = 0.5
    name.adjustsFontSizeToFitWidth = true
    name.minimumScaleFactor = 0.5
    gain.adjustsFontSizeToFitWidth = true
    gain.minimumScaleFactor = 0.5
    equation.adjustsFontSizeToFitWidth = true
    equation.minimumScaleFactor = 0.5
    
    if let code = inventoryItem.currency {
      equation.text = "\(inventoryItem.quantity.formatDoubleLocale()) × \(inventoryItem.cost.formatAsCurrency(code: code)) = \(inventoryItem.spent.formatAsCurrency(code: code))"
      InventoryService.instance.getGain(inventoryItem: inventoryItem, completion: { value in
        if let v = value {
          self.gain.text = (v < 0 ? "" : "+") + v.formatAsCurrency(code: code)
          self.gain.textColor = v.color
          let p = (v / inventoryItem.spent) * 100
          self.percentage.text = p.formatPercentage()
          self.percentage.textColor = p.color
        } else {
          self.gain.text = "NA"
          self.gain.textColor = UIColor.gray
          self.percentage.text = "NA"
          self.percentage.textColor = UIColor.gray
        }
        self.gainStackView.isHidden = false
        self.loader.isHidden = true
        self.loader.stopAnimating()
      })
    }
  }
}
