//
//  Constants.swift
//  BookPlayer

import Foundation
import StoreKit
import SearchTextField
import Alamofire
import SwiftyJSON
import UIKit

enum Constants {
    enum UserDefaults: String {
        // Application information
        case completedFirstLaunch = "userSettingsCompletedFirstLaunch"
        case fileProtectionMigration = "userSettingsFileProtectionMigration"
        case lastPauseTime = "userSettingsLastPauseTime"
        case lastPlayedBook = "userSettingsLastPlayedBook"

        // User preferences
        case chapterContextEnabled = "userSettingsChapterContext"
        case remainingTimeEnabled = "userSettingsRemainingTime"
        case smartRewindEnabled = "userSettingsSmartRewind"
        case boostVolumeEnabled = "userSettingsBoostVolume"
        case globalSpeedEnabled = "userSettingsGlobalSpeed"
        case autoplayEnabled = "userSettingsAutoplay"
        case autolockDisabled = "userSettingsDisableAutolock"

        case rewindInterval = "userSettingsRewindInterval"
        case forwardInterval = "userSettingsForwardInterval"

        case artworkJumpControlsUsed = "userSettingsArtworkJumpControlsUsed"
    }

    enum SmartRewind: TimeInterval {
        case threshold = 599.0 // 599 = 10 mins
        case maxTime = 30.0
    }

    enum Volume: Float {
        case normal = 1.0
        case boosted = 2.0
    }
}
struct Globals {
//    public static let apiUrl = "http://ec2-52-15-147-184.us-east-2.compute.amazonaws.com";
    public static let apiUrl = "http://24.22.30.62:8083";
    public static let adminUrl = "http://24.22.30.62:5000";
//    public static let adminUrl = "http://192.168.1.238:5000";
    public static var authKey = "YWRtaW46YWRtaW4xMjM="
    public static var serverUrl = ""
    public static var serverTitle = ""
    public static var username = "admin"
    public static var password = "admin123"
    public static var email = ""
    public static var userPassword = ""
    public static var token = ""
    public static var deviceID = ""
    public static var isPro = false
    public static var products = [SKProduct]()
    public static var isNew = false
    public static var genreKey = ""
    public static var downloadBookArray = [BookData]()
    public static var cookies:[HTTPCookie] = []
    public static var downloadingGenre = ""
    public static var isSyncing = false
    public static var isAutoFillSyncing = false
    public static var genreArray = [JSON]()
    public static var virtualLibraries = [JSON]()
    public static var virtualLibraryIndex = -1
    public static var queueProgress:CGFloat = 0
    public static var genreEndIndex = [String:Bool]()
    public static var genreCountMap = [String:Int]()
    public static var autoGenreListRequest:Request!
    public static func getSaveFileUrl(fileName: String) -> URL {
        print(fileName)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(fileName)
        return fileURL;
    }
    public static func isExist(fileUrl:String, title:String, author:String) -> Bool {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileUrl) {
            return true
        }
        let library = DataManager.getLibrary()
        var items: [LibraryItem] {
            guard library != nil else {
                return []
            }

            return library.items?.array as? [LibraryItem] ?? []
        }
        for item in items {
            if let book = item as? Book {
                print(item.title!, title)
                if title == book.title && author == book.author {
                    return true
                }
            }
            else if let p = item as? Playlist {
                let books = p.getBooks(from: 0)
                for sb in books {
                    if title == sb.title && author == sb.author {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    public static func getBookCount(genre:String) -> Int {
        var count = 0
        let fileManager = FileManager.default
        if let urls = try? fileManager.contentsOfDirectory(at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
            for url in urls {
                let gr = url.lastPathComponent.slice(from: "(", to: ")")
                if gr == genre {
                    count = count + 1
                }
            }
        }
        for book in downloadBookArray {
            if book.genre == genre {
                count = count + 1
            }
        }
        
        let library = DataManager.getLibrary()
        var items: [LibraryItem] {
            guard library != nil else {
                return []
            }
            return library.items?.array as? [LibraryItem] ?? []
        }
        
        for item in items {
            if let p = item as? Playlist {
                if p.title == genre {
                    count = count + p.getBooks(from: 0).count
                }
            }
        }
        return count
    }
    public static func autoSync(){
        if isSyncing {
            return
        }
        DispatchQueue.global(qos: .background).async {
            if Globals.downloadBookArray.count == 0 {
                isSyncing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    autoSync()
                }
            }
            else {
                isSyncing = true
                if downloadBookArray.count == 0 {
                    return
                }
                onMakeDownloadRequest()
            }
        }
    }
    
    static func onAddBookToQueue(book:JSON) -> Int { //0 - success, 1 - already downloaded, 2 - on queue, 3 - overflow than limit
        let bookDate = BookData.init(id: book["id"].intValue,
            name: "\(book["id"].stringValue) (\(book["tags"].stringValue)) \(book["title"].stringValue).\(book["format"].stringValue.lowercased())",
            format: book["format"].stringValue.lowercased(),
            size: (book["filesize"].stringValue as NSString).floatValue,
            title: book["title"].stringValue,
            author: book["author"].stringValue,
            genre: book["tags"].stringValue
        )
        if isExist(fileUrl: bookDate.fileUrl!.path, title: bookDate.title, author: bookDate.author) {
            return 1
        }
        for db in downloadBookArray {
            if db.downloadUrl == bookDate.downloadUrl {
                return 2
            }
        }
        let count = getBookCount(genre: book["tags"].stringValue)
        if count > 10 {
            return 3
        }
        Globals.downloadBookArray.append(bookDate)
        return 0
    }
    static func onMakeDownloadRequest(){
        if Globals.downloadBookArray.count == 0  {
            isSyncing = false
            return
        }
        print("download file on queue")
        let bookData = Globals.downloadBookArray[0]
        let fileUrl = bookData.fileUrl
        downloadingGenre = bookData.genre
        print(fileUrl!.path)
        
        AF.session.configuration.httpCookieStorage?.setCookies(Globals.cookies, for: URL(string: bookData.downloadUrl), mainDocumentURL: nil)
        
        AF.request(bookData.downloadUrl, headers: [
            "Authorization":"Basic \(Globals.authKey)"])
            .authenticate(username: Globals.username, password: Globals.password)
            .downloadProgress { progress in
                Globals.queueProgress =  CGFloat(progress.fractionCompleted)
                print(Globals.queueProgress)
            }
            .response { response in
                Globals.queueProgress = 0
                if let error = response.error {
                    print(error.localizedDescription)
                }
                else if let data = response.data {
                    do {
                        print("sync download completed genre file")
                        try data.write(to: fileUrl!, options: .atomic)
                        updateAudoDownloadBookIndex(genre: bookData.genre, id: bookData.id)
                        updateDownloadNumberOnServer(id: bookData.id)
                        if Globals.downloadBookArray.count > 0 {
                            Globals.downloadBookArray.remove(at: 0)
                        }
                        NotificationCenter.default.post(name: .didChangeDownloadQueue, object: nil)
                    }
                    catch {
                        print(error)
                    }
                }
                isSyncing = false
                autoSync()
        }
    }
    
    ///Adding files automatically to Download Queue    
    static public func autoFillDownloadQueue(genre:String) {
        if isAutoFillSyncing {
            return
        }
        let count = getBookCount(genre: genre)
        let totalCount = genreCountMap[genre] ?? 0
        if count > 10 || (totalCount != 0 && count >= totalCount) || genre == "Favorite" {
            isAutoFillSyncing = false
            return
        }
        isAutoFillSyncing = true
        let startAt = getAutoDownloadStartAt(genre: genre)
        var rootUrl = serverUrl
        if rootUrl == "" {
            rootUrl = apiUrl + "/"
        }
        var link = rootUrl + "genrelist/" +  genre.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        if startAt > 0 {
            link = rootUrl + "genrelist/" + "\(startAt)/" + genre.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        }
        print(link)
        
        let loginString = String(format: "%@:%@", Globals.username, Globals.password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
         
        AF.request(link, method: .get, parameters: nil,encoding: JSONEncoding.default, headers: [
            "Authorization":"Basic \(base64LoginString)"]).responseJSON { response in
                switch response.result {
                case .success(let value):
//                    if let result = response.result.value {
                        let json = JSON(value)
                        if json.arrayValue.count == 0 {
                            print(genre + " is end")
                            genreEndIndex[genre] = true
                            isAutoFillSyncing = false
                            updateAutoDownloadStartAt(genre: genre, startAt: 0)
                        }
                        else {
                            updateAutoDownloadStartAt(genre: genre, startAt: startAt + 20)
                            for book in json.arrayValue {
//                                if !getAudoDownloadBookIndexState(genre: genre, id: book["id"].intValue) {
                                    let resultCode = onAddBookToQueue(book: book)
                                    if resultCode == 3 {
                                        isAutoFillSyncing = false
                                        return
                                    }
                                    if resultCode == 0 {
                                        print("Auto added on download queue: \(book["title"].stringValue)")
                                    }
//                                }
                            }
                            isAutoFillSyncing = false
                            autoFillDownloadQueue(genre: genre)
                        }
//                    }
//                    else {
//                        print("auto loading data failure")
//                        isAutoFillSyncing = false
//                        autoFillDownloadQueue(genre: genre)
//                    }

                case .failure(let error):
                    print(error.localizedDescription)
                    isAutoFillSyncing = false
                    autoFillDownloadQueue(genre: genre)
                }
        }
    }
    static func getAutoGenreList(){
        var rootUrl = serverUrl
        if rootUrl == "" {
            rootUrl = apiUrl + "/"
        }
        let link = rootUrl + "genre_title_list"
        print(link)
        
        let loginString = String(format: "%@:%@", Globals.username, Globals.password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        Globals.authKey = base64LoginString
        autoGenreListRequest = AF.request(link, method: .get, parameters: nil,encoding: JSONEncoding.default, headers: [
        "Authorization":"Basic \(base64LoginString)"])
            .responseJSON { response in
                switch response.result {
                case .success(let value):
//                    if let result = response.result.value {
                        let json = JSON(value)
                        let jsonArray = json.arrayValue
                        for item in jsonArray {
                            Globals.genreCountMap[item["title"].stringValue] = item["count"].intValue
                        }
//                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    
                }
        }
                
        AF.request(rootUrl)
        .authenticate(username: Globals.username, password: Globals.password)
        .validate(contentType: ["application/json"])
            .response { response in
                Globals.cookies = HTTPCookieStorage.shared.cookies!
                print(Globals.cookies)
                AF.session.configuration.httpCookieStorage?.setCookies(Globals.cookies, for: response.request?.url, mainDocumentURL: nil)
        }
    }
    static func getVirtualLibraries(completion:(()->Void)?) {
        var rootUrl = serverUrl
        if rootUrl == "" {
            rootUrl = apiUrl + "/"
        }
        let link = rootUrl + "virtual-libraries"
        print(link)
        
        let loginString = String(format: "%@:%@", Globals.username, Globals.password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        Globals.authKey = base64LoginString
        autoGenreListRequest = AF.request(link, method: .get, parameters: nil,encoding: JSONEncoding.default, headers: [
        "Authorization":"Basic \(base64LoginString)"])
            .responseJSON { response in
                switch response.result {
                case .success(let value):
//                    if let result = response.result.value {
                        let json = JSON(value)
                        virtualLibraries = json.arrayValue
                        completion!()
//                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
        }
                
        AF.request(rootUrl)
        .authenticate(username: Globals.username, password: Globals.password)
        .validate(contentType: ["application/json"])
            .response { response in
                Globals.cookies = HTTPCookieStorage.shared.cookies!
                print(Globals.cookies)
                AF.session.configuration.httpCookieStorage?.setCookies(Globals.cookies, for: response.request?.url, mainDocumentURL: nil)
        }
    }
    static func cancelAutoGetGenreList(){
        autoGenreListRequest.cancel()
    }
    static func getAutoDownloadStartAt(genre:String) -> Int {
        let defaults: UserDefaults = UserDefaults.standard
        let start_at = defaults.integer(forKey: "\(genre)_autodownload_start_at")
        
        return start_at
    }
    static func updateAutoDownloadStartAt(genre:String, startAt:Int) {
        let defaults: UserDefaults = UserDefaults.standard
        defaults.set(startAt, forKey: "\(genre)_autodownload_start_at")
    }
    static func getAudoDownloadBookIndexState(genre:String, id: Int) -> Bool {
        let defaults: UserDefaults = UserDefaults.standard
        let index_list_count = defaults.integer(forKey: "\(genre)_autodownload_index_count")
        var index_map = [Int:Bool]()
        for i in 0 ..< index_list_count {
            index_map[defaults.integer(forKey: "\(genre)_autodownload_index_\(i)")] = true
        }
        if index_map[id] ?? false {
            return true
        }
        return false
    }
    static func updateAudoDownloadBookIndex(genre:String, id: Int) {
        let defaults: UserDefaults = UserDefaults.standard
        let index_list_count = defaults.integer(forKey: "\(genre)_autodownload_index_count")
        var index_map = [Int:Bool]()
        for i in 0 ..< index_list_count {
            index_map[defaults.integer(forKey: "\(genre)_autodownload_index_\(i)")] = true
        }
        if index_map[id] ?? false {
            return
        }
        defaults.set(id, forKey: "\(genre)_autodownload_index_\(index_list_count)")
        defaults.set(index_list_count+1, forKey: "\(genre)_autodownload_index_count")
    }
    static func updateDownloadNumberOnServer(id:Int) {
        let updateUrl = Globals.adminUrl + "/api/books/update-download"
        print(updateUrl)
        print(deviceID)
        AF.request(updateUrl, method: .post, parameters: ["id": id, "udid":deviceID],encoding: JSONEncoding.default, headers: ["Authorization":token]).responseJSON { response in
                switch response.result {
                case .success(let value):
//                    if let result = response.result.value {
                        let json = JSON(value)
                        if json["success"].boolValue {
                            print(json["message"].stringValue)
                        }
                        else {
                            print(json["message"].stringValue)
                        }
//                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
        }
    }
    static func updateFavoriteNumberOnServer(id:Int) {
        if id == 0 {
            return
        }
        let loginUrl = Globals.adminUrl + "/api/books/update-favorite"
        AF.request(loginUrl, method: .post, parameters: ["id": id, "udid":deviceID],encoding: JSONEncoding.default, headers: ["Authorization":token]).responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if json["success"].boolValue {
                        print(json["message"].stringValue)
                    }
                    else {
                        print(json["message"].stringValue)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
        }
    }
    static func updateUserProStateOnServer(state:Bool) {
        let loginUrl = Globals.adminUrl + "/api/devices/update-pro-state"
        AF.request(loginUrl, method: .post, parameters: ["state": state, "udid":deviceID],encoding: JSONEncoding.default, headers: ["Authorization":token]).responseJSON { response in
                switch response.result {
                case .success(let value):
//                    if let result = value {
                        let json = JSON(value)
                        if json["success"].boolValue {
                            print(json["message"].stringValue)
                        }
                        else {
                            print(json["message"].stringValue)
                        }
//                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
        }
    }
    static public func getBookInfo(bookId:String, completion: ((JSON)->Void)? ) {
        var rootUrl = serverUrl
        if rootUrl == "" {
            rootUrl = apiUrl + "/"
        }
        let link = rootUrl + "bookinfo/\(bookId)"
        print(link)
        
        let loginString = String(format: "%@:%@", Globals.username, Globals.password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
         
        AF.request(link, method: .get, parameters: nil,encoding: JSONEncoding.default, headers: [
            "Authorization":"Basic \(base64LoginString)"]).responseJSON { response in
                switch response.result {
                case .success(let value):
//                    if let result = response.result.value {
                        let json = JSON(value)
                    completion?(json)
                case .failure(let error):
                    print(error.localizedDescription)
                }
        }
    }
}

class BookData {
    var name = ""
    var size:Float = 0
    var progress:CGFloat = 0
    var id = 0
    var format = ""
    var title = ""
    var author = ""
    var genre = ""
    var downloadUrl = ""
    var fileUrl:URL?
    init(id:Int, name:String, format: String, size:Float, title:String, author:String, genre:String){
        self.name = name
        self.size = size
        self.id = id
        self.format = format
        self.progress = 0
        self.title = title
        self.author = author
        self.genre = genre
        var rootUrl = Globals.serverUrl
        if rootUrl == "" {
            rootUrl = Globals.apiUrl + "/"
        }
        downloadUrl = rootUrl+"download/\(id)/\(format)/\(id).\(format)"
        fileUrl = Globals.getSaveFileUrl(fileName: name)
    }
}
class DownloadIndexData {
    var id = 0
    var state = "normal"
    
    init(id:Int, state:String){
        self.state = state
        self.id = id
    }
}
extension String {
    func replaceCharacters(characters: String, toSeparator: String) -> String {
        let characterSet = CharacterSet(charactersIn: characters)
        let components = self.components(separatedBy: characterSet)
        let result = components.joined(separator: "")
        return result
    }

    func wipeCharacters(characters: String) -> String {
        return self.replaceCharacters(characters: characters, toSeparator: "")
    }
    func slice(from: String, to: String) -> String? {

        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                substring(with: substringFrom..<substringTo)
            }
        }
    }
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }
}

