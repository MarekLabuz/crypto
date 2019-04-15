//
//  AddAlertVC.swift
//  crypto
//
//  Created by Marek Łabuz on 07/01/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import UIKit
import UserNotifications

class AddAlertVC: UIViewController {
  
  @IBOutlet weak var cryptocurrencyStackView: UIStackView!
  
  @IBOutlet weak var cryptocurrencyLabel: UILabel!
  @IBOutlet weak var exchangeLabel: UILabel!
  @IBOutlet weak var datePicker: UIDatePicker!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var price: UITextField!
  @IBOutlet weak var addButton: Button!
  @IBOutlet weak var typeControl: UISegmentedControl!
  @IBOutlet weak var loader: UIActivityIndicatorView!
  @IBOutlet weak var currentPriceSV: UIStackView!
  @IBOutlet weak var currentPrice: UILabel!
  @IBOutlet weak var currentPriceLoader: UIActivityIndicatorView!
  
  var selectedCryptocurrency: CryptocurrencySimple?
  var selectedExchange: Exchange?
  var selectedCurrency: String?
  var timeVisible = true {
    didSet {
      datePicker.isHidden = !timeVisible
      price.isHidden = timeVisible
    }
  }
  
  var alertType = 0
  var alert: NotificationItem?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addButton.setTitle(alert != nil ? "SAVE" : "ADD", for: .normal)
    
    datePicker.setValue(TEXT_COLOR, forKey: "textColor")
    
    datePicker.isHidden = false
    price.isHidden = true
    price.attributedPlaceholder = NSAttributedString(string: "Enter price", attributes: [.foregroundColor: UIColor.lightGray])
    
    cryptocurrencyStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cryptocurrencyStackViewPressed)))
    
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AddInventoryItemVC.hideKeyboard)))
    
    setupViewForUpdate()
    
    datePicker.addTarget(self, action: #selector(datePickedValueChanged), for: .valueChanged)
  }
  
  func setupCurrentPrice () {
    currentPriceSV.isHidden = true
    if let symbol = selectedCryptocurrency?.symbol, let exchangeId = selectedExchange?.id, let currencySymbol = selectedCurrency {
      currentPriceLoader.startAnimating()
      currentPriceLoader.isHidden = false
      StockService.instance.getTicker(cryptocurrencySymbol: symbol, exchangeId: exchangeId, currencySymbol: currencySymbol, completion: { v in
        self.currentPriceLoader.isHidden = true
        self.currentPriceLoader.stopAnimating()
        self.currentPrice.text = v.price?.formatAsCurrency(code: currencySymbol)
        self.currentPriceSV.isHidden = false
      })
    }
  }
  
  @objc func hideKeyboard() {
    view.endEditing(true)
  }
  
  func isLoading(on: Bool) {
    DispatchQueue.main.async {
      self.loader.isHidden = !on
      self.addButton.isHidden = on
    }
  }
  
  func displayError(title: String, message: String) {
    DispatchQueue.main.async {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "I understand", style: .default, handler: nil))
      self.present(alert, animated: true, completion: nil)
    }
  }
  
  @objc func datePickedValueChanged() {
    if (datePicker.datePickerMode == .countDownTimer && datePicker.countDownDuration < 600) {
      let calendar = Calendar(identifier: .gregorian)
      var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
      components.setValue(0, for: .hour)
      components.setValue(10, for: .minute)
      guard let date = calendar.date(from: components) else { return }
      datePicker.setDate(date, animated: true)
    }
  }
  
  func setupViewForUpdate() {
    guard alert != nil else { return }
    guard
      let type = NotificationType(rawValue: alert?.type ?? ""),
      let symbol = alert?.symbol,
      let name = alert?.name,
      let exchangeId = alert?.exchangeId,
      let exchangeName = alert?.exchangeName,
      let currency = alert?.currency,
      let value = alert?.value
    else { return }
    let cryptocurrency = CryptocurrencySimple(symbol: symbol, name: name, imageURL: "")
    let exchange = Exchange(id: exchangeId, name: exchangeName, country: "")
    didSelect(view: self, cryptocurrency: cryptocurrency, exchange: exchange, currency: currency, completion: {})
    switch type {
    case .timeGoal:
      typeControl.selectedSegmentIndex = 0
      typeChanged(typeControl)
      datePicker.setDate(Date(timeIntervalSince1970: value / 1000), animated: false)
      break
    case .timeInterval:
      typeControl.selectedSegmentIndex = 1
      typeChanged(typeControl)
      datePicker.countDownDuration = value / 1000
      break
    case .priceInterval:
      typeControl.selectedSegmentIndex = 2
      typeChanged(typeControl)
      price.text = value.formatDoubleLocale()
      break
    case .priceGoal:
      typeControl.selectedSegmentIndex = 3
      typeChanged(typeControl)
      price.text = value.formatDoubleLocale()
      break
    }
  }
  
  @IBAction func unwindToAddAlert(segue: UIStoryboardSegue) {}

  @objc func cryptocurrencyStackViewPressed() {
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
  
  @IBAction func dismissButtonPressed(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }
  
  func getType() -> NotificationType? {
    switch alertType {
    case 0:
      return .timeGoal
    case 1:
      return .timeInterval
    case 2:
      return .priceInterval
    case 3:
      return .priceGoal
    default:
      return nil
    }
  }
  
  func getValue() -> Double? {
    switch alertType {
    case 0:
      return floor(datePicker.date.timeIntervalSince1970 / 60) * 60000
    case 1:
      let countDownDuration = datePicker.countDownDuration < 600 ? 600 : datePicker.countDownDuration
      return Double(countDownDuration * 1000)
    case 2, 3:
      return price.doubleValue
    default:
      return nil
    }
  }
  
  @IBAction func addButtonPressed(_ sender: Any) {
    isLoading(on: true)
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
      DispatchQueue.main.async {
        if !granted {
          self.isLoading(on: false)
          self.displayError(title: "Alerts disabled", message: "Please enable notifications for Crypto Toolkit in the system settings.")
          return
        }
        if NotificationsService.instance.notificationsID == nil || NotificationsService.instance.deviceToken == nil {
          self.isLoading(on: false)
          NotificationsService.instance.requestNotifications()
          self.displayError(title: "Alerts synchronized", message: "Please try again now.")
          return
        }
        guard
          let cryptocurrencySimple = self.selectedCryptocurrency,
          let exchange = self.selectedExchange,
          let currency = self.selectedCurrency,
          let type = self.getType(),
          let value = self.getValue()
          else {
            self.isLoading(on: false)
            self.displayError(title: "Alert incomplete", message: "Please fill in all fields.")
            return
        }
        if NotificationsService.instance.exists(cryptocurrencySimple: cryptocurrencySimple, exchange: exchange, currency: currency, type: type, value: value) {
          self.isLoading(on: false)
          self.displayError(title: "Cannot add alert", message: "Such alert already exists.")
          return
        }
        if let alert = self.alert {
          let newNotification: [String: Any] = [
            "currency": currency,
            "symbol": cryptocurrencySimple.symbol,
            "name": cryptocurrencySimple.name,
            "exchangeId": exchange.id,
            "exchangeName": exchange.name,
            "type": type.rawValue,
            "value": value,
            "isOn": true
          ]
          NotificationsService.instance.replace(notification: alert, newNotification: newNotification, completion: { success in
            self.isLoading(on: false)
            if success {
              self.dismiss(animated: true, completion: nil)
            } else {
              self.displayError(title: "Server error", message: "Alert could not be saved. Please try again later.")
            }
          })
          return
        }
        NotificationsService.instance.add(cryptocurrencySimple: cryptocurrencySimple, exchange: exchange, currency: currency, type: type, value: value) { success in
          self.isLoading(on: false)
          if success {
            self.dismiss(animated: true, completion: nil)
          } else {
            self.displayError(title: "Server error", message: "Alert could not be added. Please try again later.")
          }
        }
      }
    }
  }
  
  @IBAction func typeChanged(_ sender: UISegmentedControl) {
    view.endEditing(true)
    alertType = sender.selectedSegmentIndex
    timeVisible = alertType == 0 || alertType == 1
    if let type = getType() {
      descriptionLabel.text = NotificationsService.instance.getTypeDescription(type: type)
      switch alertType {
      case 0:
        datePicker.datePickerMode = .time
      case 1:
        datePicker.datePickerMode = .countDownTimer
        datePicker.countDownDuration = 600
      default:
        return
      }
    }
  }
}

extension AddAlertVC: SearchViewDelegate {
  func didSelect(view: UIViewController, cryptocurrency: CryptocurrencySimple, exchange: Exchange, currency: String, completion: @escaping () -> ()) {
    selectedCryptocurrency = cryptocurrency
    selectedExchange = exchange
    selectedCurrency = currency
    cryptocurrencyLabel.text = cryptocurrency.name
    cryptocurrencyLabel.textColor = TEXT_COLOR
    exchangeLabel.text = "\(exchange.name) [\(currency)]"
    exchangeLabel.textColor = TEXT_COLOR
    exchangeLabel.isHidden = false
    setupCurrentPrice()
    completion()
  }
  
  func unwindSegueIdentifier() -> String? {
    return "unwindToAddAlert"
  }
  
}
