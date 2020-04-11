//
//  PlaylistViewController.swift
//  BookPlayer
//
//  Created by Gianni Carlo on 5/12/18.
//  Copyright © 2018 Tortuga Power. All rights reserved.
//

import UIKit

class PlaylistViewController: BaseListViewController {
    var playlist: Playlist!
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var toolbarHeightConstraint: NSLayoutConstraint!
    var isShowingToolbar = true
    var checkList = [Bool]()
    override var items: [LibraryItem] {
        return self.playlist.books?.array as? [LibraryItem] ?? []
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.toggleEmptyStateView()

        self.navigationItem.title = playlist.title
        showToolbarView(true)
        
        checkList = []
        for _ in items {
            checkList.append(false)
        }
    }
    
    @IBAction func onToolBar(_ sender: Any) {
        showToolbarView(!isShowingToolbar)
        
        tableView.reloadData()
    }
    func showToolbarView(_ flag: Bool) {
        isShowingToolbar = flag
        self.toolbarHeightConstraint.constant = flag
            ? 60
            : 0
        UIView.animate(withDuration: 0.5) {
            self.toolbarView.isHidden = !flag
            self.view.layoutIfNeeded()
        }
    }
    @IBAction func onSelectAll(_ sender: Any) {
        for i in 0 ..< items.count {
            checkList[i] = true
        }
        tableView.reloadData()
    }
    @IBAction func onDeselectAll(_ sender: Any) {
        for i in 0 ..< items.count {
            checkList[i] = false
        }
        tableView.reloadData()
    }
    @IBAction func onDelete(_ sender: Any) {
        
        var count = 0
        for i in 0 ..< items.count {
            if checkList[i] {
                count = count + 1
            }
        }
        if count == 0 {
            view.makeToast("Please select at least one book to delete")
        }
        else {
            let sheet = UIAlertController(title: "Do you want delete \(count) books?", message: nil, preferredStyle: .alert)

            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            sheet.addAction(UIAlertAction(title: "Delete completely", style: .destructive, handler: { _ in
                var deleteArray = [IndexPath]()
                for (index, item) in self.items.reversed().enumerated() {
                    if self.checkList[index] {
                        let book = item as? Book
                        
                        if book == PlayerManager.shared.currentBook {
                            PlayerManager.shared.stop()
                        }

                        self.playlist.removeFromBooks(book!)

                        DataManager.saveContext()

                        try? FileManager.default.removeItem(at: book!.fileURL)
                        
                        deleteArray.append(IndexPath(row: index, section: 0))
                    }
                }
                self.deleteRows(at: deleteArray)
                NotificationCenter.default.post(name: .reloadData, object: nil)
            }))

            self.present(sheet, animated: true, completion: nil)
        }
        
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
extension PlaylistViewController {
    override func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            //context put in playlist
            DataManager.processFile(at: url)
        }
    }
}

// MARK: - TableView DataSource
extension PlaylistViewController: BookCellViewDelegate {
    func onCheckBtnClicked(cell: UITableViewCell) {
        let indexPath : IndexPath = self.tableView.indexPath(for: cell)!
        let index:Int = indexPath.row
        
        checkList[index] = !checkList[index]
        tableView.reloadRows(at: [indexPath], with: .none)
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        guard let bookCell = cell as? BookCellView else {
            return cell
        }

        bookCell.type = .file
        bookCell.isCheckMode = true
        bookCell.delegate = self
        while indexPath.row >= checkList.count {
            checkList.append(false)
        }
        bookCell.isChecked = checkList[indexPath.row]
        
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
extension PlaylistViewController {
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
            }
            else {
                playlist?.addToBooks([book])
            }
        }
        favAction.backgroundColor = UIColor.purple
        return [deleteAction, favAction]
    }
}

// MARK: - Reorder Delegate
extension PlaylistViewController {
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
