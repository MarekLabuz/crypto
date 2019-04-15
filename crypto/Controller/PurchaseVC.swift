//
//  PurchaseVC.swift
//  crypto
//
//  Created by Marek Łabuz on 10/02/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import UIKit

class PurchaseVC: UIViewController {
  
  @IBOutlet weak var proButton: UIButton!
  @IBOutlet weak var loader: UIActivityIndicatorView!
  @IBOutlet weak var restoreButton: UIButton!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var buttonContainer: UIStackView!
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var dismissButton: UIButton!
  @IBOutlet weak var dismissImage: UIImageView!
  
  var clickedFromTab = false
  var onSuccess: (() -> Void)?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if clickedFromTab {
      textLabel.text = "Subscribe to Pro and unlock an unlimited number of items to add in Rates, Inventory and Alerts."
      dismissImage.isHidden = true
      dismissButton.isHidden = true
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.setLoading(on: false)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if PurchaseService.instance.products.count > 0 {
      let price = PurchaseService.instance.products[0].localizedPrice()
      priceLabel.text = "\(price) for 1 month"
    }
  }
  
  @IBAction func buyProPressed(_ sender: Any) {
    setLoading(on: true)
    PurchaseService.instance.purchasePro { success in
      self.setLoading(on: false)
      if success {
        if let onSuccess = self.onSuccess {
          onSuccess()
        } else {
          self.dismiss(animated: true, completion: nil)
        }
      }
    }
  }
  
  @IBAction func restoreButtonPressed(_ sender: Any) {
    setLoading(on: true)
    PurchaseService.instance.restorePurchases { success in
      self.setLoading(on: false)
      if success {
        if let onSuccess = self.onSuccess {
          onSuccess()
        } else {
          self.dismiss(animated: true, completion: nil)
        }
      }
    }
  }
  
  @IBAction func linkPressed(_ sender: Any) {
    let privacyAndTerms = PrivacyAndTermsVC(nibName: "PrivacyAndTermsVC", bundle: nil)
    present(privacyAndTerms, animated: true, completion: nil)
  }
  
  func setLoading(on: Bool) {
    loader.isHidden = !on
    buttonContainer.isHidden = on
  }
  
  @IBAction func dismissPressed(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }
}
