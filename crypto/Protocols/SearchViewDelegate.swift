//
//  SearchViewDelegate.swift
//  crypto
//
//  Created by Marek Łabuz on 15/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

protocol SearchViewDelegate {
  func didSelect(view: UIViewController, cryptocurrency: CryptocurrencySimple, exchange: Exchange, currency: String, completion: @escaping () -> ())
  func unwindSegueIdentifier() -> String?
}
