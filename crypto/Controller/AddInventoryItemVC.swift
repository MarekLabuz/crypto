//
//  AddInventoryItemVC.swift
//  crypto
//
//  Created by Marek Łabuz on 08/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

class AddInventoryItemVC: UIViewController {
  
  @IBOutlet weak var addButton: Button!
  @IBOutlet weak var cryptocurrencyStackView: UIStackView!
  @IBOutlet weak var cryptocurrencyLabel: UILabel!
  @IBOutlet weak var exchangeLabel: UILabel!
  @IBOutlet weak var quantity: UITextField!
  @IBOutlet weak var cost: UITextField!
  @IBOutlet weak var moneySpent: UITextField!
  @IBOutlet weak var currencySymbolUp: UILabel!
  @IBOutlet weak var currencySymbolDown: UILabel!
  var textFieldsArray = [UITextField]()
  var selectedCryptocurrency: CryptocurrencySimple?
  var selectedExchange: Exchange?
  var selectedCurrency: String?
  
  var inventoryItem: InventoryItem?
  
  @IBAction func unwindToAddInventoryItem(segue: UIStoryboardSegue) {}
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addButton.setTitle(inventoryItem != nil ? "SAVE" : "ADD", for: .normal)
    
    textFieldsArray = [quantity, cost, moneySpent]
    quantity.attributedPlaceholder = NSAttributedString(string: "Enter quantity", attributes:[.foregroundColor: UIColor.lightGray])
    cost.attributedPlaceholder = NSAttributedString(string: "Enter cost", attributes:[.foregroundColor: UIColor.lightGray])
    moneySpent.attributedPlaceholder = NSAttributedString(string: "Enter money spent", attributes:[.foregroundColor: UIColor.lightGray])

    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AddInventoryItemVC.hideKeyboard)))
    
    cryptocurrencyStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AddInventoryItemVC.cryptoPickerPressed)))
    setupViewForUpdate()
  }
  
  func setupViewForUpdate() {
    guard inventoryItem != nil else { return }
    guard
      let quantity = inventoryItem?.quantity,
      let cost = inventoryItem?.cost,
      let moneySpent = inventoryItem?.spent,
      let symbol = inventoryItem?.symbol,
      let name = inventoryItem?.name,
      let exchangeId = inventoryItem?.exchangeId,
      let exchangeName = inventoryItem?.exchangeName,
      let currency = inventoryItem?.currency
    else { return }
    let cryptocurrency = CryptocurrencySimple(symbol: symbol, name: name, imageURL: "")
    let exchange = Exchange(id: exchangeId, name: exchangeName, country: "")
    didSelect(view: self, cryptocurrency: cryptocurrency, exchange: exchange, currency: currency, completion: {})
    self.quantity.text = quantity.formatDoubleLocale()
    self.cost.text = cost.formatDoubleLocale()
    self.moneySpent.text = moneySpent.formatDoubleLocale()
  }
  
  @IBAction func addInvetoryItem() {
    guard selectedCryptocurrency != nil && selectedExchange != nil && selectedCurrency != nil && !textFieldsArray.contains(where: { field in
      field.doubleValue == nil
    }) else { return }
    
    InventoryService.instance.addOrReplace(inventoryItem: inventoryItem, cryptocurrencySimple: selectedCryptocurrency!, exchange: selectedExchange!, currency: selectedCurrency!, quantity: quantity.doubleValue!, cost: cost.doubleValue!, spent: moneySpent.doubleValue!, completion: {
      self.dismiss(animated: true, completion: nil)
    })
  }
  
  @objc func hideKeyboard() {
    view.endEditing(true)
  }
  
  @objc func cryptoPickerPressed() {
    performSegue(withIdentifier: "toSearchVC", sender: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    case "toSearchVC":
      if let destination = segue.destination as? SearchVC {
        destination.delegate = self
        destination.type = .Cryptocurrencies
      }
    default:
      break
    }
  }
  
  @IBAction func closeBtnPressed(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func editingChanged(_ sender: UITextField) {
    if let index = textFieldsArray.index(of: sender) {
      textFieldsArray.remove(at: index)
      textFieldsArray.append(sender)
    }
    
    let otherTextFields = textFieldsArray.filter { $0 !== sender }
    let index = otherTextFields.index(where: { textField in textField.text == "" }) ?? 0
    let textFieldToEdit = otherTextFields[index]
    
    switch textFieldToEdit {
    case quantity:
      if let value = cost.doubleValue, let money = moneySpent.doubleValue {
        textFieldToEdit.text = (value == 0 ? 0 : money / value).formatDoubleLocale()
      } else {
        textFieldToEdit.text = ""
      }
    case cost:
      if let value = quantity.doubleValue, let money = moneySpent.doubleValue {
        textFieldToEdit.text = (value == 0 ? 0 : money / value).formatDoubleLocale()
      } else {
        textFieldToEdit.text = ""
      }
    case moneySpent:
      if let quantiy = quantity.doubleValue, let value = cost.doubleValue {
        textFieldToEdit.text = (quantiy * value).formatDoubleLocale()
      } else {
        textFieldToEdit.text = ""
      }
    default:
      break
    }
  }
}

extension AddInventoryItemVC: SearchViewDelegate {
  func didSelect(view: UIViewController, cryptocurrency: CryptocurrencySimple, exchange: Exchange, currency: String, completion: @escaping () -> ()) {
    selectedCryptocurrency = cryptocurrency
    selectedExchange = exchange
    selectedCurrency = currency
    cryptocurrencyLabel.text = selectedCryptocurrency?.name
    cryptocurrencyLabel.textColor = TEXT_COLOR
    exchangeLabel.isHidden = false
    exchangeLabel.text = selectedExchange?.name
    currencySymbolUp.isHidden = false
    currencySymbolUp.text = currency
    currencySymbolDown.isHidden = false
    currencySymbolDown.text = currency
    completion()
  }
  
  func unwindSegueIdentifier() -> String? {
    return "unwindToAddInventoryItem"
  }
}
