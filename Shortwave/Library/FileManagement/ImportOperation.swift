//
//  BookOperation.swift
//  BookPlayer
//
//  Created by Gianni Carlo on 8/30/18.
//  Copyright © 2018 Tortuga Power. All rights reserved.
//

import Foundation
import IDZSwiftCommonCrypto

/**
 Process files located at a specific `URL`, renames it with the hash and moves it to the specified destination folder.
 The new file maintains the extension of the original `URL`
 */

class ImportOperation: Operation {
    let files: [FileItem]

    init(files: [FileItem]) {
        self.files = files
    }

    override func main() {
        for file in self.files {
            guard FileManager.default.fileExists(atPath: file.originalUrl.path),
                let inputStream = InputStream(url: file.originalUrl) else {
                    continue
            }

            NotificationCenter.default.post(name: .processingFile, object: self, userInfo: ["filename": file.originalUrl.lastPathComponent])

            inputStream.open()

            let digest = Digest(algorithm: .md5)

            while inputStream.hasBytesAvailable {
                var inputBuffer = [UInt8](repeating: 0, count: 1024)
                inputStream.read(&inputBuffer, maxLength: inputBuffer.count)
                _ = digest.update(byteArray: inputBuffer)
            }

            inputStream.close()

            let finalDigest = digest.final()

            let hash = hexString(fromArray: finalDigest)
            let ext = file.originalUrl.pathExtension
            let filename = hash + ".\(ext)"
            let destinationURL = file.destinationFolder.appendingPathComponent(filename)

            do {
                if !FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.moveItem(at: file.originalUrl, to: destinationURL)
                } else {
                    try FileManager.default.removeItem(at: file.originalUrl)
                }
            } catch {
                print("Fail to move file from \(file.originalUrl) to \(destinationURL)")
            }

            file.processedUrl = destinationURL
        }
    }
}
