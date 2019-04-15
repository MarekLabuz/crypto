//
//  NotificationsService.swift
//  crypto
//
//  Created by Marek Łabuz on 13/01/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreData
import UserNotifications

class NotificationsService {
  
  static let instance = NotificationsService()
  let defaults = UserDefaults.standard
  
  var deviceToken: String?
  var notificationsID: String? {
    get {
      let value = defaults.string(forKey: "notificationsID")
      return value?.count == 36 ? value : ""
    }
    set {
      if newValue?.count == 36 {
        defaults.set(newValue, forKey: "notificationsID")
      }
    }
  }
  
  func getTypeDescription(type: NotificationType) -> String {
    switch type {
    case .priceGoal:
      return "When reaches the price"
    case .priceInterval:
      return "In equal price intervals"
    case .timeGoal:
      return "Every day at the same time"
    case .timeInterval:
      return "In equal time intervals"
    }
  }
  
  func fetchNotifictionsByExchange() -> [(String, [NotificationItem])] {
    let fetchRequest = NSFetchRequest<NotificationItem>(entityName: "NotificationItem")
    do {
      var nByExchange: [String: [NotificationItem]] = [:]
      (try CoreDataService.context.fetch(fetchRequest) as [NotificationItem]).forEach { notification in
        guard let exchangeName = notification.exchangeName else { return }
        if nByExchange[exchangeName] == nil {
          nByExchange[exchangeName] = [notification]
        } else {
          nByExchange[exchangeName]?.append(notification)
        }
      }
      return nByExchange.keys
        .reduce([]) { acc, key in
          guard let notifications = nByExchange[key] else { return acc }
          return acc + [(key, notifications.sorted(by: { $0.name! < $1.name! }))]
        }
        .sorted(by: { $0.0 < $1.0 })
    } catch {
      debugPrint(error.localizedDescription)
      return []
    }
  }
  
  func getNumberOfNotifications() -> Int {
    let fetchRequest = NSFetchRequest<NotificationItem>(entityName: "NotificationItem")
    do {
      return (try CoreDataService.context.fetch(fetchRequest) as [NotificationItem]).count
    } catch {
      debugPrint(error.localizedDescription)
      return 0
    }
  }
  
  func requestNotifications() {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options:[.alert, .sound]) { (granted, error) in
      if granted {
        DispatchQueue.main.async(execute: {
          UIApplication.shared.registerForRemoteNotifications()
        })
      } else{
        print("Notification permission denied.")
      }
    }
  }

  func registerDevice(token: String) {
    deviceToken = token
    let url = "\(API)/register?id=\(notificationsID ?? "")&deviceId=\(token)"
    let notifications = fetchNotifictionsByExchange()
      .reduce([]) { acc, curr in acc + curr.1 }
      .filter { notification in notification.isOn }
      .map { notification in
        return [
          "cryptocurrencyName": notification.name as Any,
          "cryptocurrencySymbol": notification.symbol as Any,
          "exchangeId": notification.exchangeId as Any,
          "exchangeName": notification.exchangeName as Any,
          "currency": notification.currency as Any,
          "type": notification.type as Any,
          "value": notification.value
        ]
    }
    let parameters: [String: Any] = [
      "notifications": notifications
    ]
    Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseString { response in
      switch response.result {
      case .success:
        do {
          self.notificationsID = try response.result.unwrap()
        } catch {
          debugPrint(error.localizedDescription)
        }
      case .failure(let error):
        debugPrint(error.localizedDescription)
      }
    }
  }
  
  func equal(value: Double, type: NotificationType, toAlert alert: NotificationItem) -> Bool {
    guard type.rawValue == alert.type else { return false }
    switch type {
    case .timeGoal:
      let calendar = Calendar(identifier: .gregorian)
      let date1 = Date(timeIntervalSince1970: value / 1000)
      let date2 = Date(timeIntervalSince1970: alert.value / 1000)
      return calendar.compare(date1, to: date2, toGranularity: .hour) == ComparisonResult.orderedSame &&
        calendar.compare(date1, to: date2, toGranularity: .minute) == ComparisonResult.orderedSame
    default:
      return value == alert.value
    }
  }
  
  func exists(cryptocurrencySimple: CryptocurrencySimple, exchange: Exchange, currency: String, type: NotificationType, value: Double) -> Bool {
    let fetchRequest = NSFetchRequest<NotificationItem>(entityName: "NotificationItem")
    do {
      let alerts = try CoreDataService.context.fetch(fetchRequest) as [NotificationItem]
      return alerts.contains { a in
        return a.symbol == cryptocurrencySimple.symbol && a.exchangeId == exchange.id && a.currency == currency && equal(value: value, type: type, toAlert: a)
      }
    } catch {
      debugPrint(error.localizedDescription)
      return false
    }
  }
  
  func add(cryptocurrencySimple: CryptocurrencySimple, exchange: Exchange, currency: String, type: NotificationType, value: Double, completion: @escaping (Bool) -> ()) {
    let notification = NotificationItem(context: CoreDataService.context)
    notification.currency = currency
    notification.symbol = cryptocurrencySimple.symbol
    notification.name = cryptocurrencySimple.name
    notification.exchangeId = exchange.id
    notification.exchangeName = exchange.name
    notification.type = type.rawValue
    notification.value = value
    notification.isOn = true
    sendAdd(notification: notification, completion: { result in
      if !result {
        CoreDataService.context.delete(notification)
        CoreDataService.saveContext(completion: {
          NotificationCenter.default.post(name: NSNotification.Name(rawValue: UPDATE_ALERTS_LIST), object: nil)
        })
      }
      completion(result)
    })
    CoreDataService.saveContext(completion: nil)
  }
  
  func remove(notification: NotificationItem, completion: @escaping (Bool) -> ()) {
    let currency = notification.currency
    let symbol = notification.symbol
    let name = notification.name
    let exchangeId = notification.exchangeId
    let exchangeName = notification.exchangeName
    let type = notification.type
    let value = notification.value
    let isOn = notification.isOn
    sendRemove(notification: notification, completion: { success in
      if !success {
        let n = NotificationItem(context: CoreDataService.context)
        n.currency = currency
        n.symbol = symbol
        n.name = name
        n.exchangeId = exchangeId
        n.exchangeName = exchangeName
        n.type = type
        n.value = value
        n.isOn = isOn
        CoreDataService.saveContext(completion: {
          NotificationCenter.default.post(name: NSNotification.Name(rawValue: UPDATE_ALERTS_LIST), object: nil)
        })
        completion(false)
      }
    })
    CoreDataService.context.delete(notification)
    CoreDataService.saveContext(completion: {
      completion(true)
    })
  }
  
  func replace(notification: NotificationItem, newNotification: [String: Any], completion: @escaping (Bool) -> ()) {
    let currency = notification.currency
    let symbol = notification.symbol
    let name = notification.name
    let exchangeId = notification.exchangeId
    let exchangeName = notification.exchangeName
    let type = notification.type
    let value = notification.value
    let isOn = notification.isOn
    sendReplace(notification: notification, newNotification: newNotification, completion: { success in
      if !success {
        notification.setValue(currency, forKey: "currency")
        notification.setValue(symbol, forKey: "symbol")
        notification.setValue(name, forKey: "name")
        notification.setValue(exchangeId, forKey: "exchangeId")
        notification.setValue(exchangeName, forKey: "exchangeName")
        notification.setValue(type, forKey: "type")
        notification.setValue(value, forKey: "value")
        notification.setValue(isOn, forKey: "isOn")
        CoreDataService.saveContext(completion: {
          NotificationCenter.default.post(name: NSNotification.Name(rawValue: UPDATE_ALERTS_LIST), object: nil)
        })
      }
      completion(success)
    })
    notification.setValue(newNotification["currency"], forKey: "currency")
    notification.setValue(newNotification["symbol"], forKey: "symbol")
    notification.setValue(newNotification["name"], forKey: "name")
    notification.setValue(newNotification["exchangeId"], forKey: "exchangeId")
    notification.setValue(newNotification["exchangeName"], forKey: "exchangeName")
    notification.setValue(newNotification["type"], forKey: "type")
    notification.setValue(newNotification["value"], forKey: "value")
    notification.setValue(newNotification["isOn"], forKey: "isOn")
    CoreDataService.saveContext(completion: nil)
  }
  
  func toggle(notification: NotificationItem, isOn: Bool) {
    notification.setValue(isOn, forKey: "isOn")
    CoreDataService.saveContext(completion: {
      if isOn {
        self.sendAdd(notification: notification, completion: { success in
          if !success {
//            print("revert add")
            notification.isOn = false
            CoreDataService.saveContext(completion: {
              NotificationCenter.default.post(name: NSNotification.Name(rawValue: UPDATE_ALERTS_LIST), object: nil)
            })
          }
        })
      } else {
        self.sendRemove(notification: notification, completion: { success in
          if !success {
//            print("revert remove")
            notification.isOn = true
            CoreDataService.saveContext(completion: {
              NotificationCenter.default.post(name: NSNotification.Name(rawValue: UPDATE_ALERTS_LIST), object: nil)
            })
          }
        })
      }
    })
  }
  
  func sendRemove(notification: NotificationItem, completion: @escaping (Bool) -> ()) {
    guard
      let notificationsID = notificationsID,
      let deviceToken = deviceToken,
      let symbol = notification.symbol,
      let exchangeId = notification.exchangeId,
      let currency = notification.currency,
      let type = notification.type
    else {
      completion(false)
      return
    }
    let value = notification.value
    let url = "\(API)/notifications?id=\(notificationsID)&deviceId=\(deviceToken)&symbol=\(symbol)&exchangeId=\(exchangeId)&currency=\(currency)&type=\(type)&value=\(value)"
    Alamofire.request(url, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: nil).validate(statusCode: 200..<300).responseString { response in
      switch response.result {
      case .success:
        completion(true)
        break
      case .failure(let error):
        debugPrint(error.localizedDescription)
        completion(false)
      }
    }
  }
  
  func sendReplace(notification: NotificationItem, newNotification: [String: Any], completion: @escaping (Bool) -> ()) {
    guard
      let notificationsID = notificationsID,
      let deviceToken = deviceToken,
      let symbol = notification.symbol,
      let exchangeId = notification.exchangeId,
      let currency = notification.currency,
      let type = notification.type
      else {
        completion(false)
        return
    }
    let value = notification.value
    let parameters: [String: Any] = [
      "notification": [
        "symbol": symbol,
        "exchangeId": exchangeId,
        "currency": currency,
        "type": type,
        "value": value
      ],
      "newNotification": newNotification
    ]
    let url = "\(API)/notifications?id=\(notificationsID)&deviceId=\(deviceToken)"
    Alamofire.request(url, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: nil).validate(statusCode: 200..<300).responseString { response in
      switch response.result {
      case .success:
        completion(true)
        break
      case .failure(let error):
        debugPrint(error.localizedDescription)
        completion(false)
      }
    }
  }
  
  func sendAdd(notification: NotificationItem, completion: @escaping (Bool) -> ()) {
    guard
      let symbol = notification.symbol,
      let name = notification.name,
      let exchangeId = notification.exchangeId,
      let exchangeName = notification.exchangeName,
      let currency = notification.currency,
      let rawValue = notification.type,
      let type = NotificationType(rawValue: rawValue)
    else {
      completion(false)
      return
    }
    let value = notification.value
    let cryptocurrencySimple = CryptocurrencySimple(symbol: symbol, name: name, imageURL: "")
    let exchange = Exchange(id: exchangeId, name: exchangeName, country: "")
    sendAdd(cryptocurrencySimple: cryptocurrencySimple, exchange: exchange, currency: currency, type: type, value: value, completion: completion)
  }
  
  func sendAdd(cryptocurrencySimple: CryptocurrencySimple, exchange: Exchange, currency: String, type: NotificationType, value: Double, completion: @escaping (Bool) -> ()) {
    guard let notificationsID = notificationsID, let deviceToken = deviceToken else { return }
    let url = "\(API)/notifications?id=\(notificationsID)&deviceId=\(deviceToken)"
    let parameters: [String: Any] = [
      "name": cryptocurrencySimple.name,
      "symbol": cryptocurrencySimple.symbol,
      "exchangeId": exchange.id,
      "exchangeName": exchange.name,
      "currency": currency,
      "type": type.rawValue,
      "value": value
    ]
    Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).validate(statusCode: 200..<300).responseString { response in
      switch response.result {
      case .success:
        completion(true)
        break
      case .failure(let error):
        debugPrint(error.localizedDescription)
        completion(false)
      }
    }
  }
  
}
