//
//  SubscriptionViewController.swift
//  Shortwave
//
//  Created by Mobile World on 9/11/19.
//  Copyright © 2019 Mobile World. All rights reserved.
//

import UIKit
import StoreKit

class SubscriptionViewController: UIViewController {
    var products: [SKProduct] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Globals.products.count == 0 {
            SubscriptionProducts.store.requestProducts({ [weak self] success, products in
                guard let self = self else { return }
                if success {
                    self.products = products!
                    print("Products count: \(self.products.count)")
                }
            })
        }
        else {
            self.products = Globals.products
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification(_:)),
                                               name: .IAPHelperPurchaseNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRestorePurchaseNotification(_:)),
                                               name: .IAPHelperRestorePurchaseNotification,
                                               object: nil)
    }
    @IBAction func onContinue(_ sender: Any) {
        if Globals.isPro {
            let alert = UIAlertController(title: "Subscription", message: "You're currently subscribed to Ansable Subscription Service", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (UIAlertAction) in
            }))
            self.present(alert, animated: true);
        }
        else {
            self.onPurchaseSubscription()
        }
    }
    func onPurchaseSubscription(){
        guard
            let index = products.firstIndex(where: { product -> Bool in
                product.productIdentifier == SubscriptionProducts.subscriptionID
            })
            else { return }
        let alert = UIAlertController(title: "Subscription", message: "The subscription service (25 GB continuous memory  for 0.99$ USD/Month paid subscription and 5 GB continuous memory for free) is defined as data usage conducive with normal listening patterns and realistic listening duration's.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "$0.99 per month", style: .default, handler: { (UIAlertAction) in
            SubscriptionProducts.store.buyProduct(self.products[index])
        }))
        alert.addAction(UIAlertAction(title: "Restore Purchase", style: .default, handler: { (UIAlertAction) in
            SubscriptionProducts.store.restorePurchases()
        }))
        alert.addAction(UIAlertAction(title: "No, thanks", style: .default, handler: { (UIAlertAction) in
            //            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true);
    }
    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard
            let productID = notification.object as? String,
            let index = products.firstIndex(where: { product -> Bool in
                product.productIdentifier == productID
            })
            else { return }
        Globals.isPro = SubscriptionProducts.store.isProductPurchased(SubscriptionProducts.subscriptionID)
        if Globals.isPro {
            //TODO: Add here
            let alert = UIAlertController(title: "Subscription", message: "Subscribed Ansable Subscription Service successfully!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (UIAlertAction) in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true);
        }
    }
    @objc func handleRestorePurchaseNotification(_ notification: Notification) {
        guard
            let productID = notification.object as? String,
            let index = products.firstIndex(where: { product -> Bool in
                product.productIdentifier == productID
            })
            else { return }
        Globals.isPro = SubscriptionProducts.store.isProductPurchased(SubscriptionProducts.subscriptionID)
        if Globals.isPro {
            //TODO: add here
            let alert = UIAlertController(title: "Subscription", message: "Restored your purchase Successful!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (UIAlertAction) in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true);
        }
        else {
            let alert = UIAlertController(title: "Subscription", message: "Restored your purchase Successful but could not find the record you purchased before ", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (UIAlertAction) in
                //                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true);
        }
    }
    @IBAction func onTermsandPrivacyPolicy(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "privacy")
        present(vc!, animated: true, completion: nil)
    }
}

