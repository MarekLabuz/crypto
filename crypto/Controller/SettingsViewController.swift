//
//  SettingsViewController.swift
//  crypto
//
//  Created by Marek Łabuz on 16/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class SettingsStockCurrenciesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var stockCurrencies: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    stockCurrencies.delegate = self
    stockCurrencies.dataSource = self
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return SettingsService.instance.stockCurrencies.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.
  }
  
  
}
