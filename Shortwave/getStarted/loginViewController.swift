//
//  loginViewController.swift
//  Syndeo
//
//  Created by Mobile World on 8/29/18.
//  Copyright © 2018 Mobile World. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class loginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var loginButton: UIButton!
//    @IBOutlet weak var registerButton: UIButton!
    
    @IBAction func onLogin(_ sender: Any) {
        if emailTextField.text == "" || passwordTextField.text == "" {
            alert(message: "Can not leave empty fields")
            return
        }
//        FirebaseApp.configure()

//        performSegue(withIdentifier: "loginToMain", sender: nil)
        let alertIndicator = UIAlertController(title: "Please Wait...", message: "\n\n", preferredStyle: UIAlertController.Style.alert)
        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.center = CGPoint(x: 139.5, y: 75.5)
        activityView.startAnimating()
        alertIndicator.view.addSubview(activityView)
        present(alertIndicator, animated: true, completion: nil)
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (_, error) in
            // ...
            alertIndicator.dismiss(animated: true, completion: nil)
            if(error == nil) {
                if (Auth.auth().currentUser?.isEmailVerified)! {
                    self.performSegue(withIdentifier: "loginToMain", sender: nil)
                }
                else {
                    Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
                        if error == nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) {
                                let alert = UIAlertController(title: "Login", message: "We sent verification link to your email. Please verify your account and try again.",
                                                              preferredStyle: UIAlertController.Style.alert)
                                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                        else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) {
                                let alert = UIAlertController(title: "Verification Error", message: error?.localizedDescription,
                                                              preferredStyle: UIAlertController.Style.alert)
                                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    })
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) {
                    let alert = UIAlertController(title: "Login Error", message: error?.localizedDescription,
                                                  preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                
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
    }

    override func viewDidAppear(_ animated: Bool) {
        let user = Auth.auth().currentUser
        if user != nil {
            print( user!.email! )
            self.performSegue(withIdentifier: "loginToMain", sender: nil)
        }
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
