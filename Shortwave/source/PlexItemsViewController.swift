//
//  PlexItemsViewController.swift
//  Shortwave
//
//  Created by Mobile World on 12/14/20.
//  Copyright © 2020 Mobile World. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SDWebImage

class PlexItemsViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var plexUrl = ""
    var itemUrl = ""
    var libraries:[JSON] = []
    var completion = {}
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Plex Library"
    }
    override func viewDidAppear(_ animated: Bool) {
        let defaults: UserDefaults = UserDefaults.standard
        plexUrl = defaults.string(forKey: "plex_url")!
        if (plexUrl.count == 0) {
            view.makeToast("url is invalid")
            navigationController?.popViewController(animated: true)
        }
        if plexUrl.last == "/" {
            plexUrl = String(plexUrl.dropLast())
        }
        getData()
    }
    func getData(){
        let libraryUrl = "\(plexUrl)\(itemUrl)"
        print(libraryUrl)
        AF.request(libraryUrl, method: .get, parameters: nil,encoding: JSONEncoding.default, headers: [
            "Accept":"application/json",
            "X-Plex-Token": Globals.plex_token,
        ]).responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    print(json)
                    self.libraries = json["MediaContainer","Metadata"].arrayValue
                    self.title = json["MediaContainer","title1"].stringValue
                    if self.title == "" {
                        self.title = "Plex Library"
                    }
                    
                    self.collectionView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                    self.view.makeToast(error.localizedDescription)
                }
        }
    }
    func getFileName(_ url:String) -> String {
        let arr = url.components(separatedBy: "\\")
        if arr.count == 0 { return "" }
        return arr[arr.count-1]
    }
    func getFileExtension(_ fileName:String) -> String {
        let arr = fileName.components(separatedBy: ".")
        if arr.count == 0 { return ""}
        return arr[arr.count-1]
    }
    func createPlexFolder(){
        let library = DataManager.getLibrary()
        let key = "Plex"
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
}
extension PlexItemsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return libraries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellID:NSString = "libCell";
        let cell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID as String, for: indexPath)
        
        let lib = libraries[indexPath.row]
        let titleLabel = cell.viewWithTag(101) as! UILabel
        if lib["title"].stringValue == "" {
            titleLabel.text = lib["titleSort"].stringValue
        }
        else {
            titleLabel.text = lib["title"].stringValue
        }
        

        let bgImage = cell.viewWithTag(102) as! UIImageView
        let imgeUrl = "\(plexUrl)\(lib["thumb"].stringValue)?X-Plex-Token=\(Globals.plex_token)"
        print(imgeUrl)
        bgImage.sd_setImage(with: URL(string: imgeUrl), placeholderImage: UIImage(named: "default.jpg"))
        
//        let cover = cell.viewWithTag(102)!
//        print(collectionView.bounds.width)
//        var columnCount:CGFloat = 2
//        if collectionView.bounds.width > 374 {
//            columnCount = 3
//        }
//        let yourWidth = collectionView.bounds.width/columnCount - 10
//        let yourHeight = yourWidth * 2 / 3
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let lib = libraries[indexPath.row]
        if lib["type"].stringValue == "track" {
            var json = JSON()
            json["name"].string = "\(getFileName(lib["Media",0,"Part",0,"file"].stringValue))"
            json["file_name"].string = "\(lib["Media",0,"Part",0,"id"].intValue) (Plex) \(getFileName(lib["Media",0,"Part",0,"file"].stringValue))"
            json["size"].float = lib["Media",0,"Part",0,"size"].floatValue / 1024 / 1024
            json["title"].string = lib["title"].stringValue == "" ? lib["titleSort"].stringValue : lib["title"].stringValue
            json["author"].string = lib["parentTitle"].stringValue
            json["genre"].string = "Plex"
            json["tags"].string = "Plex"
            json["format"].string = getFileExtension(json["name"].stringValue)
            json["download"].string = "\(plexUrl)\(lib["Media",0,"Part",0,"key"].stringValue)?X-Plex-Token=\(Globals.plex_token)"
            
            createPlexFolder()
            switch Globals.onAddBookToQueue(book: json) {
            case 0:
                view.makeToast("Added on Download queue.")
                break
            default:
                break
            }
        }
        else {
            let pvc = self.storyboard!.instantiateViewController(withIdentifier: "plex_item") as! PlexItemsViewController
            pvc.itemUrl = lib["key"].stringValue
            self.navigationController?.pushViewController(pvc, animated: true)
        }
//        for i in 0 ..< selectedArray.count {
//            if selectedArray[i] == indexPath {
//                selectedArray.remove(at: i)
//                collectionView.reloadItems(at: [indexPath])
//                return
//            }
//        }
//        selectedArray.append(indexPath)
//        collectionView.reloadItems(at: [indexPath])
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var columnCount:CGFloat = 2
        if collectionView.bounds.width > 374 {
            columnCount = 3
        }
        let yourWidth = collectionView.bounds.width/columnCount - 10
        let yourHeight = yourWidth * 3 / 2

        return CGSize(width: yourWidth, height: yourHeight)
    }
}

