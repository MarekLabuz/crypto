//
//  PurchaseService.swift
//  crypto
//
//  Created by Marek Łabuz on 10/02/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import Foundation
import StoreKit
import Alamofire
import SwiftyJSON

typealias CompletionHandler = (Bool) -> ()

class PurchaseService: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {

  static let instance = PurchaseService()
  let defaults = UserDefaults.standard
  
  let IAP_PRO = "com.marek.labuz.crypto.pro"
  var isPro: Bool {
    get {
//      return true
      return defaults.bool(forKey: IAP_PRO)
    }
    set {
      defaults.set(newValue, forKey: IAP_PRO)
    }
  }
  
  var productsRequest: SKProductsRequest!
  var products = [SKProduct]()
  var transactionComplete: CompletionHandler?
  
  func fetchProducts() {
    validateSubscription(completion: { success in
      print("Pro mode: \(self.isPro)")
      self.isPro = success
      if success {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: UPDATE_TAB_BAR), object: nil)
      }
    })
    let productIds = NSSet(object: IAP_PRO) as! Set<String>
    productsRequest = SKProductsRequest(productIdentifiers: productIds)
    productsRequest.delegate = self
    productsRequest.start()
  }
  
  func purchasePro(completion: @escaping CompletionHandler) {
    if SKPaymentQueue.canMakePayments() && products.count > 0 {
      transactionComplete = completion
      let proProduct = products[0]
      let payment = SKPayment(product: proProduct)
      SKPaymentQueue.default().add(self)
      SKPaymentQueue.default().add(payment)
    } else {
      completion(false)
    }
  }
  
  func restorePurchases(completion: @escaping CompletionHandler) {
    if SKPaymentQueue.canMakePayments() {
      transactionComplete = completion
      SKPaymentQueue.default().add(self)
      SKPaymentQueue.default().restoreCompletedTransactions()
    } else {
      completion(false)
    }
  }
  
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    if response.products.count > 0 {
      products = response.products
    }
  }
  
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        SKPaymentQueue.default().finishTransaction(transaction)
        if transaction.payment.productIdentifier == IAP_PRO {
          isPro = true
          transactionComplete?(true)
        }
        break
      case .failed:
        SKPaymentQueue.default().finishTransaction(transaction)
        transactionComplete?(false)
        break
      case .restored:
        SKPaymentQueue.default().finishTransaction(transaction)
        if transaction.payment.productIdentifier == IAP_PRO {
          isPro = true
          transactionComplete?(true)
        }
        break
      default:
        break
      }
    }
  }
  
  func validateSubscription(completion: @escaping CompletionHandler) {
    guard
      let receiptURL = Bundle.main.appStoreReceiptURL,
      let receipt = NSData(contentsOf: receiptURL)
    else {
      completion(false)
      return
    }
    
    let requestContents: [String: Any] = ["receipt-data": receipt.base64EncodedString(options: []), "password": "19db55e2f8d44a7a8efe1df2cd82cb08"]
    let appleServer = receiptURL.lastPathComponent == "sandboxReceipt" ? "sandbox" : "buy"
    let stringURL = "https://\(appleServer).itunes.apple.com/verifyReceipt"
    
    Alamofire.request(stringURL, method: .post, parameters: requestContents, encoding: JSONEncoding.default).responseJSON { response in
      let now = NSDate().timeIntervalSince1970
      if
        let value = response.result.value as? NSDictionary,
        let status = value.value(forKey: "status") as? Int,
        let purchases = value.value(forKey: "latest_receipt_info") as? NSArray
      {
        let result = status == 0 && purchases.contains { v in
          if let string = (v as? NSObject)?.value(forKey: "expires_date_ms") as? String {
            return ((Double(string) ?? 0) / 1000) > now
          }
          return false
        }
        completion(result)
      } else {
        completion(false)
        print("Error: \(response.result)")
      }
    }
  }
  
}
