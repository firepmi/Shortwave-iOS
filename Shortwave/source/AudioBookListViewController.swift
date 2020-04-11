//
//  AudioBookListViewController.swift
//  Shortwave
//
//  Created by Mobile World on 1/23/19.
//  Copyright © 2019 Mobile World. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import JGProgressHUD
import StoreKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Toast_Swift

class AudioBookListViewController: UIViewController {
    var bookArray:[JSON] = []
    @IBOutlet weak var collectionView: UICollectionView!
    var products: [SKProduct] = []
    var totalCount = 0
    var selectedArray:[Bool] = []
    @IBOutlet weak var loadMoreAnimtionView: UIView!
    @IBOutlet weak var collectionViewBottom: NSLayoutConstraint!
    var waiting = false
    var type = 0
    var downloadRequest:Request!
    let hud = JGProgressHUD(style: .extraLight)
    var ref: DatabaseReference!
    var isGenre = false
    var isLast = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let link = Globals.serverUrl + "audiobooks/search"
        print(link)
        self.collectionViewBottom.constant = 60
        self.loadMoreAnimtionView.isHidden = true
        refreshDatabySort(key: Globals.genreKey)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download Queue", style: .done, target: self, action: #selector(toDownloadQueue))
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
        
        if !Globals.isPro {
            Globals.isPro = SubscriptionProducts.store.isProductPurchased(SubscriptionProducts.subscriptionID)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification(_:)),
                                               name: .IAPHelperPurchaseNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRestorePurchaseNotification(_:)),
                                               name: .IAPHelperRestorePurchaseNotification,
                                               object: nil)
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
            let alert = UIAlertController(title: "Subscription", message: "Purchased Subscription Membership successfully!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (UIAlertAction) in
                //                self.dismiss(animated: true, completion: nil)
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
                //                self.dismiss(animated: true, completion: nil)
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
    func onPurchaseSubscription(){
        guard
            let index = products.firstIndex(where: { product -> Bool in
                product.productIdentifier == SubscriptionProducts.subscriptionID
            })
            else { return }
        let alert = UIAlertController(title: "Subscription", message: "It is the unlimited access for books on membership subscription", preferredStyle: .alert)
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
    @objc func sortByGenre(){
//        performSegue(withIdentifier: "toSort", sender: nil)
        navigationController?.popViewController(animated: true)
    }
    var genreKey = ""
    public func refreshDatabySort(key:String) {
        isGenre = true
        genreKey = key
        let alertIndicator = UIAlertController(title: "Please Wait...", message: "\n\n", preferredStyle: UIAlertController.Style.alert)
        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.center = CGPoint(x: 139.5, y: 75.5)
        activityView.startAnimating()
        alertIndicator.view.addSubview(activityView)
        if bookArray.count == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.present(alertIndicator, animated: true, completion: nil)
            })
        }
        var link = Globals.serverUrl + "genrelist/" +  key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        if totalCount > 0 {
            link = Globals.serverUrl + "genrelist/" + "\(totalCount)/" + key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        }
        print(link)
        
        let loginString = String(format: "%@:%@", Globals.username, Globals.password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
         
        Alamofire.request(link, method: .get, parameters: nil,encoding: JSONEncoding.default, headers: [
            "Authorization":"Basic \(base64LoginString)"]).responseJSON { response in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    alertIndicator.dismiss(animated: false, completion: nil)
                })
                
                UIView.animate(withDuration: 1) {
//                    self.collectionViewBottom.constant = 0
                    self.loadMoreAnimtionView.isHidden = true
                }
                self.waiting = false
                switch response.result {
                case .success(_):
                    if let result = response.result.value {
                        let json = JSON(result)
                        if json.arrayValue.count == 0 {
                            self.isLast = true
                        }
                        else {
                            for _ in 0 ..< json.arrayValue.count {
                                self.selectedArray.append(true)
                            }
                            self.bookArray.append(contentsOf: json.arrayValue)
                            self.totalCount = self.totalCount + json.arrayValue.count
                            
                            print(self.bookArray.count)
                            self.collectionView.reloadData()
                        }
                    }
                    else {
                        let alert = UIAlertController(title: "Loading Data", message: "Loading Data failure!", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (UIAlertAction) in

                        }))
                        self.present(alert, animated: true);
                    }                   

                case .failure(let error):
                    print(error.localizedDescription)
                }
        }
    }

    func alertDownloadDialog(index:Int){
        let alert = UIAlertController(title: "Download Book", message: "Book Details: \(bookArray[index]["title"].stringValue)\nFilesize: \(bookArray[index]["filesize"].stringValue)",
            preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Add to download queue", style: .default, handler: { (UIAlertAction) in
            let code = Globals.onAddBookToQueue(book: self.bookArray[index])
            switch code {
            case 0:
                print("added")
                Globals.autoSync()
            case 1:
                self.view.makeToast("You already downloaded this book")
            case 2:
                self.view.makeToast("Already in download queue")
            case 3:
                self.view.makeToast("10 more books unplayed! Listen them first")
            default:
                print("expection code: \(code)")
            }
        }))
        self.present(alert, animated: true)
    }
    
    var updatedWeek = 0
    var updatedId = 0
    var updatedAudioID = 0
    var updatedDate = ""
    var updatedSize = 0
    func onUpdateInfo(){
        if updatedWeek == 0 {
            return
        }
        let user = Auth.auth().currentUser
        self.ref.child("products").child((user?.uid)!).child("weekly")
            .child("week\(updatedWeek)").child("product")
            .child("audio\(updatedAudioID)").setValue(updatedId)
        self.ref.child("products").child((user?.uid)!).child("weekly")
            .child("week\(updatedWeek)").child("start_date")
            .setValue(updatedDate)
        self.ref.child("products").child((user?.uid)!).child("weekly")
            .child("week\(updatedWeek)").child("total_value")
            .setValue(updatedSize)
    }
    func onCheckAvailableCount(id:Int, index:Int) {
        let user = Auth.auth().currentUser
        ref.child("products").child((user?.uid)!).child("weekly")
            .observeSingleEvent(of: .value) { (snapshot) in
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                if snapshot.childrenCount == 0 {
                    //Create Initial Week
                    self.updatedWeek = 1
                    self.updatedId = id
                    self.updatedDate = dateFormatter.string(from: date)
                    self.updatedAudioID = 1
                    self.updatedSize = self.bookArray[index]["filesize"].intValue
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        self.alertDownloadDialog(index: index)
                    }
                }
                else {
                    var lastChild:DataSnapshot!
                    let week:UInt = snapshot.childrenCount
                    for child in snapshot.children {
                        lastChild = child as? DataSnapshot
                    }
                    var startDate = Date()
                    var lastValue:UInt = 0
                    var totalValue = 0
                    for case let snap as DataSnapshot in lastChild.children {
                        if snap.key == "start_date" {
                            startDate = dateFormatter.date(from: snap.value as! String)!
                        }
                        else if snap.key == "product" {
                            lastValue = snap.childrenCount
                        }
                        else if snap.key == "total_value" {
                            totalValue = snap.value as! Int
                        }
                    }
                    
                    if startDate < date && date < (startDate.addingTimeInterval(3600*24*7)) {
                        var limit = 5000
                        if Globals.isPro {
                            limit = 30000
                        }
                        else if totalValue >= limit {
                            let alert = UIAlertController(title: "Download", message: "You can not download more than \(limit)MB size of books per week, Would you purchase subscription to be allowed 25GB continuous memory?", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (UIAlertAction) in
                                self.onPurchaseSubscription()
                            }))
                            alert.addAction(UIAlertAction(title: "No, Thanks", style: .cancel, handler: { (UIAlertAction) in
                            }))
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                                self.present(alert, animated: true);
                            }
                            return
                        }
                        if totalValue >= limit {
                            print("You can not download more than \(limit)MB size of  books per week, Please try again next week")
                            let alert = UIAlertController(title: "Download", message: "You can not download more than \(limit)MB size of books per week, Please try again next week", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (UIAlertAction) in
                            }))
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                                self.present(alert, animated: true);
                            }
                            
                        }
                        else {
                            //Add new audio
                            self.updatedWeek = Int(week)
                            self.updatedId = id
                            self.updatedDate = dateFormatter.string(from: date)
                            self.updatedAudioID = Int(lastValue+1)
                            self.updatedSize = totalValue + self.bookArray[index]["filesize"].intValue
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                                self.alertDownloadDialog(index: index)
                            }
                        }
                        return
                    }
                    //Create new week
                    self.updatedWeek = Int(week+1)
                    self.updatedId = id
                    self.updatedDate = dateFormatter.string(from: date)
                    self.updatedAudioID = 1
                    self.updatedSize = self.bookArray[index]["filesize"].intValue
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        self.alertDownloadDialog(index: index)
                    }
                }
        }
    }
    
    @objc func onCheckItem(_ sender:UIButton){
        let position = sender.convert(CGPoint.zero, to: collectionView)
        let indexPath = collectionView.indexPathForItem(at: position)
        if indexPath == nil {
            return
        }
        let index:Int = indexPath!.row
        
        print(index)
        
        selectedArray[index] = !selectedArray[index]
        collectionView.reloadItems(at: [indexPath!])
//        if index < bookArray.count && !waiting {
//            self.bookArray.remove(at: index)
//            collectionView.reloadItems(at: [indexPath!])
//        }
    }
    func loadMore(){
        refreshDatabySort(key: Globals.genreKey)
    }
    
    @IBAction func onSelectAll(_ sender: Any) {
        for i in 0 ..< selectedArray.count {
            selectedArray[i] = true
        }
        collectionView.reloadData()
    }
    @IBAction func onDeselectAll(_ sender: Any) {
        for i in 0 ..< selectedArray.count {
            selectedArray[i] = false
        }
        collectionView.reloadData()
    }
    @objc func toDownloadQueue(){
        if !waiting {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                print("Go to Download")
                self.performSegue(withIdentifier: "toDownload", sender: nil)
            })
        }
    }
    @IBAction func onDownloadAll(_ sender: Any) {
        var count = 0
        for i in 0 ..< bookArray.count {
            if selectedArray[i] {
                if Globals.onAddBookToQueue(book: self.bookArray[i]) == 0 {
                    count = count + 1
                }
            }
        }
        Globals.autoSync()
        view.makeToast("Added \(count) books in download queue")
        
         /*
        if Globals.downloadBookArray.count == 0 {
            let alert = UIAlertController(title: "Empty books", message: "Please select at least one book to downlod.", preferredStyle: UIAlertController.Style.alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                                        
                                    }))
            self.present(alert, animated: true);
            return
        }
        if !waiting {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                print("Go to Download")
                self.performSegue(withIdentifier: "toDownload", sender: nil)
            })
        }
 */
    }
}
extension AudioBookListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
             return bookArray.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let reuseIdentifier = "audio_item"
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath)
            
            let view = cell.viewWithTag(100)
            view?.layer.cornerRadius = 5
            view?.layer.borderWidth = 1
            view?.layer.borderColor = UIColor(red: 96/255.0, green: 93/255.0, blue: 124/255.0, alpha: 1).cgColor
            
            let titleLabel = cell.viewWithTag(101) as! UILabel
            titleLabel.text = bookArray[indexPath.row]["title"].stringValue
            let authorLabel = cell.viewWithTag(102) as! UILabel
            authorLabel.text = bookArray[indexPath.row]["author"].stringValue
            
            let image = cell.viewWithTag(103) as! UIImageView
            image.image = UIImage(named: "icon_source_item.png")
            var coverString:String = bookArray[indexPath.row]["cover"].stringValue
            coverString = coverString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let imageUrl = Globals.serverUrl + "cover/" + coverString
            if bookArray[indexPath.row]["has_cover"].intValue > 0 {
                ImageViewManager.getImageFromUrl(url: imageUrl, imageView: image, placeholder: UIImage(named: "icon_source_item.png")!)
            }
            
            cell.contentView.layer.shadowColor = UIColor.black.cgColor
            cell.contentView.layer.shadowOpacity = 1
            cell.contentView.layer.shadowOffset = CGSize(width: -1, height: 1)
            cell.contentView.layer.shadowRadius = 4.0
            
            let checkButton = cell.viewWithTag(104) as! UIButton
            checkButton.addTarget(self, action: #selector(onCheckItem(_:)), for: .touchUpInside)
            
            let checkImage = cell.viewWithTag(105) as! UIImageView
            if selectedArray[indexPath.row] {
                checkImage.image = UIImage(named: "icon_check_on.png")
            }
            else {
                checkImage.image = UIImage(named: "icon_check_off.png")
            }
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            alertDownloadDialog(index: indexPath.row)
 
//                onCheckAudioId(id: bookArray[indexPath.row]["id"].intValue, index: indexPath.row)
            
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let yourWidth = collectionView.bounds.width/3.0-10
            let yourHeight = yourWidth + 60
            return CGSize(width: yourWidth, height: yourHeight)
        }
        
        func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//            print(indexPath.row, bookArray.count-1)
            if indexPath.row == bookArray.count - 1 && !waiting && !isLast{
                waiting = true
                loadMore()
                UIView.animate(withDuration: 1) {
//                    self.collectionViewBottom.constant = 60
                    self.loadMoreAnimtionView.isHidden = false
                }
            }
        }
}
