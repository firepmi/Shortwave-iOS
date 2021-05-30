//
//  ItemCollectionView.swift
//  TV Escola Adult
//
//  Created by Mobile World on 2/11/19.
//  Copyright © 2019 Jenya Ivanova. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import AlamofireImage

protocol ItemCollectionViewDelegate {
    func itemCollectionView(_ itemCollectionView: ItemCollectionView, didSelectItemAt indexPath: IndexPath, section:Int)
    func itemCollectionView(queueBooksForPlayback indexPath: IndexPath, section:Int) -> [Book]
    func itemCollectionView(setUpPlayer books:[Book], section:Int)
    func itemCollectionView(isScrollEnd offset:CGFloat, section: Int)
}
class ItemCollectionView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    var itemDelegate: ItemCollectionViewDelegate!
    var identifier = "BookCollectionViewCell"
    var categoryItemList:[Book] = []
    var collectionPosition = CGFloat(0)
    var section = 0
    var waiting = false
    var byStr = "Title"
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: bounds, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = true
        cv.delegate = self
        cv.dataSource = self
        cv.register(UINib(nibName: "BookCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        cv.backgroundColor = UIColor.clear
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = UIColor.clear
        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        return cv
    }()
    
    override var bounds: CGRect {
        didSet {
            collectionView.frame = bounds
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public func setDelegate(itemCollectionDelegate: ItemCollectionViewDelegate) {
        itemDelegate = itemCollectionDelegate
        addSubview(collectionView)
    }
    public func setScrollDirection(direction: UICollectionView.ScrollDirection){
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = direction
    }
    public func sort(by:String, ascending: Bool){
        if by == "Title" {
            categoryItemList = categoryItemList.sorted(by: {
                if(ascending) {
                    return $0.bookId > $1.bookId
                }
                else {
                    return $0.bookId < $1.bookId
                }
            })
        }
        else if by == "Author" {
            categoryItemList = categoryItemList.sorted(by: {
                if(ascending) {
                    return $0.author > $1.author
                }
                else {
                    return $0.author < $1.author
                }
            })
        }
        else {
            categoryItemList = categoryItemList.sorted(by: {
                if(ascending) {
                    return $0.completedDate ?? Date() < $1.completedDate ?? Date()
                }
                else {
                    return $0.completedDate ?? Date() > $1.completedDate ?? Date()
                }
            })
        }
        collectionView.reloadData()
    }
    public func setContentOffset(offset:CGFloat){
        collectionPosition = offset
        collectionView.contentOffset.x = collectionPosition
        itemDelegate.itemCollectionView(isScrollEnd: offset, section: section)
    }
    
    public func reloadData(array:[Book], scrollingPosition:CGFloat, rowSection: Int){
        categoryItemList = array
        section = rowSection
        collectionPosition = scrollingPosition
        waiting = false
        collectionView.reloadData()
    }
    public func reloadData(array:[Book]){
        categoryItemList = array
        waiting = false
        collectionView.reloadData()
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryItemList.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath as IndexPath) as! BookCollectionViewCell

        if categoryItemList.count <= indexPath.row {
            return cell
        }
        
        
        let item = categoryItemList[indexPath.row]
        
        cell.artwork = item.artwork
        cell.title = item.title
        cell.playbackState = .stopped
        cell.type = item is Playlist ? .playlist : .book

        cell.onArtworkTap = { [weak self] in
            guard let books = self?.itemDelegate.itemCollectionView(queueBooksForPlayback: indexPath, section: self!.section) else {
                return
            }

            self?.itemDelegate.itemCollectionView(setUpPlayer: books, section: self!.section)
        }

        if let book = item as? Book {
            cell.subtitle = book.author
            cell.progress = book.progress
        } else if let playlist = item as? Playlist {
            cell.subtitle = playlist.info()
            cell.progress = playlist.downloadProgress()
        }
        
        return cell;
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("collectionview scroll end")
        collectionPosition = scrollView.contentOffset.x
        itemDelegate.itemCollectionView(isScrollEnd: collectionPosition, section: section)
    }
    
    func reloadCell(y:Int){
        if y < 0 {
            return ;
        }
        let indexPath1 = IndexPath(row: y, section: 0)
        collectionView.reloadItems(at: [indexPath1])
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.reloadData()
        itemDelegate.itemCollectionView(self, didSelectItemAt: indexPath, section: section)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: 150, height: 200)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
//        if flowLayout.scrollDirection == .vertical {
//            let w = collectionView.bounds.width
//            let n:Int = Int(w / 173)
//            let totalCellWidth = 173 * n
//            let totalSpacingWidth = 10 * (n-1)
//
//            var leftInset = (w - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
//            if leftInset < 0 {
//                leftInset = 0
//            }
//            let rightInset = leftInset
//
//            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
//        }
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

