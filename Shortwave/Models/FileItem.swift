//
//  FileItem.swift
//  BookPlayer
//
//  Created by Gianni Carlo on 9/11/18.
//  Copyright © 2018 Tortuga Power. All rights reserved.
//

import Foundation

class FileItem {
    var originalUrl: URL
    var processedUrl: URL?
    var destinationFolder: URL
    var genre = ""
    var bookId = 0

    init(originalUrl: URL, processedUrl: URL?, destinationFolder: URL, genre: String, bookId: Int) {
        self.originalUrl = originalUrl
        self.processedUrl = processedUrl
        self.destinationFolder = destinationFolder
        self.genre = genre
        self.bookId = bookId
    }
    convenience init(_ url: URL, destinationFolder: URL) {
        self.init(originalUrl: url, processedUrl: nil, destinationFolder: destinationFolder, genre:"", bookId: 0)
    }
}
