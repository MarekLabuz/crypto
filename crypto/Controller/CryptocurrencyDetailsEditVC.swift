//
//  CryptocurrencyDetailsEditVC.swift
//  crypto
//
//  Created by Marek Łabuz on 31/12/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class CryptocurrencyDetailsEditVC: UIViewController {
  
  @IBOutlet weak var settingsTable: UITableView!
  
  var cryptocurrency: Cryptocurrency!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    settingsTable.delegate = self
    settingsTable.dataSource = self
    
    settingsTable.isEditing = true
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    settingsTable.reloadData()
  }
  
  @IBAction func dismissButtonClicked(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func addCurrencyButtonClicked(_ sender: Any) {
    guard let searchVC = UIStoryboard(name: "Main", bundle: nil)
      .instantiateViewController(withIdentifier: "SearchVC") as? SearchVC else { return }
    searchVC.delegate = self
    searchVC.type = .Currencies
    searchVC.selectedCryptocurrency = CryptocurrencySimple(symbol: cryptocurrency.symbol!, name: cryptocurrency.name!, imageURL: "")
    searchVC.selectedExchange = Exchange(id: cryptocurrency.exchangeId!, name: cryptocurrency.exchangeName!, country: "")
    present(searchVC, animated: true, completion: nil)
  }
}

extension CryptocurrencyDetailsEditVC: UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return cryptocurrency.candlestickChart ? 2 : 3
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 0:
      return (cryptocurrency.values?.count ?? 0) + 1
    case 1:
      return 1
    default:
      return 4
    }
  }
  
  func getSwitchLabel(index: Int) -> String {
    switch index {
    case 0:
      return "High"
    case 1:
      return "Low"
    case 2:
      return "Open"
    default:
      return "Close"
    }
  }
  
  func getSwitchCallback(index: Int) -> (Bool) -> () {
    switch index {
    case 0:
      return { v in StockService.instance.setChartDisplay(cryptocurrency: self.cryptocurrency, key: "high", value: v) }
    case 1:
      return { v in StockService.instance.setChartDisplay(cryptocurrency: self.cryptocurrency, key: "low", value: v) }
    case 2:
      return { v in StockService.instance.setChartDisplay(cryptocurrency: self.cryptocurrency, key: "open", value: v) }
    default:
      return { v in StockService.instance.setChartDisplay(cryptocurrency: self.cryptocurrency, key: "close", value: v) }
    }
  }
  
  func getSwitchDefaultValue(index: Int) -> Bool {
    switch index {
    case 0:
      return cryptocurrency.high
    case 1:
      return cryptocurrency.low
    case 2:
      return cryptocurrency.open
    default:
      return cryptocurrency.close
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.section {
    case 0:
      if indexPath.row == (cryptocurrency.values?.count ?? 0), let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell") as? ButtonTVC {
        cell.setupView(titleLabel: "Add currency", onClick: { _ in })
        return cell
      } else if let cell = tableView.dequeueReusableCell(withIdentifier: "keyValueCell") as? KeyValueCell, let currency = cryptocurrency.values?[indexPath.row] as? String {
        cell.setupView(key: currency, value: "")
        return cell
      }
    case 1:
      if let cell = tableView.dequeueReusableCell(withIdentifier: "segmentControlCell") as? SegmentControlCell {
        cell.setupView(index: cryptocurrency.candlestickChart ? 1 : 0, handler: { index in
          StockService.instance.setTypeOfChart(cryptocurrency: self.cryptocurrency, index: index)
          if self.cryptocurrency.candlestickChart && index == 1 {
            tableView.deleteSections([2], with: .fade)
          } else {
            tableView.insertSections([2], with: .fade)
          }
        })
        return cell
      }
    default:
      if let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell") as? SwitchCell {
        cell.setupView(label: getSwitchLabel(index: indexPath.row), toggleOn: getSwitchDefaultValue(index: indexPath.row), onSwitch: getSwitchCallback(index: indexPath.row))
        return cell
      }
    }
    
    return UITableViewCell()
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0:
      return "Currencies"
    case 1:
      return ""
    default:
      return "History chart lines"
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    if let header = view as? UITableViewHeaderFooterView {
      header.textLabel?.textColor = UIColor.lightGray
    }
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return indexPath.section == 0 && indexPath.row != (cryptocurrency.values?.count ?? 0) && (cryptocurrency.values?.count ?? 0) > 1
  }
  
  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return indexPath.section == 0
  }
  
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    StockService.instance.swapValues(cryptocurrency: cryptocurrency, from: sourceIndexPath.row, to: destinationIndexPath.row)
  }
  
  func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
    let addButtonIndex = (cryptocurrency.values?.count ?? 0)
    if (sourceIndexPath.section != proposedDestinationIndexPath.section || sourceIndexPath.row == addButtonIndex || proposedDestinationIndexPath.row == addButtonIndex) {
      return sourceIndexPath
    }
    return proposedDestinationIndexPath
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      StockService.instance.removeValue(cryptocurrency: cryptocurrency, index: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
    }
  }
}

extension CryptocurrencyDetailsEditVC: SearchViewDelegate {
  @IBAction func unwindToDetailsEdit(segue: UIStoryboardSegue) {}
  
  func didSelect(view: UIViewController, cryptocurrency: CryptocurrencySimple, exchange: Exchange, currency: String, completion: @escaping () -> ()) {
    if !StockService.instance.exists(view: view, cryptocurrency: cryptocurrency, exchange: exchange, currency: currency) {
      StockService.instance.addValue(cryptocurrency: self.cryptocurrency, currency: currency, completion: {
        completion()
      })
    }
  }
  
  func unwindSegueIdentifier() -> String? {
    return "unwindToDetailsEdit"
  }
}
