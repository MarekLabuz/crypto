//
//  InventoryService.swift
//  crypto
//
//  Created by Marek Łabuz on 08/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import Foundation
import CoreData

class InventoryService {
  
  static let instance = InventoryService()
  private init() {}

  func fetchInventoryItemsByExchange() -> [(String, [InventoryItem])] {
    let fetchRequest = NSFetchRequest<InventoryItem>(entityName: "InventoryItem")
    do {
      var iiByExchange: [String: [InventoryItem]] = [:]
      (try CoreDataService.context.fetch(fetchRequest) as [InventoryItem]).forEach { inventoryItem in
        guard let exchangeName = inventoryItem.exchangeName else { return }
        if iiByExchange[exchangeName] == nil {
          iiByExchange[exchangeName] = [inventoryItem]
        } else {
          iiByExchange[exchangeName]?.append(inventoryItem)
        }
      }
      return iiByExchange.keys
        .reduce([]) { acc, key in
          guard let inventoryItems = iiByExchange[key] else { return acc }
          return acc + [(key, inventoryItems.sorted(by: { $0.name! < $1.name! }))]
        }
        .sorted(by: { $0.0 < $1.0 })
    } catch {
      debugPrint(error.localizedDescription)
      return []
    }
  }
  
  func getNumberOfInventoryItems() -> Int {
    let fetchRequest = NSFetchRequest<InventoryItem>(entityName: "InventoryItem")
    do {
      return (try CoreDataService.context.fetch(fetchRequest) as [InventoryItem]).count
    } catch {
      debugPrint(error.localizedDescription)
      return 0
    }
  }
  
  func addOrReplace(inventoryItem: InventoryItem?, cryptocurrencySimple: CryptocurrencySimple, exchange: Exchange, currency: String, quantity: Double, cost: Double, spent: Double, completion: @escaping () -> ()) {
    let inventoryItem = inventoryItem ?? InventoryItem(context: CoreDataService.context)
    inventoryItem.symbol = cryptocurrencySimple.symbol
    inventoryItem.name = cryptocurrencySimple.name
    inventoryItem.exchangeId = exchange.id
    inventoryItem.exchangeName = exchange.name
    inventoryItem.currency = currency
    inventoryItem.quantity = quantity
    inventoryItem.cost = cost
    inventoryItem.spent = spent
    CoreDataService.saveContext(completion: completion)
  }
  
  func remove(inventoryItem: InventoryItem, completion: @escaping () -> ()) {
    CoreDataService.context.delete(inventoryItem)
    CoreDataService.saveContext(completion: completion)
  }
  
  func getGain(inventoryItem: InventoryItem, completion: @escaping (Double?) -> ()) {
    guard let symbol = inventoryItem.symbol, let exchangeId = inventoryItem.exchangeId, let currency = inventoryItem.currency else { return }
    StockService.instance.getTicker(cryptocurrencySymbol: symbol, exchangeId: exchangeId, currencySymbol: currency, completion: { value in
      guard symbol == value.cryptocurrencySymbol, !value.isFetching else { return }
      
      guard let price = value.price else {
        completion(nil)
        return
      }
      let gain = inventoryItem.quantity * (price - inventoryItem.cost)
      completion(gain)
    })
  }
}
