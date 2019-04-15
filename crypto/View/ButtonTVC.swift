//
//  ButtonTVC.swift
//  crypto
//
//  Created by Marek Łabuz on 25/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class ButtonTVC: UITableViewCell {

  @IBOutlet weak var button: UIButton!
  var onClick: ((UIButton) -> Void)?
  
  func setupView(titleLabel: String, onClick: @escaping (UIButton) -> Void) {
    button.setTitle(titleLabel, for: .normal)
    self.onClick = onClick
  }
  
  @IBAction func buttonPressed(_ sender: UIButton) {
    onClick?(sender)
  }
}
