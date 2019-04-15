//
//  StockTableVC.swift
//  crypto
//
//  Created by Marek Łabuz on 05/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit
import CoreData

class StockTableVC: UIViewController {
  
  @IBOutlet weak var stockTable: UITableView!
  @IBOutlet weak var placeholder: UILabel!
  
  var cryptocurrencies = [(String, [Cryptocurrency])]()
  var selectedCryptocurrency: CryptocurrencySimple?
  var selectedExchange: Exchange?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    stockTable.delegate = self
    stockTable.dataSource = self
    
    navigationItem.leftBarButtonItem = editButtonItem
    
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
    stockTable.refreshControl = refreshControl
    
//    let fetchRequest = NSFetchRequest<Cryptocurrency>(entityName: "Cryptocurrency")
//
//    if let result = try? CoreDataService.context.fetch(fetchRequest) {
//      for object in result {
//        CoreDataService.context.delete(object)
//      }
//    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadStockTable), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    
    reloadStockTable()
  }
  
  @IBAction func unwindToStockTable(segue: UIStoryboardSegue) {}
  
  func getCurrency(indexPath: IndexPath) -> Cryptocurrency {
    let cryptocurrenciesTuple: (String, [Cryptocurrency]) = self.cryptocurrencies[indexPath.section]
    let cryptocurrencies = cryptocurrenciesTuple.1
    return cryptocurrencies[indexPath.row]
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    reloadStockTable()
  }

  func reloadPlaceholder() {
    if cryptocurrencies.count > 0 {
      stockTable.isHidden = false
      placeholder.isHidden = true
    } else {
      stockTable.isHidden = true
      placeholder.isHidden = false
    }
  }
  
  @objc func reloadStockTable() {
    cryptocurrencies = StockService.instance.fetchCryptocurrenciesByExchange()
    stockTable.reloadData()
    reloadPlaceholder()
  }
  
  @objc func refresh(_ refreshControl: UIRefreshControl) {
    reloadStockTable()
    refreshControl.endRefreshing()
  }
  
  override func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    stockTable.setEditing(editing, animated: true)
  }
  
  @IBAction func addCurrencyBtnPressed(_ sender: Any) {
    if StockService.instance.getNumberOfCryptocurrencies() < 3 || PurchaseService.instance.isPro {
      performSegue(withIdentifier: "toSearchVC", sender: nil)
    } else {
      let purchaseVC = PurchaseVC(nibName: "PurchaseVC", bundle: nil)
      present(purchaseVC, animated: true, completion: nil)
    }
  }
}

extension StockTableVC: UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return cryptocurrencies.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cryptocurrencies[section].1.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: "currencyCell") as? CrytocurrecyCell {
      cell.setupView(cryptocurrency: getCurrency(indexPath: indexPath))
      return cell
    }
    return UITableViewCell()
  }
  
//  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//    return 30
//  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return cryptocurrencies[section].0
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
  
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    let header = view as? UITableViewHeaderFooterView
    header?.textLabel?.textColor = .lightGray
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      StockService.instance.remove(cryptocurrency: getCurrency(indexPath: indexPath), completion: {
        self.cryptocurrencies[indexPath.section].1.remove(at: indexPath.row)
        if self.cryptocurrencies[indexPath.section].1.count == 0 {
          self.cryptocurrencies.remove(at: indexPath.section)
          tableView.deleteSections([indexPath.section], with: .fade)
        } else {
          tableView.deleteRows(at: [indexPath], with: .fade)
        }
        self.reloadPlaceholder()
      })
    }
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let currency = getCurrency(indexPath: indexPath)
    performSegue(withIdentifier: "toCurrencyDetailsVC", sender: currency)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    case "toSearchVC":
      if let destination = segue.destination as? SearchVC {
        destination.type = .Cryptocurrencies
        destination.delegate = self
      }
    case "toCurrencyDetailsVC":
      if let destination = segue.destination as? CryptocurrencyDetailsVC, let cryptocurrency = sender as? Cryptocurrency {
        destination.cryptocurrency = cryptocurrency
      }
    default:
      break
    }
  }
}

extension StockTableVC: SearchViewDelegate {
  func didSelect(view: UIViewController, cryptocurrency: CryptocurrencySimple, exchange: Exchange, currency: String, completion: @escaping () -> ()) {
    if !StockService.instance.exists(view: view, cryptocurrency: cryptocurrency, exchange: exchange, currency: currency) {
      StockService.instance.add(cryptocurrencySimple: cryptocurrency, exchange: exchange, currency: currency, completion: {
        completion()
      })
    }
  }
  
  func unwindSegueIdentifier() -> String? {
    return "unwindToStockTable"
  }
}
