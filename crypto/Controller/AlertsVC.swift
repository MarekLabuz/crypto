//
//  AlertsVC.swift
//  crypto
//
//  Created by Marek Łabuz on 07/01/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import UIKit
import CoreData

class AlertsVC: UIViewController {
  
  @IBOutlet weak var alertsTable: UITableView!
  @IBOutlet weak var placeholder: UILabel!
  
  var alerts = [(String, [NotificationItem])]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    alertsTable.delegate = self
    alertsTable.dataSource = self
    
    navigationItem.leftBarButtonItem = editButtonItem
    
//    let fetchRequest = NSFetchRequest<NotificationItem>(entityName: "NotificationItem")
//
//    if let result = try? CoreDataService.context.fetch(fetchRequest) {
//      for object in result {
//        CoreDataService.context.delete(object)
//      }
//    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadAlertsTable), name: NSNotification.Name(rawValue: UPDATE_ALERTS_LIST), object: nil)
    reloadAlertsTable()
  }
  
  func displayError(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "I understand", style: .default, handler: nil))
    present(alert, animated: true, completion: nil)
  }
  
  @objc func reloadAlertsTable() {
    alerts = NotificationsService.instance.fetchNotifictionsByExchange()
    alertsTable.reloadData()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    reloadAlertsTable()
    reloadPlaceholder()
  }
  
  func reloadPlaceholder() {
    if alerts.count > 0 {
      alertsTable.isHidden = false
      placeholder.isHidden = true
    } else {
      alertsTable.isHidden = true
      placeholder.isHidden = false
    }
  }
  
  override func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    alertsTable.setEditing(editing, animated: true)
  }
  
  @IBAction func addButtonPressed(_ sender: Any) {
    if NotificationsService.instance.getNumberOfNotifications() < 3 || PurchaseService.instance.isPro {
      performSegue(withIdentifier: "toAddAlertVC", sender: nil)
    } else {
      let purchaseVC = PurchaseVC(nibName: "PurchaseVC", bundle: nil)
      present(purchaseVC, animated: true, completion: nil)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "toAddAlertVC", let destination = segue.destination as? AddAlertVC, let alert = sender as? NotificationItem {
      destination.alert = alert
    }
  }
}

extension AlertsVC: UITableViewDelegate, UITableViewDataSource {
  func getAlert(indexPath: IndexPath) -> NotificationItem {
    let alertsTuple: (String, [NotificationItem]) = self.alerts[indexPath.section]
    let alerts = alertsTuple.1
    return alerts[indexPath.row]
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return alerts.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return alerts[section].1.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: "alertCell") as? AlertCell {
      cell.setupView(notification: getAlert(indexPath: indexPath))
      return cell
    }
    return UITableViewCell()
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return alerts[section].0
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
      NotificationsService.instance.remove(notification: getAlert(indexPath: indexPath), completion: { success in
        if success {
          self.alerts[indexPath.section].1.remove(at: indexPath.row)
          if self.alerts[indexPath.section].1.count == 0 {
            self.alerts.remove(at: indexPath.section)
            tableView.deleteSections([indexPath.section], with: .fade)
          } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
          }
        } else {
          self.displayError(title: "Alert server error", message: "Alert could not be deleted. Please try again later.")
        }
        self.reloadPlaceholder()
      })
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let alert = alerts[indexPath.section].1[indexPath.row]
    performSegue(withIdentifier: "toAddAlertVC", sender: alert)
  }
  
}
