//
//  ViewTabBarController.swift
//  crypto
//
//  Created by Marek Łabuz on 01/03/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import UIKit

class ViewTabBarController: UITabBarController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(self, selector: #selector(removePurchaseVC), name: NSNotification.Name(rawValue: UPDATE_TAB_BAR), object: nil)
  }
  
  @objc func removePurchaseVC() {
    self.viewControllers = self.viewControllers?.filter { vc in return !(vc is PurchaseVC) }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    removePurchaseVC()
    if !PurchaseService.instance.isPro {
      let proVC = PurchaseVC(nibName: "PurchaseVC", bundle: nil)
      proVC.clickedFromTab = true
      proVC.onSuccess = {
        self.removePurchaseVC()
        self.selectedViewController = self.viewControllers?[0]
      }
      proVC.tabBarItem = UITabBarItem(title: "Pro", image: UIImage(named: "shopping_cart"), tag: 1)
      self.viewControllers?.insert(proVC, at: 3)
    }
  }
  
}
