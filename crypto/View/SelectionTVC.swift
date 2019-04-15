//
//  SelectionTVC.swift
//  crypto
//
//  Created by Marek Łabuz on 17/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class SelectionTVC: UITableViewCell {

  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var sublabel: UILabel!
  
  func setupView(label: String, sublabel: String, currentSelection: String?) {
    self.label.text = label
    self.sublabel.text = sublabel
    if label == currentSelection {
      accessoryType = .checkmark
    } else {
      accessoryType = .none
    }
    
  }
}
