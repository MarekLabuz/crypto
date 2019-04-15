//
//  AboutVC.swift
//  crypto
//
//  Created by Marek Łabuz on 11/02/2018.
//  Copyright © 2018 Marek Łabuz. All rights reserved.
//

import UIKit
import AcknowList

class AboutVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var infoTable: UITableView!
  let path = Bundle.main.path(forResource: "Pods-crypto-acknowledgements", ofType: "plist")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    infoTable.delegate = self
    infoTable.dataSource = self
  }
  
  @IBAction func linkPressed(_ sender: Any) {
    let privacyAndTerms = PrivacyAndTermsVC(nibName: "PrivacyAndTermsVC", bundle: nil)
    present(privacyAndTerms, animated: true, completion: nil)
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    switch indexPath.row {
    case 0:
      let viewController = AcknowListViewController(acknowledgementsPlistPath: path)
      viewController.view.backgroundColor = #colorLiteral(red: 0.9803921569, green: 0.9725490196, blue: 0.9725490196, alpha: 1)
      if let navigationController = self.navigationController {
        navigationController.pushViewController(viewController, animated: true)
      }
      break
    case 1:
      performSegue(withIdentifier: "toLogosLicenceTable", sender: nil)
      break
    default:
      break
    }
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0.1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    switch indexPath.row {
    case 0:
      cell.textLabel?.text = "Acknowledgements"
      break
    case 1:
      cell.textLabel?.text = "Logos licences"
      break
    default:
      break
    }
    cell.accessoryType = .disclosureIndicator
    return cell
  }
  
}
