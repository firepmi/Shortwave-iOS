//
//  BookDetailViewController.swift
//  Shortwave
//
//  Created by mobileworld on 9/21/20.
//  Copyright © 2020 Mobile World. All rights reserved.
//

import UIKit
import SwiftyJSON
import JGProgressHUD

class BookDetailViewController: BaseListViewController {
    var playlist: Playlist!
    var currentBook: Book!
    
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pubDateLabel: UILabel!
    @IBOutlet weak var seriesLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var zenreLabel: UILabel!
    
    @IBOutlet weak var descriptionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    var identifier = "BookCollectionViewCell"
    
    override var items: [LibraryItem] {
        var sortArray:[Book] = self.playlist.books!.array as! [Book]
        sortArray = sortArray.sorted(by: { $0.bookId > $1.bookId })
//        for a in sortArray {
//            print(a.bookId)
//        }
        return sortArray//self.playlist.books?.array as? [LibraryItem] ?? []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(UINib(nibName: "BookCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        collectionView.invalidateIntrinsicContentSize()
                
        self.toggleEmptyStateView()

        self.navigationItem.title = playlist.title
        
    }
    func getData(){
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Please wait..."
        hud.show(in: self.view)
        Globals.getBookInfo(bookId: "\(currentBook.bookId)", completion: { json in
            print(json)
            hud.dismiss()
            self.reloadDetailView(json: json)
//            self.collectionView.reloadData()
        }, error: { error in
            hud.dismiss()
            print(error)
        })
    }
    func reloadDetailView(json:JSON){
        self.navigationItem.title = json["title"].stringValue
        titleLabel.text = json["title"].stringValue
        pubDateLabel.text = json["authors",0].string
        seriesLabel.text = json["series"].stringValue
        //tags to string
        var zenres = ""
        for zenre in json["tags"].arrayValue {
            zenres = "\(zenres),\(zenre.stringValue)"
        }
        //remove prefix comma,
        if zenres != "" {
            zenres = zenres[1..<zenres.count]
        }
        zenreLabel.text = zenres
        descriptionTextView.text = json["comments"].stringValue
        var coverString:String = json["cover"].stringValue
        coverString = coverString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let imageUrl = Globals.serverUrl + "cover/" + coverString
        if json["has_cover"].intValue > 0 {
            imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: UIImage(named: "default.jpg"))
        }
        else {
            imageView.image = UIImage(named: "default.jpg")
        }
        let fixedWidth = descriptionTextView.frame.size.width
        let newSize = descriptionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        descriptionHeightConstraint.constant = newSize.height
//
        tableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = tableView.contentSize.height
        tableView.alwaysBounceVertical = false
        tableView.isScrollEnabled = false

        detailView.applyGradient(
            withColours:
            [
                UIColor(red: 181/255.0, green: 123/255.0, blue: 220/255.0, alpha: 0.5),
                UIColor(red: 201/255.0, green: 81/255.0, blue: 194/255.0, alpha: 0)
            ], gradientOrientation: .vertical, isShouldClearedChild: false)

    }
    override func viewDidAppear(_ animated: Bool) {
        getData()
    }
    @IBAction func onSeeAll(_ sender: Any) {
        self.loadPlayer(books: items as! [Book])
    }
       
    @IBAction func onPlayBook(_ sender: Any) {
        let books = self.queueBooksForPlayback(self.currentBook, forceAutoplay: true)
        self.setupPlayer(books: books)
    }
    @IBAction func onDownloadBook(_ sender: Any) {
    }
    @IBAction func onMoreBook(_ sender: Any) {
    }
    
    override func handleOperationCompletion(_ files: [FileItem]) {
        DataManager.insertBooks(from: files, into: self.playlist) {
            self.reloadData()
        }
        
        for file in files {
            if file.genre == "" {
                continue
            }
            var playlist:Playlist?
            var items: [LibraryItem] {
                guard self.library != nil else {
                    return []
                }

                return self.library.items?.array as? [LibraryItem] ?? []
            }
            
            for item in items {
                if let p = item as? Playlist {
                    if p.title == file.genre {
                        playlist = p
                        break
                    }
                }
            }
            if playlist == nil {
                playlist = DataManager.createPlaylist(title: file.genre, books: [])
                self.library.addToItems(playlist!)
            }
            DataManager.insertBooks(from: [file], into: playlist!) {
                DataManager.saveContext()

                self.showLoadView(false)
                self.reloadData()
            }
        }
        self.showLoadView(false)
        NotificationCenter.default.post(name: .reloadData, object: nil)
        /*
        guard files.count > 1 else {
            self.showLoadView(false)
            NotificationCenter.default.post(name: .reloadData, object: nil)
            return
        }

        let alert = UIAlertController(title: "Import \(files.count) files into", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Library", style: .default) { (_) in
            DataManager.insertBooks(from: files, into: self.library) {
                self.showLoadView(false)
                self.reloadData()
                NotificationCenter.default.post(name: .reloadData, object: nil)
            }
        })

        alert.addAction(UIAlertAction(title: "Current Playlist", style: .default) { (_) in
            self.showLoadView(false)
            NotificationCenter.default.post(name: .reloadData, object: nil)
        })

        let vc = self.presentedViewController ?? self

        vc.present(alert, animated: true, completion: nil)*/
    }

    // MARK: - Callback events
    @objc override func onBookPlay() {
        guard
            let currentBook = PlayerManager.shared.currentBook,
            let index = self.playlist.itemIndex(with: currentBook.fileURL),
            let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: .library)) as? BookCellView
        else {
            return
        }

        bookCell.playbackState = .playing
    }

    @objc override func onBookPause() {
        guard
            let currentBook = PlayerManager.shared.currentBook,
            let index = self.playlist.itemIndex(with: currentBook.fileURL),
            let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: .library)) as? BookCellView
        else {
            return
        }

        bookCell.playbackState = .paused
    }

    @objc override func onBookStop(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let book = userInfo["book"] as? Book,
            let index = self.playlist.itemIndex(with: book.fileURL),
            let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: .library)) as? BookCellView
        else {
            return
        }

        bookCell.playbackState = .stopped
    }

    // MARK: - IBActions
    @IBAction func addAction() {
        self.presentImportFilesAlert()
    }
}

// MARK: - DocumentPicker Delegate
extension BookDetailViewController {
    override func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            //context put in playlist
            DataManager.processFile(at: url)
        }
    }
}

// MARK: - TableView DataSource
extension BookDetailViewController: BookCellViewDelegate {
    func onCheckBtnClicked(cell: UITableViewCell) {
        let indexPath : IndexPath = self.tableView.indexPath(for: cell)!
        let index:Int = indexPath.row
        
        tableView.reloadRows(at: [indexPath], with: .none)
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        guard let bookCell = cell as? BookCellView else {
            return cell
        }

        bookCell.type = .file
        bookCell.isCheckMode = false
        bookCell.delegate = self
        
        bookCell.isChecked = false
        
        guard let currentBook = PlayerManager.shared.currentBook,
            let index = self.playlist.itemIndex(with: currentBook.fileURL),
            index == indexPath.row else {
                return bookCell
        }

        bookCell.playbackState = .playing

        return bookCell
    }
}

// MARK: - TableView Delegate
extension BookDetailViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if isShowingToolbar {
//            checkList[indexPath.row] = !checkList[indexPath.row]
//            tableView.reloadRows(at: [indexPath], with: .none)
//        }
//        else {
            tableView.deselectRow(at: indexPath, animated: true)

            guard indexPath.sectionValue == .library else {
                if indexPath.sectionValue == .add {
                    self.presentImportFilesAlert()
                }

                return
            }

            let books = self.queueBooksForPlayback(self.items[indexPath.row], forceAutoplay: true)

            self.setupPlayer(books: books)
//        }
        
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard indexPath.sectionValue == .library, let book = self.items[indexPath.row] as? Book else {
            return nil
        }

        let deleteAction = UITableViewRowAction(style: .default, title: "Options") { (_, indexPath) in
            let sheet = UIAlertController(title: "\(book.title!)", message: nil, preferredStyle: .alert)

            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            sheet.addAction(UIAlertAction(title: "Remove from playlist", style: .default, handler: { _ in
                self.playlist.removeFromBooks(book)
                self.library.addToItems(book)

                DataManager.saveContext()

                self.deleteRows(at: [indexPath])

                NotificationCenter.default.post(name: .reloadData, object: nil)
            }))

            sheet.addAction(UIAlertAction(title: "Delete completely", style: .destructive, handler: { _ in
                if book == PlayerManager.shared.currentBook {
                    PlayerManager.shared.stop()
                }

                self.playlist.removeFromBooks(book)

                DataManager.saveContext()

                try? FileManager.default.removeItem(at: book.fileURL)

                self.deleteRows(at: [indexPath])

                NotificationCenter.default.post(name: .reloadData, object: nil)
            }))

            self.present(sheet, animated: true, completion: nil)
        }

        deleteAction.backgroundColor = UIColor.gray

        let favAction = UITableViewRowAction(style: .default, title: "Add to Favorite") { (_, indexPath) in
            
            var playlist:Playlist?
            var items: [LibraryItem] {
                guard self.library != nil else {
                    return []
                }

                return self.library.items?.array as? [LibraryItem] ?? []
            }
            
            for item in items {
                if let p = item as? Playlist {
                    if p.title == "Favorite" {
                        playlist = p
                        break
                    }
                }
            }
            if playlist == nil {
                playlist = DataManager.createPlaylist(title: "Favorite", books: [])
                self.library.addToItems(playlist!)
            }
            if book.fileItem != nil {
                let favBook = Book(from: book.fileItem!, context: book.context!)
                playlist?.addToBooks([favBook])
                Globals.updateFavoriteNumberOnServer(id: book.bookId)
            }
            else {
                playlist?.addToBooks([book])
                Globals.updateFavoriteNumberOnServer(id: book.bookId)
            }
            DataManager.saveContext()

            self.deleteRows(at: [indexPath])

            NotificationCenter.default.post(name: .reloadData, object: nil)
        }
        favAction.backgroundColor = UIColor.purple
        return [deleteAction, favAction]
    }
}

// MARK: - Reorder Delegate
extension BookDetailViewController {
    override func tableView(_ tableView: UITableView, reorderRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard destinationIndexPath.sectionValue == .library else {
            return
        }

        // swiftlint:disable force_cast
        let book = self.items[sourceIndexPath.row] as! Book
        self.playlist.removeFromBooks(at: sourceIndexPath.row)
        self.playlist.insertIntoBooks(book, at: destinationIndexPath.row)
        DataManager.saveContext()
    }
}

extension BookDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath as IndexPath) as? BookCollectionViewCell else {
            return UICollectionViewCell()
        }

        if items.count <= indexPath.row {
            return cell
        }
        
        
        let item = items[indexPath.row]
        
        cell.artwork = item.artwork
        cell.title = item.title
        cell.playbackState = .stopped
        cell.type = item is Playlist ? .playlist : .book

        cell.onArtworkTap = { [weak self] in
            guard let books = self?.self.queueBooksForPlayback(self!.items[indexPath.row]) else {
                return
            }

            self!.setupPlayer(books: books)
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
        
    func reloadCell(y:Int){
        if y < 0 {
            return ;
        }
        let indexPath1 = IndexPath(row: y, section: 0)
        collectionView.reloadItems(at: [indexPath1])
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let books = self.queueBooksForPlayback(items[indexPath.row])

        if let playlist = self.items[indexPath.row] as? Playlist {
            self.presentBookDetails(playlist, books: books)

            return
        }
        self.setupPlayer(books: books)
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
