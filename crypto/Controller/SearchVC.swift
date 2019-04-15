//
//  SearchVC.swift
//  crypto
//
//  Created by Marek Łabuz on 05/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class SearchVC: UIViewController, UISearchBarDelegate {
  
  var delegate: SearchViewDelegate?
  
  @IBOutlet weak var loader: UIActivityIndicatorView!
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var tableView: UITableView!
  var filteredItems = [Any]()
  var allItems = [Any]()
  
  var type: SearchTypes?
  
  var selectedCryptocurrency: CryptocurrencySimple?
  var selectedExchange: Exchange?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    searchBar.delegate = self
    searchBar.placeholder = getPlaceholder()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    loader.isHidden = false
    loader.startAnimating()
    
    getData(completion: { (data) in
      self.loader.isHidden = true
      self.loader.stopAnimating()
      self.allItems = data
      self.updateList(searchText: self.searchBar.text)
    })
  }
  
  func getPlaceholder() -> String? {
    guard type != nil else { return nil }
    switch type! {
    case .Cryptocurrencies:
      return "Enter cryptocurrency"
    case .Exchanges:
      return "Enter exchange"
    case .Currencies:
      return "Enter currency"
    }
  }
  
  func updateList(searchText: String?) {
    filteredItems = allItems
    if searchText != nil && searchText != "" {
      filteredItems = filteredItems.filter(filter(type: type, searchtext: searchText!.lowercased()))
    }
    filteredItems = filteredItems.sorted(by: sort(type: type))
    tableView.reloadData()
  }
  
  @IBAction func searchBackBtnPressed(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    updateList(searchText: searchText)
  }
}

extension SearchVC: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0.1
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = filteredItems[indexPath.row]
    tableView.deselectRow(at: indexPath, animated: true)
    didSelect(element: item)
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filteredItems.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return cellFor(tableView: tableView, element: filteredItems[indexPath.row])
  }
}

extension SearchVC {
  
  func showSearchVC(type: SearchTypes) {
    guard let searchVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchVC") as? SearchVC else { return }
    searchVC.delegate = delegate
    searchVC.type = type
    searchVC.selectedCryptocurrency = selectedCryptocurrency
    searchVC.selectedExchange = selectedExchange
    present(searchVC, animated: true, completion: nil)
  }
  
  func didSelect(element: Any) {
    guard type != nil else { return }
    switch type! {
    case .Cryptocurrencies:
      selectedCryptocurrency = element as? CryptocurrencySimple
      showSearchVC(type: .Exchanges)
    case .Exchanges:
      selectedExchange = element as? Exchange
      showSearchVC(type: .Currencies)
    case .Currencies:
      guard let selectedCurrency = element as? String, selectedExchange != nil, selectedCryptocurrency != nil else { return }
      delegate?.didSelect(view: self, cryptocurrency: selectedCryptocurrency!, exchange: selectedExchange!, currency: selectedCurrency, completion: {
        if let unwindSegueIdentifier = self.delegate?.unwindSegueIdentifier() {
          self.performSegue(withIdentifier: unwindSegueIdentifier, sender: nil)
        }
      })
    }
  }
  
  func cellFor(tableView: UITableView, element: Any) -> UITableViewCell {
    guard type != nil else { return UITableViewCell() }
    switch type! {
    case .Cryptocurrencies:
      guard let cryptocurrencySimple = element as? CryptocurrencySimple,
        let cell = tableView.dequeueReusableCell(withIdentifier: "cryptocurrencyCell") as? SearchCurrencyTableViewCell else { return UITableViewCell() }
      cell.setupView(cryptocurrencySimple: cryptocurrencySimple)
      return cell
    case .Exchanges:
      guard let exchange = element as? Exchange,
        let cell = tableView.dequeueReusableCell(withIdentifier: "keyValueCell") as? KeyValueCell else { return UITableViewCell() }
      cell.setupView(key: exchange.country.emojiFlag, value: exchange.name)
      return cell
    case .Currencies:
      guard let currency = element as? String,
        let cell = tableView.dequeueReusableCell(withIdentifier: "keyValueCell") as? KeyValueCell else { return UITableViewCell() }
      cell.setupView(key: StockService.instance.currencySymbols[currency] ?? "", value: currency)
      return cell
    }
  }
  
  func getData(completion: @escaping ([Any]) -> ()) {
    guard type != nil else { return }
    switch type! {
    case .Cryptocurrencies:
      StockService.instance.getAllCryptocurrencies { simpleCurrencies in
        completion(simpleCurrencies)
      }
    case .Exchanges:
      guard selectedCryptocurrency != nil else { return }
      StockService.instance.getExchanges(cryptocurrencySymbol: selectedCryptocurrency!.symbol, completion: { exchanges in
        completion(exchanges)
      })
    case .Currencies:
      guard selectedCryptocurrency != nil, selectedExchange != nil else { return }
      StockService.instance.getCurrencies(cryptocurrencySymbol: selectedCryptocurrency!.symbol, exchangeId: selectedExchange!.id, completion: { currencies in
        completion(currencies)
      })
    }
  }
  
  func filter(type: SearchTypes?, searchtext: String) -> (Any) -> Bool {
    guard type != nil else { return { _ in return true } }
    switch type! {
    case .Cryptocurrencies:
      return { e in
        guard let a = e as? CryptocurrencySimple else { return false }
        return a.name.lowercased().range(of: searchtext) != nil || a.symbol.lowercased().range(of: searchtext) != nil
      }
    case .Exchanges:
      return { e in
        guard let a = e as? Exchange else { return false }
        return a.name.lowercased().range(of: searchtext) != nil || a.id.lowercased().range(of: searchtext) != nil
      }
    case .Currencies:
      return { e in
        guard let a = e as? String else { return false }
        return a.lowercased().range(of: searchtext) != nil
      }
    }
  }
  
  func sort(type: SearchTypes?) -> (Any, Any) -> Bool {
    guard type != nil else { return { (_, _) in return false } }
    switch type! {
    case .Cryptocurrencies:
      return { (_, _) in return false }
    case .Exchanges:
      return { (a, b) in
        guard let e1 = a as? Exchange, let e2 = b as? Exchange else { return false }
        return e1.name < e2.name
      }
    case .Currencies:
      return { (a, b) in
        guard let e1 = a as? String, let e2 = b as? String else { return false }
        return e1 < e2
      }
    }
  }
}
