//
//  SegmentControlCell.swift
//  crypto
//
//  Created by Marek Łabuz on 07/01/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import UIKit

class SegmentControlCell: UITableViewCell {
  
  var handler: ((Int) -> ())?
  @IBOutlet weak var segmentControl: UISegmentedControl!
  
  func setupView(index: Int, handler: @escaping (Int) -> ()) {
    segmentControl.selectedSegmentIndex = index
    segmentControl.isHidden = false
    self.handler = handler
  }

  @IBAction func valueChanged(_ sender: UISegmentedControl) {
    handler?(sender.selectedSegmentIndex)
  }
}
