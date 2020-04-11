//
//  registerViewController.swift
//  Syndeo
//
//  Created by Mobile World on 9/20/18.
//  Copyright © 2018 Mobile World. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class registerViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var fullnameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var checkButton: UIButton!
    
    var alertIndicator: UIAlertController!
    var ref: DatabaseReference!
    var checked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmTextField.delegate = self
        fullnameTextField.delegate = self
        usernameTextField.delegate = self

        loginButton.layer.masksToBounds = true
        loginButton.layer.cornerRadius = 10
//        loginButton.applyGradient(
//            withColours:
//            [
//                UIColor(red: 8/255.0, green: 224/255.0, blue: 190/255.0, alpha: 1),
//                UIColor(red: 91/255.0, green: 168/255.0, blue: 179/255.0, alpha: 1)
//            ], gradientOrientation: .topLeftBottomRight)

        registerButton.layer.masksToBounds = true
        registerButton.layer.cornerRadius = 10
//        registerButton.applyGradient(
//            withColours:
//            [
//                UIColor(red: 151/255.0, green: 93/255.0, blue: 170/255.0, alpha: 1),
//                UIColor(red: 201/255.0, green: 81/255.0, blue: 194/255.0, alpha: 1)
//            ], gradientOrientation: .topLeftBottomRight)

        emailTextField.layer.masksToBounds = true
        emailTextField.layer.cornerRadius = 10
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor.white.cgColor
        emailTextField.setLeftPaddingPoints(10)
        emailTextField.setRightPaddingPoints(10)

//        phoneTextField.layer.masksToBounds = true
//        phoneTextField.layer.cornerRadius = 10
//        phoneTextField.layer.borderWidth = 1
//        phoneTextField.layer.borderColor = UIColor.white.cgColor
//        phoneTextField.setLeftPaddingPoints(10)
//        phoneTextField.setRightPaddingPoints(10)

        passwordTextField.layer.masksToBounds = true
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.white.cgColor
        passwordTextField.setLeftPaddingPoints(10)
        passwordTextField.setRightPaddingPoints(10)

        confirmTextField.layer.masksToBounds = true
        confirmTextField.layer.cornerRadius = 10
        confirmTextField.layer.borderWidth = 1
        confirmTextField.layer.borderColor = UIColor.white.cgColor
        confirmTextField.setLeftPaddingPoints(10)
        confirmTextField.setRightPaddingPoints(10)

        usernameTextField.layer.masksToBounds = true
        usernameTextField.layer.cornerRadius = 10
        usernameTextField.layer.borderWidth = 1
        usernameTextField.layer.borderColor = UIColor.white.cgColor
        usernameTextField.setLeftPaddingPoints(10)
        usernameTextField.setRightPaddingPoints(10)

        fullnameTextField.layer.masksToBounds = true
        fullnameTextField.layer.cornerRadius = 10
        fullnameTextField.layer.borderWidth = 1
        fullnameTextField.layer.borderColor = UIColor.white.cgColor
        fullnameTextField.setLeftPaddingPoints(10)
        fullnameTextField.setRightPaddingPoints(10)
        
        
        checkButton.setImage(UIImage(named: "btn_check_off.png"), for: .normal)
    }

    @IBAction func onRegister(_ sender: Any) {
        if !checked {
            let alertController = UIAlertController(title: "Terms of Service", message: "You should agree the terms of service", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
            return
        }
        if emailTextField.text == "" || passwordTextField.text == "" || fullnameTextField.text == "" ||
            usernameTextField.text == "" || confirmTextField.text == ""{
            alert(message: "Can not leave empty fields")
            return
        } else if passwordTextField.text != confirmTextField.text {
            alert(message: "Password does not match")
            return
        }

//        dismiss(animated: true, completion: nil)
        alertIndicator = UIAlertController(title: "Please Wait...", message: "\n\n", preferredStyle: UIAlertController.Style.alert)
        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.center = CGPoint(x: 139.5, y: 75.5)
        activityView.startAnimating()
        alertIndicator.view.addSubview(activityView)
        present(alertIndicator, animated: true, completion: nil)
        
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (_, error) in
            if error == nil {
                print("You have successfully signed up")
                self.saveData()
//                self.performSegue(withIdentifier: "SignupToTerms", sender: nil)
                self.dismiss(animated: true, completion: nil)

            } else {
                self.alertIndicator.dismiss(animated: true, completion: nil)
                let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)

                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(defaultAction)

                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
   
    func saveData() {
        alertIndicator.dismiss(animated: true, completion: nil)
        ref = Database.database().reference()
        let user = Auth.auth().currentUser
        ref.child("profile").child((user?.uid)!).child("full_name")
            .setValue(fullnameTextField.text)
        ref.child("profile").child((user?.uid)!).child("email")
            .setValue(emailTextField.text)
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        ref.child("products").child((user?.uid)!).child("purchased_date")
            .setValue(dateFormatter.string(from: date))
    }
    func alert(message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            let alert = UIAlertController(title: "Register", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (_) in

            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func alertSucess() {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            let alert = UIAlertController(title: "Register", message: "Your Account is successfully registered", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if(textField.isEqual(passwordTextField)) {
            animateViewMoving(up: true, moveValue: 0)
        } else if(textField.isEqual(confirmTextField)) {
            animateViewMoving(up: true, moveValue: 90)
        }

    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if(textField.isEqual(passwordTextField)) {
            animateViewMoving(up: false, moveValue: 0)
        } else if(textField.isEqual(confirmTextField)) {
            animateViewMoving(up: false, moveValue: 80)
        }

    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(confirmTextField) {
            onRegister(self)
            return false
        }
        else if textField == fullnameTextField {
            usernameTextField.becomeFirstResponder()
        }
        else if textField == usernameTextField {
            emailTextField.becomeFirstResponder()
        }
        else if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }
        else if textField == passwordTextField {
            confirmTextField.becomeFirstResponder()
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
    @IBAction func onBackToLogin(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onAgreeTerms(_ sender: Any) {
        if checked {
            checkButton.setImage(UIImage(named: "btn_check_off.png"), for: .normal)
        }
        else {
            checkButton.setImage(UIImage(named: "btn_check_on.png"), for: .normal)
        }
        checked = !checked
    }
    @IBAction func onGoToTerms(_ sender: Any) {
    }
}
