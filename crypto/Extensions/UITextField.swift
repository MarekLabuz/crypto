//
//  UITextField.swift
//  crypto
//
//  Created by Marek Łabuz on 20/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

extension UITextField {
  var doubleValue: Double? {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale.current
    return formatter.number(from: self.text ?? "")?.doubleValue ?? nil
  }
}
