//
//  CurrencyPageVC.swift
//  crypto
//
//  Created by Marek Łabuz on 14/11/2017.
//  Copyright © 2017 Marek Łabuz. All rights reserved.
//

import UIKit

func createViewController (cryptocurrency: Cryptocurrency, currencySymbol: String) -> UIViewController {
  let uiViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CurrencyValueVC")
  
  if let currencyValueVC = uiViewController as? CurrencyValueVC {
    currencyValueVC.cryptocurrency = cryptocurrency
    currencyValueVC.currencySymbol = currencySymbol
    return currencyValueVC
  } else {
    return uiViewController
  }
}

class CurrencyPageVC: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
  
  var valuesViewControllers = [UIViewController]()
  var pageControl: UIPageControl!
  
  var cryptocurrency: Cryptocurrency!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    delegate = self
    dataSource = self

    pageControl.currentPage = 0
    pageControl.alpha = 0.5
    pageControl.tintColor = UIColor.black
    pageControl.backgroundColor = UIColor.clear
    pageControl.pageIndicatorTintColor = UIColor.gray
    pageControl.currentPageIndicatorTintColor = SPECIAL
  }
  
  @IBAction func unwindToCurrencyPage(segue: UIStoryboardSegue) {}
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    fetchViews()
    
    pageControl.numberOfPages = valuesViewControllers.count
    pageControl.reloadInputViews()
  }
  
  func fetchViews() {
    guard let values = cryptocurrency.values as? [String] else { return }
    valuesViewControllers = values.map { currencySymbol in
      return createViewController(cryptocurrency: cryptocurrency, currencySymbol: currencySymbol)
    }
    
    let addVC = AddCryptocurrencyValueVC(nibName: "AddCryptocurrencyValueVC", bundle: nil)
    addVC.cryptocurrency = cryptocurrency
    valuesViewControllers.append(addVC)
    
    let isCurrentPageWithinRange = valuesViewControllers.count > pageControl.currentPage
    if let currentPage = isCurrentPageWithinRange ? valuesViewControllers[pageControl.currentPage] : valuesViewControllers.first {
      setViewControllers([currentPage], direction: .forward, animated: false, completion: nil)
      if !isCurrentPageWithinRange {
        pageControl.currentPage = 0
      }
    }
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    let pageContentViewController = pageViewController.viewControllers![0]
    self.pageControl.currentPage = valuesViewControllers.index(of: pageContentViewController)!
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let viewControllerIndex = valuesViewControllers.index(of: viewController) else { return nil }
    
    let previousIndex = viewControllerIndex - 1
    
    guard previousIndex >= 0 else { return nil }
    guard valuesViewControllers.count > previousIndex else { return nil }
    
    return valuesViewControllers[previousIndex]
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let viewControllerIndex = valuesViewControllers.index(of: viewController) else { return nil }
    
    let nextIndex = viewControllerIndex + 1
    let orderedViewControllersCount = valuesViewControllers.count
    
    guard orderedViewControllersCount != nextIndex else { return nil }
    guard orderedViewControllersCount > nextIndex else { return nil }
    
    return valuesViewControllers[nextIndex]
  }
}
