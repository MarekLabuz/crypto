//
//  KeyValueCell.swift
//  crypto
//
//  Created by Marek Łabuz on 17/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class KeyValueCell: UITableViewCell {
  
  @IBOutlet weak var key: UILabel!
  @IBOutlet weak var value: UILabel!
  
  func setupView(key: String, value: String) {
    self.key.text = key
    self.value.text = value
  }
}
