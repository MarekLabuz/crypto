//
//  InventoryTableVC.swift
//  crypto
//
//  Created by Marek Łabuz on 08/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit
import CoreData

class InventoryTableVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var sumSpent: UILabel!
  @IBOutlet weak var sumGain: UILabel!
  @IBOutlet weak var inventoryTable: UITableView!
  @IBOutlet weak var loader: UIActivityIndicatorView!
  @IBOutlet weak var placeholder: UILabel!
  @IBOutlet weak var gainSpentSV: UIStackView!
  
  var inventoryItems = [(String, [InventoryItem])]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    let fetchRequest = NSFetchRequest<InventoryItem>(entityName: "InventoryItem")
//
//    if let result = try? CoreDataService.context.fetch(fetchRequest) {
//      for object in result {
//        CoreDataService.context.delete(object)
//      }
//    }
    
    sumGain.adjustsFontSizeToFitWidth = true
    sumGain.minimumScaleFactor = 0.5
    sumSpent.adjustsFontSizeToFitWidth = true
    sumSpent.minimumScaleFactor = 0.5
    
    inventoryTable.delegate = self
    inventoryTable.dataSource = self
    
    navigationItem.leftBarButtonItem = editButtonItem
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadInventoryTable), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    
    reloadInventoryTable()
  }
    
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    reloadInventoryTable()
    reloadPlaceholder()
  }
  
  func reloadPlaceholder() {
    if inventoryItems.count > 0 {
      inventoryTable.isHidden = false
      gainSpentSV.isHidden = false
      placeholder.isHidden = true
    } else {
      inventoryTable.isHidden = true
      gainSpentSV.isHidden = true
      placeholder.isHidden = false
    }
  }
  
  func getInventoryItem(indexPath: IndexPath) -> InventoryItem {
    let inventoryItemsTuple: (String, [InventoryItem]) = self.inventoryItems[indexPath.section]
    let inventoryItems = inventoryItemsTuple.1
    return inventoryItems[indexPath.row]
  }
  
  @objc func reloadInventoryTable() {
    inventoryItems = InventoryService.instance.fetchInventoryItemsByExchange()
    inventoryTable.reloadData()
    recalculateSums()
  }
  
  @IBAction func addButtonPressed(_ sender: Any) {
    if InventoryService.instance.getNumberOfInventoryItems() < 3 || PurchaseService.instance.isPro {
      performSegue(withIdentifier: "toAddInventoryItemVC", sender: nil)
    } else {
      let purchaseVC = PurchaseVC(nibName: "PurchaseVC", bundle: nil)
      present(purchaseVC, animated: true, completion: nil)
    }
  }
  
  func recalculateSums() {
    var sumSpentByCurrency = [String: Double]()
    var sumGainByCurrency = [String: Double]()
    
    let allInventoryItems = inventoryItems.reduce([]) { acc, curr in acc + curr.1 }
    allInventoryItems.forEach { item in
      if let currency = item.currency {
        sumSpentByCurrency[currency] = (sumSpentByCurrency[currency] ?? 0) + item.spent
      }
    }
    sumSpent.numberOfLines = sumSpentByCurrency.count
    sumSpent.text = sumSpentByCurrency.keys.map { code in return sumSpentByCurrency[code]?.formatAsCurrency(code: code) ?? "" }.joined(separator: "\n")
    
    sumGain.isHidden = true
    loader.isHidden = true
    loader.stopAnimating()
    
    let totalLength = allInventoryItems.count
    if totalLength > 0 {
      loader.isHidden = false
      loader.startAnimating()
      
      var counter = 0
      allInventoryItems.forEach { item in
        if let exchangeId = item.exchangeId, let symbol = item.symbol, let currency = item.currency {
          StockService.instance.getTicker(cryptocurrencySymbol: symbol, exchangeId: exchangeId, currencySymbol: currency, completion: { value in
            guard !value.isFetching else { return }
            
            if let price = value.price {
              sumGainByCurrency[currency] = (sumGainByCurrency[currency] ?? 0) + item.quantity * (price - item.cost)
            }
            counter += 1
            if counter >= totalLength {
              self.loader.isHidden = true
              self.loader.stopAnimating()
              self.sumGain.isHidden = false
              self.sumGain.numberOfLines = sumGainByCurrency.count
              self.sumGain.text = sumGainByCurrency.keys
                .map { code in
                  if let spent = sumSpentByCurrency[code], let gain = sumGainByCurrency[code]{
                    return (spent + gain).formatAsCurrency(code: code)
                  }
                  return "NA"
                }
                .joined(separator: "\n")
            }
          })
        }
      }
    }
  }
  
  override func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    inventoryTable.setEditing(editing, animated: true)
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return inventoryItems.count
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return inventoryItems[section].0
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return inventoryItems[section].1.count
  }
  
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    let header = view as? UITableViewHeaderFooterView
    header?.textLabel?.textColor = .lightGray
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: "inventoryItem") as? InventoryItemCell {
      cell.setupView(inventoryItem: getInventoryItem(indexPath: indexPath))
      return cell
    }
    return UITableViewCell()
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      InventoryService.instance.remove(inventoryItem: getInventoryItem(indexPath: indexPath), completion: {
        self.inventoryItems[indexPath.section].1.remove(at: indexPath.row)
        if self.inventoryItems[indexPath.section].1.count == 0 {
          self.inventoryItems.remove(at: indexPath.section)
          tableView.deleteSections([indexPath.section], with: .fade)
        } else {
          tableView.deleteRows(at: [indexPath], with: .fade)
        }
        self.recalculateSums()
        self.reloadPlaceholder()
      })
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let inventoryItem = getInventoryItem(indexPath: indexPath)
    performSegue(withIdentifier: "toAddInventoryItemVC", sender: inventoryItem)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "toAddInventoryItemVC", let destination = segue.destination as? AddInventoryItemVC, let inventoryItem = sender as? InventoryItem {
      destination.inventoryItem = inventoryItem
    }
  }
  
}
