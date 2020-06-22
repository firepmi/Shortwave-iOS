//
//  SourceViewController.swift
//  Shortwave
//
//  Created by Mobile World on 12/10/18.
//  Copyright © 2018 Tortuga Power. All rights reserved.
//

import UIKit

class SourceViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var titleArray = ["Radio Dramas", "Audio Books"]
    var urlArray = [Globals.apiUrl,Globals.apiUrl]
    var userArray = ["admin","admin"]
    var passwordArray = ["admin123","admin123"]
    
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
//        navigationController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onPersonalServer))
        
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
        
        let defaults: UserDefaults = UserDefaults.standard
        
        let server_list_count = defaults.integer(forKey: "server_list_count")
        
        for i in 0 ..< server_list_count {
            urlArray.append(defaults.string(forKey: "server_url\(i)")!)
            titleArray.append(defaults.string(forKey: "server_title\(i)")!)
            userArray.append(defaults.string(forKey: "server_user\(i)")!)
            passwordArray.append(defaults.string(forKey: "server_password\(i)")!)
        }
        
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
    }
    func addNewServer(url:String, title:String, user:String, password:String){
        for i in 0 ..< urlArray.count {
            if url == urlArray[i] {
                urlArray[i] = url
                titleArray[i] = title
                userArray[i] = user
                passwordArray[i] = password
                
                let defaults: UserDefaults = UserDefaults.standard
                defaults.set(url, forKey: "server_url\(i)")
                defaults.set(title, forKey: "server_title\(i)")
                defaults.set(user, forKey: "server_user\(i)")
                defaults.set(password, forKey: "server_password\(i)")
                
                collectionView.reloadData()
                return
            }
        }
        let i = urlArray.count
        let defaults: UserDefaults = UserDefaults.standard
        defaults.set(url, forKey: "server_url\(i-1)")
        defaults.set(title, forKey: "server_title\(i-1)")
        defaults.set(user, forKey: "server_user\(i-1)")
        defaults.set(password, forKey: "server_password\(i-1)")
        defaults.set(i, forKey: "server_list_count")
        
        urlArray.append(url)
        titleArray.append(title)
        userArray.append(user)
        passwordArray.append(password)
        
        collectionView.reloadData()
    }
    @objc func removeServer(_ sender:UIButton){
        let position = sender.convert(CGPoint.zero, to: collectionView)
        let indexPath = collectionView.indexPathForItem(at: position)
        if indexPath == nil {
            return
        }
        let index:Int = indexPath!.row
        
        let alert = UIAlertController(title: "Remove Server", message: "Are you sure to remove this server?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) in
            self.processRemoveServer(index:index)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (UIAlertAction) in
            
        }))
        self.present(alert, animated: true);
        
        
    }
    func processRemoveServer(index:Int){
        let defaults: UserDefaults = UserDefaults.standard
        
        for i in index ..< urlArray.count - 1 {
            urlArray[i] = urlArray[i+1]
            titleArray[i] = titleArray[i+1]
            userArray[i] = userArray[i+1]
            passwordArray[i] = passwordArray[i+1]
            
            defaults.set(urlArray[i], forKey: "server_url\(i-1)")
            defaults.set(titleArray[i], forKey: "server_title\(i-1)")
            defaults.set(userArray[i], forKey: "server_user\(i-1)")
            defaults.set(passwordArray[i], forKey: "server_password\(i-1)")
        }
        
        urlArray.remove(at: urlArray.count-1)
        titleArray.remove(at: titleArray.count-1)
        userArray.remove(at: userArray.count-1)
        passwordArray.remove(at: passwordArray.count-1)
        
        defaults.set(urlArray.count-1, forKey: "server_list_count")
        
        collectionView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urlArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "source_item"

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath)

        let view = cell.viewWithTag(100)
        view?.layer.cornerRadius = 5
        view?.layer.borderWidth = 1
        view?.layer.borderColor = UIColor(red: 96/255.0, green: 93/255.0, blue: 124/255.0, alpha: 1).cgColor

        let titleLabel:UILabel = cell.viewWithTag(101) as! UILabel
        titleLabel.text = titleArray[indexPath.row]

        cell.contentView.layer.shadowColor = UIColor.black.cgColor
        cell.contentView.layer.shadowOpacity = 1
        cell.contentView.layer.shadowOffset = CGSize(width: -1, height: 1)
        cell.contentView.layer.shadowRadius = 5.0

        let deleteButton = cell.viewWithTag(102) as? UIButton
        let deleteLabel = cell.viewWithTag(103)
        if indexPath.row <= 1 {
            deleteButton?.isHidden = true
            deleteLabel?.isHidden = true
        }
        else {
            deleteButton?.isHidden = false
            deleteLabel?.isHidden = false
        }
        deleteButton?.addTarget(self, action: #selector(removeServer(_:)), for: .touchUpInside)
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if( indexPath.row == 0 ) {
            Globals.serverUrl = Globals.apiUrl + "/"
            Globals.username = "admin"
            Globals.password = "admin123"
            Globals.isNew = false
            performSegue(withIdentifier: "mainToSort", sender: nil)
        }
        else {
            Globals.serverUrl = urlArray[indexPath.row]
            if Globals.serverUrl.last! != "/" {
                Globals.serverUrl = Globals.serverUrl + "/"
            }
            Globals.username = userArray[indexPath.row]
            Globals.password = passwordArray[indexPath.row]
            Globals.isNew = false
            self.performSegue(withIdentifier: "mainToSort", sender: nil)
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = collectionView.bounds.width/3.0-10
        let yourHeight = CGFloat(120)
        return CGSize(width: yourWidth, height: yourHeight)
    }
    
}
