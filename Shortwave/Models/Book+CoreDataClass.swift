//
//  Book+CoreDataClass.swift
//  BookPlayer
//
//  Created by Gianni Carlo on 5/14/18.
//  Copyright © 2018 Tortuga Power. All rights reserved.
//
//

import Foundation
import CoreData
import AVFoundation

public class Book: LibraryItem {
    var fileItem: FileItem?
    var context: NSManagedObjectContext?
    var fileURL: URL {
        return DataManager.getProcessedFolderURL().appendingPathComponent(self.identifier)
    }
    
    var currentChapter: Chapter? {
        guard let chapters = self.chapters?.array as? [Chapter], !chapters.isEmpty else {
            return nil
        }

        for chapter in chapters where chapter.start <= self.currentTime && chapter.end > self.currentTime {
            return chapter
        }

        return nil
    }

    var displayTitle: String {
        return self.title
    }

    var progress: Double {
        return self.currentTime / self.duration
    }

    var percentage: Double {
        return round(self.progress * 100)
    }

    var hasChapters: Bool {
        return !(self.chapters?.array.isEmpty ?? true)
    }

    // TODO: This is a makeshift version of a proper completion property.
    // See https://github.com/TortugaPower/BookPlayer/issues/201
    var isCompleted: Bool {
        return round(self.currentTime) >= round(self.duration)
    }

    func setChapters(from asset: AVAsset, context: NSManagedObjectContext) {
        for locale in asset.availableChapterLocales {
            let chaptersMetadata = asset.chapterMetadataGroups(withTitleLocale: locale, containingItemsWithCommonKeys: [AVMetadataKey.commonKeyArtwork])

            for (index, chapterMetadata) in chaptersMetadata.enumerated() {
                let chapterIndex = index + 1
                let chapter = Chapter(from: asset, context: context)

                chapter.title = AVMetadataItem.metadataItems(
                    from: chapterMetadata.items,
                    withKey: AVMetadataKey.commonKeyTitle,
                    keySpace: AVMetadataKeySpace.common
                ).first?.value?.copy(with: nil) as? String ?? ""
                chapter.start = CMTimeGetSeconds(chapterMetadata.timeRange.start)
                chapter.duration = CMTimeGetSeconds(chapterMetadata.timeRange.duration)
                chapter.index = Int16(chapterIndex)

                self.addToChapters(chapter)
            }
        }
    }

    convenience init(from bookUrl: FileItem, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Book", in: context)!
        self.init(entity: entity, insertInto: context)
        let fileURL = bookUrl.processedUrl!
        self.ext = fileURL.pathExtension
        self.identifier = fileURL.lastPathComponent
        let asset = AVAsset(url: fileURL)

        let titleFromMeta = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common).first?.value?.copy(with: nil) as? String
        let authorFromMeta = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.commonKeyArtist, keySpace: AVMetadataKeySpace.common).first?.value?.copy(with: nil) as? String

        self.title = titleFromMeta ?? bookUrl.originalUrl.lastPathComponent.replacingOccurrences(of: "_", with: " ")
        self.author = authorFromMeta ?? "Unknown Author"
        self.duration = CMTimeGetSeconds(asset.duration)

        var colors: ArtworkColors!
        if let data = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common).first?.value?.copy(with: nil) as? NSData {
            self.artworkData = data
            colors = ArtworkColors(from: self.artwork, context: context)
        } else {
            colors = ArtworkColors(context: context)
            self.usesDefaultArtwork = true
        }

        self.artworkColors = colors

        self.setChapters(from: asset, context: context)

        let legacyIdentifier = bookUrl.originalUrl.lastPathComponent
        let storedTime = UserDefaults.standard.double(forKey: legacyIdentifier)
        //migration of time
        if storedTime > 0 {
            self.currentTime = storedTime
            UserDefaults.standard.removeObject(forKey: legacyIdentifier)
        }
        
        self.fileItem = bookUrl
        self.context = context
        self.bookId = bookUrl.bookId
    }
}
