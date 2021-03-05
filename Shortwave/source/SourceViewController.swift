//
//  SourceViewController.swift
//  Shortwave
//
//  Created by Mobile World on 12/10/18.
//  Copyright © 2018 Tortuga Power. All rights reserved.
//

import UIKit
import SwiftyJSON

class SourceViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var serverArray = [JSON()]
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        SubscriptionProducts.store.requestProducts({ [weak self] success, products in
            guard self != nil else { return }
            if success {
                Globals.products = products!
                print("Products count: \(Globals.products.count)")
                Globals.isPro = SubscriptionProducts.store.isProductPurchased(SubscriptionProducts.subscriptionID)
                Globals.updateUserProStateOnServer(state: Globals.isPro)
                print(SubscriptionProducts.subscriptionID, Globals.isPro)
            }
        })
        
        //TODO: it should be removed if you add auto play option on settings
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.autoplayEnabled.rawValue)
    }
    override func viewDidAppear(_ animated: Bool) {
        //Auto Sync Start
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { (t) in
            Globals.autoSync()
        }
        if Globals.genreCountMap.values.count == 0 {
            Globals.getAutoGenreList()
        }
        Globals.getVirtualLibraries {
            self.serverArray = [JSON()]
            self.serverArray.append(contentsOf: Globals.virtualLibraries)
            var calibre = JSON()
            calibre["name"] = "Calibre"
            self.serverArray.append(calibre)
            var plex = JSON()
            plex["name"] = "Plex"
            self.serverArray.append(plex)
            self.collectionView.reloadData()
        }
        var calibre = JSON()
        calibre["name"] = "Calibre"
        self.serverArray.append(calibre)
        var plex = JSON()
        plex["name"] = "Plex"
        self.serverArray.append(plex)
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return serverArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "source_item"

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath)

        let view = cell.viewWithTag(100)
        view?.layer.cornerRadius = 5
        view?.layer.borderWidth = 1
        view?.layer.borderColor = UIColor(red: 96/255.0, green: 93/255.0, blue: 124/255.0, alpha: 1).cgColor

        let titleLabel:UILabel = cell.viewWithTag(101) as! UILabel
        
        if serverArray[indexPath.row]["name"].string == nil {
            titleLabel.text = "Audiobooks"
        }
        else {
            titleLabel.text = serverArray[indexPath.row]["name"].stringValue//titleArray[indexPath.row]
        }

        let icon = view?.viewWithTag(104) as! UIImageView
        if indexPath.row == Globals.virtualLibraries.count + 1 {
            icon.image = UIImage(named: "icon_calibre.png")
        }
        else if indexPath.row == Globals.virtualLibraries.count + 2 {
            icon.image = UIImage(named: "icon_plex.png")
        }
        else {
            icon.image = UIImage(named: "default.jpg")
        }
        
        cell.contentView.layer.shadowColor = UIColor.black.cgColor
        cell.contentView.layer.shadowOpacity = 1
        cell.contentView.layer.shadowOffset = CGSize(width: -1, height: 1)
        cell.contentView.layer.shadowRadius = 5.0

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if Globals.virtualLibraries.count + 1 == indexPath.row {
            onPersonalServer()
        }
        else if Globals.virtualLibraries.count + 2 == indexPath.row {
            print("Plex server")
            onPlexServer()
        }
        else {
            Globals.virtualLibraryIndex = indexPath.row-1
            gotoMain()
        }
        
    }
    @IBAction func onAddNewServer(_ sender: Any) {
        onPersonalServer()
    }
    @objc func onPersonalServer(){
        let vc = storyboard!.instantiateViewController(withIdentifier: "CustomDialog") as! CustomDialogViewController
        
        vc.modalPresentationStyle = .overFullScreen
        let popover = vc.popoverPresentationController
        popover?.sourceView = self.view
        popover?.sourceRect = self.view.bounds
        popover?.delegate = self as? UIPopoverPresentationControllerDelegate
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = { 
            self.performSegue(withIdentifier: "mainToSort", sender: nil) //toBookList
        }
        
        present(vc, animated: true, completion:nil)
        
    }
    @objc func onPlexServer(){
        let vc = storyboard!.instantiateViewController(withIdentifier: "PlexLogin") as! PlexLoginViewController
        
        vc.modalPresentationStyle = .overFullScreen
        let popover = vc.popoverPresentationController
        popover?.sourceView = self.view
        popover?.sourceRect = self.view.bounds
        popover?.delegate = self as? UIPopoverPresentationControllerDelegate
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = {
            let pvc = self.storyboard!.instantiateViewController(withIdentifier: "plex_library")
            self.navigationController?.pushViewController(pvc, animated: true)
//            self.performSegue(withIdentifier: "plex_library", sender: nil) //toBookList
        }
        
        present(vc, animated: true, completion:nil)
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = collectionView.bounds.width/3.0-10
        let yourHeight = CGFloat(120)
        return CGSize(width: yourWidth, height: yourHeight)
    }
    func gotoMain(){
        Globals.serverUrl = Globals.apiUrl + "/"
        Globals.username = "admin"
        Globals.password = "admin123"
        Globals.isNew = false
        performSegue(withIdentifier: "mainToSort", sender: nil)
    }
}
