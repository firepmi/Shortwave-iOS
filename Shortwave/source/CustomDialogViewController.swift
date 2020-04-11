//
//  CustomDialogViewController.swift
//  TV Escola Adult
//
//  Created by Mobile World on 10/31/18.
//  Copyright © 2018 Jenya Ivanova. All rights reserved.
//

import UIKit
import SearchTextField

class CustomDialogViewController: UIViewController {
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
        
    @IBOutlet weak var titleTextField: SearchTextField!
    @IBOutlet weak var urlTextField: SearchTextField!
    @IBOutlet weak var usernameTextField: SearchTextField!
    @IBOutlet weak var passwordTextField: SearchTextField!
    
    var urlArray:[String] = []
    var completion = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        titleTextField.delegate = self
        urlTextField.delegate = self
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 10
        
        confirmButton.layer.masksToBounds = true
        confirmButton.layer.cornerRadius = confirmButton.bounds.height/2
        confirmButton.layer.borderWidth = 2
        confirmButton.layer.borderColor = UIColor(red: 182/255.0, green: 139/255.0, blue: 72/255.0, alpha: 1).cgColor
        
        titleTextField.setLeftPaddingPoints(10)
        titleTextField.setRightPaddingPoints(10)
        urlTextField.setLeftPaddingPoints(10)
        urlTextField.setRightPaddingPoints(10)
        usernameTextField.setLeftPaddingPoints(10)
        usernameTextField.setRightPaddingPoints(10)
        passwordTextField.setLeftPaddingPoints(10)
        passwordTextField.setRightPaddingPoints(10)
        
        titleTextField.placeholder = "Server Title"
        urlTextField.placeholder = "Server Url"
        usernameTextField.placeholder = "Username (Optional)"
        passwordTextField.placeholder = "Password (Optional)"
        passwordTextField.isSecureTextEntry = true
        
        let defaults: UserDefaults = UserDefaults.standard
        let url_list_count = defaults.integer(forKey: "url_list_count")
        for i in 0 ..< url_list_count {
            urlArray.append(defaults.string(forKey: "url\(i)")!)
        }
        
        urlTextField.filterStrings(urlArray)
        
        titleTextField.text = defaults.string(forKey: "last_title")
        urlTextField.text = defaults.string(forKey: "last_url")
        usernameTextField.text = defaults.string(forKey: "last_username")
        passwordTextField.text = defaults.string(forKey: "last_password")
        
        if urlTextField.text!.count == 0 {
            urlTextField.text = "http://"
        }
    }
    
    @IBAction func onClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func onConfirm(_ sender: Any) {
        if urlTextField.text!.count < 8 {
            return
        }
        Globals.serverTitle = titleTextField.text!
        Globals.serverUrl = urlTextField.text!
        if Globals.serverUrl.last! != "/" {
            Globals.serverUrl = Globals.serverUrl + "/"
        }
        Globals.username = usernameTextField.text!
        Globals.password = passwordTextField.text!
        Globals.isNew = true
        
        var ok = true
        for url in urlArray {
            if url == urlTextField.text {
                ok = false
                break
            }
        }
        
        if ok {
            let defaults: UserDefaults = UserDefaults.standard
            defaults.set(urlArray.count + 1, forKey: "url_list_count")
            defaults.set(urlTextField.text, forKey: "url\(urlArray.count)")
        }
        dismiss(animated: true, completion: completion)
    }
    
}
extension CustomDialogViewController: UITextFieldDelegate {
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
        case titleTextField:
            defaults.set(titleTextField.text, forKey: "last_title")
        case urlTextField:
            defaults.set(urlTextField.text, forKey: "last_url")
        case usernameTextField:
            defaults.set(usernameTextField.text, forKey: "last_username")
        case passwordTextField:
            defaults.set(passwordTextField.text, forKey: "last_password")
        default:
            break
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(titleTextField) {
            urlTextField.becomeFirstResponder()
        }
        else if textField == urlTextField {
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
