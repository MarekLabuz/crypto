//
//  StockService.swift
//  crypto
//
//  Created by Marek Łabuz on 05/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreData

class StockService {
  
  static let instance = StockService()
  private init() {}
  
  var cryptocurrenciesSimple = [CryptocurrencySimple]()
  var values = [String: Value]()
  var valuesQueue = [String: [(Value) -> Void]]()
  var historyData = [String: HistoryData]()
  var currentCurrency: String?
  
  let availableLines = ["high", "low", "open", "close"]
  let availableCharts: [Aggregation] = [.h3, .h12, .h24, .d7, .d31, .d90, .d180, .d365]
  
  let currencySymbols = NSLocale.availableLocaleIdentifiers
    .map { Locale(identifier: $0) }
    .reduce(into: [String: String]()) { (acc, curr) in
      if curr.currencyCode != nil {
        acc[curr.currencyCode!] = curr.currencySymbol ?? ""
      }
  }
  
  func fetchCryptocurrenciesByExchange() -> [(String, [Cryptocurrency])] {
    let fetchRequest = NSFetchRequest<Cryptocurrency>(entityName: "Cryptocurrency")
    do {
      var ccByExchange: [String: [Cryptocurrency]] = [:]
      (try CoreDataService.context.fetch(fetchRequest) as [Cryptocurrency]).forEach { cryptocurrency in
        guard let exchangeName = cryptocurrency.exchangeName else { return }
        if ccByExchange[exchangeName] == nil {
          ccByExchange[exchangeName] = [cryptocurrency]
        } else {
          ccByExchange[exchangeName]?.append(cryptocurrency)
        }
      }
      return ccByExchange.keys
        .reduce([]) { acc, key in
          guard let cryptocurrencies = ccByExchange[key] else { return acc }
          return acc + [(key, cryptocurrencies.sorted(by: { $0.name! < $1.name! }))]
        }
        .sorted(by: { $0.0 < $1.0 })
    } catch {
      debugPrint(error.localizedDescription)
      return []
    }
  }
  
  func getNumberOfCryptocurrencies() -> Int {
    let fetchRequest = NSFetchRequest<Cryptocurrency>(entityName: "Cryptocurrency")
    do {
      return (try CoreDataService.context.fetch(fetchRequest) as [Cryptocurrency]).count
    } catch {
      debugPrint(error.localizedDescription)
      return 0
    }
  }
  
  func add(cryptocurrencySimple: CryptocurrencySimple, exchange: Exchange, currency: String, completion: @escaping () -> ()) {
    let fetchRequest = NSFetchRequest<Cryptocurrency>(entityName: "Cryptocurrency")
    do {
      let cryptocurrencies = try CoreDataService.context.fetch(fetchRequest) as [Cryptocurrency]
      if let cryptocurrency = cryptocurrencies.find(fn: { c in c.symbol == cryptocurrencySimple.symbol && c.exchangeId == exchange.id }) {
        addValue(cryptocurrency: cryptocurrency, currency: currency, completion: completion)
      } else {
        let cryptocurrency = Cryptocurrency(context: CoreDataService.context)
        cryptocurrency.symbol = cryptocurrencySimple.symbol
        cryptocurrency.name = cryptocurrencySimple.name
        cryptocurrency.exchangeId = exchange.id
        cryptocurrency.exchangeName = exchange.name
        cryptocurrency.values = [currency]
        cryptocurrency.high = false
        cryptocurrency.low = false
        cryptocurrency.open = false
        cryptocurrency.close = true
        CoreDataService.saveContext(completion: completion)
      }
    } catch {
      debugPrint(error.localizedDescription)
    }
  }
  
  func addValue(cryptocurrency: Cryptocurrency, currency: String, completion: @escaping () -> ()) {
    cryptocurrency.setValue(cryptocurrency.values?.adding(currency) as NSArray?, forKey: "values")
    CoreDataService.saveContext(completion: completion)
  }
  
  func removeValue(cryptocurrency: Cryptocurrency, index: Int) {
    if var values = cryptocurrency.values as? [String], values.count > 1 {
      values.remove(at: index)
      cryptocurrency.setValue(values, forKey: "values")
      CoreDataService.saveContext(completion: nil)
    }
  }
  
  func swapValues(cryptocurrency: Cryptocurrency, from: Int, to: Int) {
    if var values = cryptocurrency.values as? [String] {
      values.swapAt(from, to)
      cryptocurrency.setValue(values as NSArray, forKey: "values")
      CoreDataService.saveContext(completion: nil)
    }
  }
  
  func clearHistoryData(cryptocurrency: Cryptocurrency) {
    (cryptocurrency.values as? [String])?.forEach({ currencySymbol in
      availableCharts.forEach({ type in
        if let cryptocurrencySymbol = cryptocurrency.symbol, let exchangeId = cryptocurrency.exchangeId {
//          print("\(type.rawValue)-\(cryptocurrencySymbol)-\(exchangeId)-\(currencySymbol)")
          historyData["\(type.rawValue)-\(cryptocurrencySymbol)-\(exchangeId)-\(currencySymbol)"] = nil
        }
      })
    })
  }
  
  func setChartDisplay(cryptocurrency: Cryptocurrency, key: String, value: Bool) {
    if availableLines.contains(key) {
      cryptocurrency.setValue(value, forKey: key)
      clearHistoryData(cryptocurrency: cryptocurrency)
      CoreDataService.saveContext(completion: nil)
    }
  }
  
  func setTypeOfChart(cryptocurrency: Cryptocurrency, index: Int) {
    cryptocurrency.candlestickChart = index == 1
    clearHistoryData(cryptocurrency: cryptocurrency)
    CoreDataService.saveContext(completion: nil)
  }
  
  func remove(cryptocurrency: Cryptocurrency, completion: @escaping () -> ()) {
    CoreDataService.context.delete(cryptocurrency)
    CoreDataService.saveContext(completion: completion)
  }
  
  func exists(view: UIViewController, cryptocurrency: CryptocurrencySimple, exchange: Exchange, currency: String) -> Bool {
    let cryptocurrencies = fetchCryptocurrenciesByExchange()
    guard let cryptocurrenciesWithExchange = cryptocurrencies.first(where: { tuple in tuple.0 == exchange.name }) else { return false }
    let contains =  cryptocurrenciesWithExchange.1.contains(where: { c in
      return c.symbol == cryptocurrency.symbol && c.exchangeId == exchange.id && c.values?.contains(currency) == true
    })
    if contains {
      let alert = UIAlertController(title: "Cannot add item", message: "Such item already exists", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      view.present(alert, animated: true, completion: nil)
    }
    return contains
  }
  
  func getTicker(cryptocurrencySymbol: String, exchangeId: String, currencySymbol: String, completion: @escaping (Value) -> (Void)) {
    let now = NSDate().timeIntervalSince1970
    let key = "\(cryptocurrencySymbol)-\(exchangeId)-\(currencySymbol)"
    
    if let value = values[key], value.isFetching || now - value.lastFetched < 180 {
      if value.isFetching {
        valuesQueue[key] = valuesQueue[key] ?? []
        valuesQueue[key]?.append(completion)
      }
      completion(value)
//      print("Currency from cache")
      return
    }
    
    values[key] = Value(cryptocurrencySymbol: cryptocurrencySymbol, exchangeId: exchangeId, currencySymbol: currencySymbol, price: nil, low24h: nil, open24h: nil, high24h: nil, ask: nil, bid: nil, marketCap: nil, change24h: nil, changePct24h: nil, volume: nil, lastUpdated: nil, lastFetched: now, isFetching: true)
    
//    print("Currency fetched")
    let query = "\(API)/ticker?query=\(cryptocurrencySymbol)/\(exchangeId)/\(currencySymbol)"
    Alamofire.request(query, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { response in
      guard var value = self.values[key] else { return }
      value.isFetching = false
      
      if let data = response.data {
        do {
          let jsonArray = try JSON(data: data).arrayValue
          if jsonArray.count > 0 {
            let jsonData = jsonArray[0]
            value.price = jsonData["last"].double
            value.open24h = jsonData["open"].double
            value.high24h = jsonData["high"].double
            value.low24h = jsonData["low"].double
            value.ask = jsonData["ask"].double
            value.bid = jsonData["bid"].double
            value.change24h = jsonData["change"].double
            value.changePct24h = jsonData["percentage"].double
            value.volume = jsonData["baseVolume"].double
            value.marketCap = jsonData["marketCap"].double
          }
        } catch {
          debugPrint(error.localizedDescription)
        }
      }
      
      self.values[key] = value
      completion(value)
      self.valuesQueue[key]?.forEach { callback in
        callback(value)
      }
      self.valuesQueue[key] = []
    }
  }
  
  func getAllCryptocurrencies(completion: @escaping ([CryptocurrencySimple]) -> Void) {
    if !cryptocurrenciesSimple.isEmpty {
//      print("coin list from cache")
      completion(cryptocurrenciesSimple)
      return
    }
//    print("coin list fetched")
    Alamofire.request("\(API)/symbols", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { response in
      if let data = response.data {
        do {
          let cryptoCurrencyData = try JSON(data: data).arrayValue
          self.cryptocurrenciesSimple = cryptoCurrencyData.map { cryptoCurrencyItem in
          if let symbol = cryptoCurrencyItem["symbol"].string, let name = cryptoCurrencyItem["name"].string {
            return CryptocurrencySimple(symbol: symbol, name: name, imageURL: "")
          }
            return CryptocurrencySimple(symbol: "", name: "", imageURL: "")
          }
        } catch {
          debugPrint(error.localizedDescription)
        }
        
        completion(self.cryptocurrenciesSimple)
      }
    }
  }
  
  func getHistoryData(type: Aggregation, cryptocurrency: Cryptocurrency, currencySymbol: String, completion: @escaping (HistoryData) -> Void) {
    guard let cryptocurrencySymbol = cryptocurrency.symbol, let exchangeId = cryptocurrency.exchangeId else {
      return
    }
    
    let now = NSDate().timeIntervalSince1970
    let key = "\(type.rawValue)-\(cryptocurrencySymbol)-\(exchangeId)-\(currencySymbol)"

    if let historyItem = historyData[key], historyItem.isFetching || now - historyItem.lastFetched < 180 {
//      print("History from cache")
      completion(historyItem)
      return
    }
    
    historyData[key] = HistoryData(type: type, data: [], cryptocurrency: cryptocurrency, lastFetched: now, isFetching: true)
    
    var lines = [String]()
    lines.appendWith(condition: cryptocurrency.high || cryptocurrency.candlestickChart, "high")
    lines.appendWith(condition: cryptocurrency.low || cryptocurrency.candlestickChart, "low")
    lines.appendWith(condition: cryptocurrency.open || cryptocurrency.candlestickChart, "open")
    lines.appendWith(condition: cryptocurrency.close || cryptocurrency.candlestickChart, "close")
    
    print("History fetched")
    let query = "\(API)/history?query=\(type.rawValue)/\(lines.joined(separator: ","))/\(cryptocurrencySymbol)/\(exchangeId)/\(currencySymbol)"
    Alamofire.request(query, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { response in
      guard var history = self.historyData[key] else { return }
      history.isFetching = false

      if let data = response.data {
        do {
          let jsonArray = try JSON(data: data).arrayValue
          if jsonArray.count > 0 {
            let historyDataJSON = jsonArray[0].arrayValue
            history = HistoryData(type: type, data: historyDataJSON, cryptocurrency: cryptocurrency, lastFetched: now, isFetching: false)
          }
        } catch {
          debugPrint(error.localizedDescription)
        }
      }
      
      self.historyData[key] = history
      completion(history)
    }
  }
  
  func getExchanges(cryptocurrencySymbol: String, completion: @escaping ([Exchange]) -> Void) {
    let query = "\(API)/exchanges?symbol=\(cryptocurrencySymbol)"
    Alamofire.request(query, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { response in
      guard let data = response.data else {
        completion([])
        return
      }
      do {
        let exchangesData = try JSON(data: data).arrayValue
        let exchanges = exchangesData.map { exchange -> Exchange in
          if let id = exchange["id"].string, let name = exchange["name"].string, let country = exchange["country"].string {
            return Exchange(id: id, name: name, country: country)
          }
          return Exchange(id: "", name: "", country: "")
        }
        completion(exchanges)
      } catch {
        debugPrint(error.localizedDescription)
        completion([])
      }
    }
  }
  
  func getCurrencies(cryptocurrencySymbol: String, exchangeId: String, completion: @escaping ([String]) -> Void) {
    let query = "\(API)/currencies?symbol=\(cryptocurrencySymbol)&exchangeId=\(exchangeId)"
    Alamofire.request(query, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { response in
      do {
        if let data = response.data, let currencies = try JSON(data: data).arrayObject as? [String] {
          completion(currencies)
          return
        }
      } catch {
        debugPrint(error.localizedDescription)
      }
      completion([])
    }
  }
}
