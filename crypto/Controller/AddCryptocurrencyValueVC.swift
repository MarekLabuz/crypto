//
//  AddCryptocurrencyValueVC.swift
//  crypto
//
//  Created by Marek Łabuz on 10/12/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class AddCryptocurrencyValueVC: UIViewController, SearchViewDelegate {
  
  var cryptocurrency: Cryptocurrency!
  
  @IBAction func addButtonPressed(_ sender: Any) {
    guard let searchVC = UIStoryboard(name: "Main", bundle: nil)
      .instantiateViewController(withIdentifier: "SearchVC") as? SearchVC else { return }
    searchVC.delegate = self
    searchVC.type = .Currencies
    searchVC.selectedCryptocurrency = CryptocurrencySimple(symbol: cryptocurrency.symbol!, name: cryptocurrency.name!, imageURL: "")
    searchVC.selectedExchange = Exchange(id: cryptocurrency.exchangeId!, name: cryptocurrency.exchangeName!, country: "")
    present(searchVC, animated: true, completion: nil)
  }
  
  func data(type: SearchTypes?, get: @escaping ([Any]) -> ()) {
    StockService.instance.getCurrencies(cryptocurrencySymbol: cryptocurrency.symbol!, exchangeId: cryptocurrency.exchangeId!, completion: { currencies in
      get(currencies)
    })
  }
  
  func didSelect(view: UIViewController, cryptocurrency: CryptocurrencySimple, exchange: Exchange, currency: String, completion: @escaping () -> ()) {
    if !StockService.instance.exists(view: view, cryptocurrency: cryptocurrency, exchange: exchange, currency: currency) {
      StockService.instance.addValue(cryptocurrency: self.cryptocurrency, currency: currency, completion: {
        completion()
      })
    }
  }
  
  func unwindSegueIdentifier() -> String? {
    return "unwindToCurrencyPage"
  }
  
}
