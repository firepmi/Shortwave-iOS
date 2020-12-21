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
    
//    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var request:Request!
    var type = 0;
    let activityView = UIActivityIndicatorView(style: .gray)
    var loading = true
    
    let colors = [UIColor.blue, UIColor.gray, UIColor.yellow, UIColor.red, UIColor.green, UIColor.darkGray, UIColor.brown, UIColor.cyan,  UIColor.lightGray, UIColor.orange, UIColor.purple, UIColor.magenta, UIColor.systemOrange, UIColor.systemPink]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        tableView.tableFooterView = UIView(frame: CGRect.zero)
                
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
                            self.listArray = [[]]//[[],[],[]]
                            for item in jsonArray {
                                self.listArray[0].append(item)
                            }

                        self.loaded = true
                        self.collectionView.reloadData()
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
        
        let library = DataManager.getLibrary()
        
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
    func setImage(imageView:UIImageView, title:String) {
        if title.starts(with: "action") || title.starts(with: "advanture") {
            imageView.image = UIImage(named: "actionandadvanture.jpg")
        }
        else if title.starts(with: "american history") {
            imageView.image = UIImage(named: "american_history.jpg")
        }
        else if title.starts(with: "anthology")
                    || title.starts(with: "collection & anthologies")
                    || title.starts(with: "collections & anthologies")
                    || title.starts(with: "collections and anthologies")
                    || title.starts(with: "colletions & anthologies"){
            imageView.image = UIImage(named: "anthology.jpg")
        }
        else if title.starts(with: "aviation") {
            imageView.image = UIImage(named: "aviation.jpg")
        }
        else if title.starts(with: "baseball") {
            imageView.image = UIImage(named: "baseball.jpg")
        }
        else if title.starts(with: "biography") {
            imageView.image = UIImage(named: "biography.jpeg")
        }
        else if title.starts(with: "bloopers") {
            imageView.image = UIImage(named: "bloopers.jpg")
        }
        else if title.starts(with: "culture") {
            imageView.image = UIImage(named: "culture.jpg")
        }
        else if title.starts(with: "celebrity") {
            imageView.image = UIImage(named: "celibrity.jpg")
        }
        else if title.starts(with: "children") {
            imageView.image = UIImage(named: "children.jpeg")
        }
        else if title.starts(with: "christian") || title.starts(with: "religion") {
            imageView.image = UIImage(named: "christian.jpg")
        }
        else if title.starts(with: "christmas") {
            imageView.image = UIImage(named: "christmas.jpg")
        }
        else if title.starts(with: "comedy") {
            imageView.image = UIImage(named: "comedy.jpg")
        }
        else if title.starts(with: "comic") {
            imageView.image = UIImage(named: "comic.jpg")
        }
        else if title.starts(with: "culture") {
            imageView.image = UIImage(named: "culture.jpg")
        }
        else if title.starts(with: "crime") {
            imageView.image = UIImage(named: "crime.jpg")
        }
        else if title.starts(with: "documentary") {
            imageView.image = UIImage(named: "documentary.jpg")
        }
        else if title.starts(with: "drama") {
            imageView.image = UIImage(named: "drama.jpg")
        }
        else if title.starts(with: "engineering") {
            imageView.image = UIImage(named: "engineering.jpg")
        }
        else if title.starts(with: "entertainment") {
            imageView.image = UIImage(named: "entertainment.jpg")
        }
        else if title.starts(with: "espionage") {
            imageView.image = UIImage(named: "espionage.jpg")
        }
        else if title.starts(with: "events") || title.starts(with: "current event") || title.starts(with: "contemporary event"){
            imageView.image = UIImage(named: "events.jpg")
        }
        else if title.starts(with: "expedition") {
            imageView.image = UIImage(named: "expedition.jpg")
        }
        else if title.starts(with: "fiction") {
            imageView.image = UIImage(named: "fiction.jpg")
        }
        else if title.starts(with: "government") {
            imageView.image = UIImage(named: "government.jpg")
        }
        else if title.starts(with: "historical drama") {
            imageView.image = UIImage(named: "historical drama.jpg")
        }
        else if title.starts(with: "historical") {
            imageView.image = UIImage(named: "historical.jpg")
        }
        else if title.starts(with: "history") {
            imageView.image = UIImage(named: "history.jpg")
        }
        else if title.starts(with: "horror") {
            imageView.image = UIImage(named: "horror.jpg")
        }
        else if title.starts(with: "humor") {
            imageView.image = UIImage(named: "humor.jpg")
        }
        else if title.starts(with: "interview") {
            imageView.image = UIImage(named: "interviews.jpeg")
        }
        else if title.starts(with: "jazz") {
            imageView.image = UIImage(named: "jazz.jpg")
        }
        else if title.starts(with: "literature") || title.starts(with: "poet") {
            imageView.image = UIImage(named: "literature.jpg")
        }
        else if title.starts(with: "law") {
            imageView.image = UIImage(named: "law.jpg")
        }
        else if title.starts(with: "magic") {
            imageView.image = UIImage(named: "magic.jpg")
        }
        else if title.starts(with: "military") {
            imageView.image = UIImage(named: "military.jpg")
        }
        else if title.starts(with: "myst") {
            imageView.image = UIImage(named: "mystery.jpg")
        }
        else if title.starts(with: "music") {
            imageView.image = UIImage(named: "music.png")
        }
        else if title.starts(with: "news") {
            imageView.image = UIImage(named: "news.jpg")
        }
        else if title.starts(with: "non") {
            imageView.image = UIImage(named: "non_fiction.jpg")
        }
        else if title.starts(with: "opera") {
            imageView.image = UIImage(named: "opera.jpg")
        }
        else if title.starts(with: "police") {
            imageView.image = UIImage(named: "police.jpg")
        }
        else if title.starts(with: "plays") {
            imageView.image = UIImage(named: "plays.jpg")
        }
        else if title.starts(with: "psycholog") {
            imageView.image = UIImage(named: "psychology.jpg")
        }
        else if title.starts(with: "quiz") {
            imageView.image = UIImage(named: "quiz.jpg")
        }
        else if title.starts(with: "radio") {
            imageView.image = UIImage(named: "radio.jpg")
        }
        else if title.starts(with: "romance") {
            imageView.image = UIImage(named: "romance.jpg")
        }
        else if title.starts(with: "serial") {
            imageView.image = UIImage(named: "serial.jpg")
        }
        else if title.starts(with: "science fiction") {
            imageView.image = UIImage(named: "science_fiction.jpg")
        }
        else if title.starts(with: "science") {
            imageView.image = UIImage(named: "science.jpg")
        }
        else if title.starts(with: "shakespeare") {
            imageView.image = UIImage(named: "shakespeare.jpg")
        }
        else if title.starts(with: "skit") || title.starts(with: "sitcom") || title.starts(with: "situational comedy"){
            imageView.image = UIImage(named: "skit.jpg")
        }
        else if title.starts(with: "sports") {
            imageView.image = UIImage(named: "sports.jpg")
        }
        else if title.starts(with: "song") {
            imageView.image = UIImage(named: "music.png")
        }
        else if title.starts(with: "soap opera") {
            imageView.image = UIImage(named: "soap_opera.jpg")
        }
        else if title.starts(with: "short stor") {
            imageView.image = UIImage(named: "short_story.jpg")
        }
        else if title.starts(with: "supernatural") {
            imageView.image = UIImage(named: "supernatural.jpg")
        }
        else if title.starts(with: "suspense") {
            imageView.image = UIImage(named: "suspense.jpg")
        }
        else if title.starts(with: "superhero") {
            imageView.image = UIImage(named: "superhero.jpg")
        }
        else if title.starts(with: "talent") {
            imageView.image = UIImage(named: "talent.jpg")
        }
        else if title.starts(with: "talk show") {
            imageView.image = UIImage(named: "talkshow.jpg")
        }
        else if title.starts(with: "talk") {
            imageView.image = UIImage(named: "talk.jpg")
        }
        else if title.starts(with: "thriller") {
            imageView.image = UIImage(named: "thriller.jpg")
        }
        else if title.starts(with: "triller") {
            imageView.image = UIImage(named: "triller.jpg")
        }
        else if title.starts(with: "variety") {
            imageView.image = UIImage(named: "variety.jpg")
        }
        else if title.starts(with: "western") {
            imageView.image = UIImage(named: "western.jpg")
        }
        else if title.starts(with: "world war") {
            imageView.image = UIImage(named: "worldwar2.jpg")
        }
        else {
            imageView.image = UIImage(named: "default_category.jpg")
        }
    }
}
extension SortByViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listArray[section].count
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1//genreArray.count
    }
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return genreArray[section]
//    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellID:NSString = "sortCell";
        let cell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID as String, for: indexPath)
//        cell.selectionStyle = .none
        
        let titleLabel = cell.viewWithTag(101) as! UILabel
        titleLabel.text = listArray[indexPath.section][indexPath.row]["title"].stringValue// + " -- (" + listArray[indexPath.section][indexPath.row]["count"].stringValue + ")"
        
        let bgImage = cell.viewWithTag(100) as! UIImageView
        setImage(imageView: bgImage, title: listArray[indexPath.section][indexPath.row]["title"].stringValue.lowercased())
        
        let cover = cell.viewWithTag(102)!
//        cover.applyGradient(withColours: [colors[indexPath.row % colors.count], UIColor.black, colors[indexPath.row % colors.count]])
        let gcolors = [colors[indexPath.row % colors.count], UIColor.black, colors[indexPath.row % colors.count]]
        print(collectionView.bounds.width)
        var columnCount:CGFloat = 2
        if collectionView.bounds.width > 374 {
            columnCount = 3
        }
        let yourWidth = collectionView.bounds.width/columnCount - 10
        let yourHeight = yourWidth * 2 / 3
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0,y: 0,width: yourWidth, height: yourHeight)
        gradient.colors = gcolors.map { $0.cgColor }
//        gradient.locations = locations
        
        cover.layer.sublayers?.forEach( {$0.removeFromSuperlayer()})
        cover.layer.insertSublayer(gradient, at: 0)
                
        let checkImage = cell.viewWithTag(103)
        checkImage?.isHidden = true
        for index in selectedArray {
            if index == indexPath {
                checkImage?.isHidden = false
            }
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        for i in 0 ..< selectedArray.count {
            if selectedArray[i] == indexPath {
                selectedArray.remove(at: i)
                collectionView.reloadItems(at: [indexPath])
                return
            }
        }
        selectedArray.append(indexPath)
        collectionView.reloadItems(at: [indexPath])
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var columnCount:CGFloat = 2
        if collectionView.bounds.width > 374 {
            columnCount = 3
        }
        let yourWidth = collectionView.bounds.width/columnCount - 10
        let yourHeight = yourWidth * 2 / 3

        return CGSize(width: yourWidth, height: yourHeight)
    }
}
