//
//  AlertCell.swift
//  crypto
//
//  Created by Marek Łabuz on 16/01/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import UIKit

class AlertCell: UITableViewCell {
  
  @IBOutlet weak var toggle: UISwitch!
  @IBOutlet weak var type: UILabel!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var symbol: UILabel!
  @IBOutlet weak var value: UILabel!
  var notification: NotificationItem!
  
  @IBAction func toggleValueChanged(_ sender: UISwitch) {
    NotificationsService.instance.toggle(notification: notification, isOn: sender.isOn)
  }
  
  func setupView(notification: NotificationItem) {
    self.notification = notification
    
    let dateFormatter = DateFormatter()
    dateFormatter.locale = NSLocale.current
    dateFormatter.dateFormat = "HH:mm"
    
    symbol.text = notification.symbol
    name.text = notification.name
    if let rawValue = notification.type, let notificationType = NotificationType(rawValue: rawValue)  {
      type.text = NotificationsService.instance.getTypeDescription(type: notificationType)
      if let code = notification.currency {
        switch notificationType {
        case .priceGoal, .priceInterval:
          value.text = notification.value.formatAsCurrency(code: code)
        case .timeGoal:
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "HH:mm"
          value.text = dateFormatter.string(from: Date(timeIntervalSince1970: notification.value / 1000))
        case .timeInterval:
          let hours = floor(notification.value / 3600000)
          let minutes = floor((notification.value - (hours * 3600000)) / 60000)
          value.text = "\(Int(hours))h \(Int(minutes))m"
        }
      }
    }
    toggle.isOn = notification.isOn
  }
}
