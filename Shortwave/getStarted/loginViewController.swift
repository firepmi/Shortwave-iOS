//
//  loginViewController.swift
//  Syndeo
//
//  Created by Mobile World on 8/29/18.
//  Copyright © 2018 Mobile World. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class loginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    let defaults: UserDefaults = UserDefaults.standard
    
    @IBAction func onLogin(_ sender: Any) {
        if emailTextField.text == "" || passwordTextField.text == "" {
            alert(message: "Can not leave empty fields")
            return
        }

        let alertIndicator = UIAlertController(title: "Please Wait...", message: "\n\n", preferredStyle: UIAlertController.Style.alert)
        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.center = CGPoint(x: 139.5, y: 75.5)
        activityView.startAnimating()
        alertIndicator.view.addSubview(activityView)
        present(alertIndicator, animated: true, completion: nil)
        defaults.set(emailTextField.text, forKey: "email")
        let loginUrl = Globals.adminUrl + "/api/login"
        Alamofire.request(loginUrl, method: .post, parameters: ["email": emailTextField.text!, "password":passwordTextField.text!],encoding: JSONEncoding.default, headers: nil).responseJSON { response in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    alertIndicator.dismiss(animated: false, completion: nil)
                })
                                        
                switch response.result {
                case .success(_):
                    if let result = response.result.value {
                        let json = JSON(result)
                        if json["success"].boolValue {
                            Globals.token = json["token"].stringValue
                            self.defaults.set(self.emailTextField.text, forKey: "email")
                            self.defaults.set(Globals.token, forKey: "token")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                self.performSegue(withIdentifier: "loginToMain", sender: nil)
                            })
                            
                        }
                        else {
                            self.alert(message: json["message"].stringValue)
                        }
                    }
                    else {
                        self.alert(message: "Loading Data failure!")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.alert(message: "Loading Data failure!")
                }
        }
    }
    func alert(message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            let alert = UIAlertController(title: "Login Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (_) in

            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    @IBAction func onRegister(_ sender: Any) {
        self.performSegue(withIdentifier: "toRegister", sender: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(loginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        emailTextField.delegate = self
        passwordTextField.delegate = self

        emailTextField.layer.masksToBounds = true
        emailTextField.layer.cornerRadius = 10
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor.white.cgColor
        emailTextField.setLeftPaddingPoints(10)
        emailTextField.setRightPaddingPoints(10)

        passwordTextField.layer.masksToBounds = true
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.white.cgColor
        passwordTextField.setLeftPaddingPoints(10)
        passwordTextField.setRightPaddingPoints(10)

        emailTextField.textColor = UIColor.white
 
        passwordTextField.textColor = UIColor.white

        loginButton.layer.masksToBounds = true
        loginButton.layer.cornerRadius = 10
        
        Globals.deviceID = UIDevice.current.identifierForVendor!.uuidString
    }

    override func viewDidAppear(_ animated: Bool) {
        self.performSegue(withIdentifier: "loginToMain", sender: nil)
//        
//        if let token = defaults.string(forKey: "token") {
//            if token != "" {
//                Globals.token = token
//                Globals.email = defaults.string(forKey: "email")!
//                self.performSegue(withIdentifier: "loginToMain", sender: nil)
//            }
//        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }
        else if textField == passwordTextField {
            onLogin(textField)
        }
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if(textField.isEqual(emailTextField)) {
            animateViewMoving(up: true, moveValue: 40)
        } else {
            animateViewMoving(up: true, moveValue: 60)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if(textField.isEqual(emailTextField)) {
            animateViewMoving(up: false, moveValue: 40)
        } else {
            animateViewMoving(up: false, moveValue: 60)
        }

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
