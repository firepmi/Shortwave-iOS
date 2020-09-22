//
//  SortByViewController.swift
//  Shortwave
//
//  Created by Mobile World on 3/23/19.
//  Copyright © 2019 Mobile World. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class SortByViewController: UIViewController {
    var genreArray = ["Fiction","Non-Fiction"/*,"Faith / Spiritual"*/]
    var listArray:[[JSON]] = [[],[],[]]
    var selectedArray:[IndexPath] = []
    let alertIndicator = UIAlertController(title: "Please Wait...", message: "\n\n", preferredStyle: UIAlertController.Style.alert)
    var loaded = false
    
    @IBOutlet weak var tableView: UITableView!
    var request:Request!
    var type = 0;
    let activityView = UIActivityIndicatorView(style: .gray)
    var loading = true
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
                
        activityView.center = CGPoint(x: 139.5, y: 75.5)
        activityView.startAnimating()
        alertIndicator.view.addSubview(activityView)
        alertIndicator.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alertIndicator, animated: true) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissAlertController))
            self.alertIndicator.view.superview?.subviews[0].addGestureRecognizer(tapGesture)
        }
        Globals.cancelAutoGetGenreList()
    }
    func onLoadData(){
        self.loading = true
        var link = Globals.serverUrl + "genre_title_list"
        let loginString = String(format: "%@:%@", Globals.username, Globals.password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        Globals.authKey = base64LoginString
        
        if Globals.virtualLibraryIndex != -1 {
            link = "\(link)/\(Globals.virtualLibraryIndex)"
        }
        print(link)
        request = AF.request(link, method: .get, parameters: nil,encoding: JSONEncoding.default, headers: [
        "Authorization":"Basic \(base64LoginString)"])
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    self.loading = false
                    self.alertIndicator.dismiss(animated: false) {
//                        if let result = value {
                            let json = JSON(value)
                            let jsonArray = json.arrayValue
                            self.listArray = [[],[],[]]
                            for item in jsonArray {
                                var added = false
                                Globals.genreCountMap[item["title"].stringValue] = item["count"].intValue
                                for i in 0 ..< self.genreArray.count {
                                    if item["genre"].stringValue == self.genreArray[i] {
                                        self.listArray[i].append(item)
                                        added = true
                                    }
                                }
                                if !added {
                                    self.genreArray.append(item["genre"].stringValue)
                                    self.listArray.append([item])
                                }
                            }
                            
                            for i in 0 ..< self.genreArray.count {
                                if self.genreArray[i] == "Other" {
                                    self.genreArray[i] = "Misc"
                                }
                            }
                            self.loaded = true
                            self.tableView.reloadData()
//                        }
//                        else {
//                            let alert = UIAlertController(title: "Loading Data", message: "Loading Data failure!", preferredStyle: UIAlertController.Style.alert)
//                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (UIAlertAction) in
//                                
//                            }))
//                            self.present(alert, animated: true);
//                        }
                    }

                case .failure(let error):
                    self.loading = false
                    print(error.localizedDescription)
                    var errorMessage = "The server may not exist or it is unavailable at this time. Check the server name or IP address, check your network connection, and then try again."
                    if error.localizedDescription == "cancelled" {
                        errorMessage = "Request timeout, Please check your information or try again later"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        self.alertIndicator.dismiss(animated: true){
                            let alert = UIAlertController(title: "Loading Data", message: errorMessage, preferredStyle: UIAlertController.Style.alert)
                                                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                                                        self.navigationController?.popViewController(animated: true)
                                                    }))
                            self.present(alert, animated: true);
                        }
                    })
                    
                }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: {
            print("stop request", self.loading)
            if self.loading {
                self.loading = false
                self.request.cancel()
                self.alertIndicator.dismiss(animated: true){
                    let alert = UIAlertController(title: "Loading Data", message: "Request timeout, Please check your information or try again later", preferredStyle: UIAlertController.Style.alert)
                                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (UIAlertAction) in
                                                self.navigationController?.popViewController(animated: true)
                                            }))
                    self.present(alert, animated: true);
                }
            }
        })
        
        AF.request(Globals.serverUrl)
            .authenticate(username: Globals.username, password: Globals.password)
        .validate(contentType: ["application/json"])
            .response { response in
                Globals.cookies = HTTPCookieStorage.shared.cookies!
                print(Globals.cookies)
                AF.session.configuration.httpCookieStorage?.setCookies(Globals.cookies, for: response.request?.url, mainDocumentURL: nil)
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        if !loaded {
            onLoadData()
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        self.loading = false
    }
    @objc func dismissAlertController(){
        self.dismiss(animated: true) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func onNext(_ sender: Any) {
        if selectedArray.count == 0 {
            let alert = UIAlertController(title: "Empty genre", message: "Please select at least one genre to show data", preferredStyle: UIAlertController.Style.alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (UIAlertAction) in
                                        
                                    }))
            self.present(alert, animated: true);
            return
        }
        Globals.genreKey = ""
//        Globals.downloadedGenre = listArray[selectedArray[0].section][selectedArray[0].row]["title"].stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var library = DataManager.getLibrary()
        
        for index in selectedArray {
            let key = listArray[index.section][index.row]["title"].stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            Globals.genreKey = Globals.genreKey + key + ":"
            
            var playlist:Playlist?
            var items: [LibraryItem] {
                guard library != nil else {
                    return []
                }

                return library.items?.array as? [LibraryItem] ?? []
            }
            
            for item in items {
                if let p = item as? Playlist {
                    if p.title == key {
                        playlist = p
                        break
                    }
                }
            }
            if playlist == nil {
                playlist = DataManager.createPlaylist(title: key, books: [])
                library.addToItems(playlist!)
            }
        }
        
        if Globals.genreKey.last! == ":" {
            Globals.genreKey = String(Globals.genreKey.dropLast())
        }
        print(Globals.genreKey)
        
//        performSegue(withIdentifier: "genreToDownload", sender: nil) //genreToBookList
        tabBarController?.selectedIndex = 1
    }
}
extension SortByViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listArray[section].count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return genreArray.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return genreArray[section]
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID:NSString = "sortCell";
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellID as String)!
        cell.selectionStyle = .none
        
        let titleLabel = cell.viewWithTag(100) as! UILabel
        titleLabel.text = listArray[indexPath.section][indexPath.row]["title"].stringValue + " -- (" + listArray[indexPath.section][indexPath.row]["count"].stringValue + ")"
        
        let checkImage = cell.viewWithTag(101)
        checkImage?.isHidden = true
        for index in selectedArray {
            if index == indexPath {
                checkImage?.isHidden = false
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for i in 0 ..< selectedArray.count {
            if selectedArray[i] == indexPath {
                selectedArray.remove(at: i)
                tableView.reloadRows(at: [indexPath], with: .none)
                return
            }
        }
        selectedArray.append(indexPath)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
