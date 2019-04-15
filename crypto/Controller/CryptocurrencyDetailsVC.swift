//
//  CryptocurrencyDetailsVC.swift
//  crypto
//
//  Created by Marek Łabuz on 05/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class CryptocurrencyDetailsVC: UIViewController {
  
  @IBOutlet weak var currencyPageControl: UIPageControl!
  @IBOutlet weak var currencyView: UIView!
  @IBOutlet weak var historyView: UIView!
  var cryptocurrency: Cryptocurrency!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.title = "\(cryptocurrency.name ?? "NA") / \(cryptocurrency.exchangeName ?? "NA")"
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonClicked))
  }
  
  @objc func editButtonClicked() {
    performSegue(withIdentifier: "toCryptocurrencyDetailsEditVC", sender: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let embeddedVC = segue.destination as? CurrencyPageVC {
      embeddedVC.cryptocurrency = cryptocurrency
      embeddedVC.pageControl = currencyPageControl
    }
    if let embeddedVC = segue.destination as? HistoryPageItemVC {
      embeddedVC.cryptocurrency = cryptocurrency
      embeddedVC.aggregation = .h24
    }
    if let destination = segue.destination as? CryptocurrencyDetailsEditVC {
      destination.cryptocurrency = cryptocurrency
    }
  }
}
