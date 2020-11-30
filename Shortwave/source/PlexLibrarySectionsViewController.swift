//
//  PlexLibrarySectionsViewController.swift
//  Shortwave
//
//  Created by mobileworld on 30.11.20.
//  Copyright © 2020 Mobile World. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SDWebImage

class PlexLibrarySectionsViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var plexUrl = ""
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
        if plexUrl.last != "/" {
            plexUrl += "/"
        }
        getData()
    }
    func getData(){
        let libraryUrl = "\(plexUrl)library/sections"
        print(libraryUrl)
        AF.request(libraryUrl, method: .get, parameters: nil,encoding: JSONEncoding.default, headers: [
            "Accept":"application/json",
            "X-Plex-Token": Globals.plex_token,
        ]).responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    self.libraries = json["MediaContainer","Directory"].arrayValue
                    self.collectionView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                    self.view.makeToast(error.localizedDescription)
                }
        }
    }
}
extension PlexLibrarySectionsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return libraries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellID:NSString = "libCell";
        let cell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID as String, for: indexPath)
        
        let lib = libraries[indexPath.row]
        let titleLabel = cell.viewWithTag(101) as! UILabel
        titleLabel.text = lib["title"].stringValue

        let bgImage = cell.viewWithTag(102) as! UIImageView
        let imgeUrl = "\(String(plexUrl.dropLast()))\(lib["composite"].stringValue)?X-Plex-Token=\(Globals.plex_token)"
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
