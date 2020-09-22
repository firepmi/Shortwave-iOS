//
//  ImageViewManager.swift
//  TV Escola Adult
//
//  Created by Mobile World on 3/25/19.
//  Copyright © 2019 Jenya Ivanova. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import SwiftyJSON

//class ImageViewManager {
//    public static var imageViewDictionary = Dictionary<UIImageView,String>()
//    public static var imagesDictionary = Dictionary<String,UIImage>()
//    public static func getImageFromUrl(url: String, imageView:UIImageView, placeholder:UIImage) {
//        //        print("url:" , url)
//        if( url == "" ) {
//            imageView.image = placeholder
//            return
//        }
//        if imagesDictionary[url] != nil {
//            imageView.image = imagesDictionary[url]
//            return
//        }
//        else {
//            imageView.image = placeholder
//        }
//        imageViewDictionary[imageView] = url
//        AF
//            .request(url, method: .get, parameters: nil,encoding: JSONEncoding.default, headers: [
//                "Authorization":"Basic \(Globals.authKey)"])
//            .authenticate(username: Globals.username, password: Globals.password)
//            .responseImage { response in
//            guard let image = response.result.value else {
//                // Handle error
//                print("image download error:")
//                print(url)
//                return
//            }
//            imagesDictionary[url] = image
//            checkImageView(url: url)
//            // Do stuff with your image
//        }
//    }
//    static func checkImageView(url:String){
//        for viewItem in imageViewDictionary {
//            if viewItem.value == url {
//                viewItem.key.image = imagesDictionary[url]
//                imageViewDictionary.removeValue(forKey: viewItem.key)
//            }
//        }
//    }
//}
