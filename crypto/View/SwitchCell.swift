//
//  SwitchCell.swift
//  crypto
//
//  Created by Marek Łabuz on 31/12/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class SwitchCell: UITableViewCell {
  
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var toggle: UISwitch!
  
  var onSwitch: ((Bool) -> ())?
  
  func setupView(label: String, toggleOn: Bool, onSwitch: @escaping (Bool) -> ()) {
    self.label.text = label
    toggle.isOn = toggleOn
    self.onSwitch = onSwitch
  }
  
  @IBAction func onSwitchValueChanged(_ sender: Any) {
    self.onSwitch?(toggle.isOn)
  }
}
