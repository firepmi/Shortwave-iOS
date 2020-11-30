//
//  PlexLoginViewController.swift
//  Shortwave
//
//  Created by mobileworld on 29.11.20.
//  Copyright © 2020 Mobile World. All rights reserved.
//

import UIKit
import SearchTextField
import Alamofire
import SwiftyXMLParser
import Toast_Swift

class PlexLoginViewController: UIViewController {
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
        
    @IBOutlet weak var urlTextField: SearchTextField!
    @IBOutlet weak var usernameTextField: SearchTextField!
    @IBOutlet weak var passwordTextField: SearchTextField!
    
    var plexLoginUrl = "https://plex.tv/users/sign_in.xml"
    var urlArray:[String] = []
    var completion = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        urlTextField.delegate = self
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 10
        
        confirmButton.layer.masksToBounds = true
        confirmButton.layer.cornerRadius = confirmButton.bounds.height/2
        confirmButton.layer.borderWidth = 2
        confirmButton.layer.borderColor = UIColor(red: 182/255.0, green: 139/255.0, blue: 72/255.0, alpha: 1).cgColor
        
        urlTextField.setLeftPaddingPoints(10)
        urlTextField.setRightPaddingPoints(10)
        usernameTextField.setLeftPaddingPoints(10)
        usernameTextField.setRightPaddingPoints(10)
        passwordTextField.setLeftPaddingPoints(10)
        passwordTextField.setRightPaddingPoints(10)
        
        urlTextField.placeholder = "Server Url"
        usernameTextField.placeholder = "Username"
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        
        let defaults: UserDefaults = UserDefaults.standard
        urlTextField.text = defaults.string(forKey: "plex_url")
        usernameTextField.text = defaults.string(forKey: "plex_username")
        passwordTextField.text = defaults.string(forKey: "plex_password")
        
        if urlTextField.text!.count == 0 {
            urlTextField.text = "http://"
        }
    }
    func onLogin(){
        let loginString = String(format: "%@:%@", usernameTextField.text!, passwordTextField.text!)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
         
        AF.request(plexLoginUrl, method: .post, parameters: nil,encoding: JSONEncoding.default, headers: [
            "Authorization":"Basic \(base64LoginString)",
            "X-Plex-Client-Identifier": UIDevice.current.identifierForVendor!.uuidString,
        ]).responseString { response in
                switch response.result {
                case .success(let value):
//                    print(value)
                    self.getToken(value)
                case .failure(let error):
                    print(error.localizedDescription)
                    self.view.makeToast("Auth failed")
                }
        }
    }
    func getToken(_ str: String) {
        let xml = try! XML.parse(str)
        if let token = xml["user","authentication-token"].text {
            Globals.plex_token = token
            dismiss(animated: true, completion: completion)
        }
        else {
            view.makeToast("Auth failed")
        }
    }
    @IBAction func onClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func onConfirm(_ sender: Any) {
        onLogin()
                    let defaults: UserDefaults = UserDefaults.standard
        defaults.set(usernameTextField.text!, forKey: "plex_username")
        defaults.set(urlTextField.text!, forKey: "plex_url")
        defaults.set(passwordTextField.text!, forKey: "plex_password")
//        if urlTextField.text!.count < 8 {
//            return
//        }
//
//        Globals.serverTitle = titleTextField.text!
//        Globals.serverUrl = urlTextField.text!
//        if Globals.serverUrl.last! != "/" {
//            Globals.serverUrl = Globals.serverUrl + "/"
//        }
//        Globals.username = usernameTextField.text!
//        Globals.password = passwordTextField.text!
//        Globals.isNew = true
//
//        var ok = true
//        for url in urlArray {
//            if url == urlTextField.text {
//                ok = false
//                break
//            }
//        }
//
//        if ok {
//            let defaults: UserDefaults = UserDefaults.standard
//            defaults.set(urlArray.count + 1, forKey: "url_list_count")
//            defaults.set(urlTextField.text, forKey: "url\(urlArray.count)")
//        }
//        dismiss(animated: true, completion: completion)
    }
    
}
extension PlexLoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if(textField.isEqual(usernameTextField)) {
            animateViewMoving(up: true, moveValue: 40)
        } else if(textField.isEqual(passwordTextField)) {
            animateViewMoving(up: true, moveValue: 90)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if(textField.isEqual(usernameTextField)) {
            animateViewMoving(up: false, moveValue: 40)
        } else if(textField.isEqual(passwordTextField)) {
            animateViewMoving(up: false, moveValue: 90)
        }
        
        let defaults: UserDefaults = UserDefaults.standard
        
        switch textField {
        case urlTextField:
            defaults.set(urlTextField.text, forKey: "plex_url")
        case usernameTextField:
            defaults.set(usernameTextField.text, forKey: "plex_username")
        case passwordTextField:
            defaults.set(passwordTextField.text, forKey: "plex_password")
        default:
            break
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == urlTextField {
            usernameTextField.becomeFirstResponder()
        }
        else if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        }
        else if textField == passwordTextField {
            dismissKeyboard()
        }

        return true
    }
    // Lifting the view up
    func animateViewMoving (up: Bool, moveValue: CGFloat) {
        let movementDuration: TimeInterval = 0.3
        let movement: CGFloat = ( up ? -moveValue : moveValue)
        UIView.beginAnimations( "animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration )
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

