//
//  ForgotPasswordViewController.swift
//  Shortwave
//
//  Created by mobileworld on 1/16/20.
//  Copyright © 2020 Mobile World. All rights reserved.
//


import UIKit
import Firebase
import FirebaseAuth

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailTextField: UITextField!
   
    @IBOutlet weak var resetButton: UIButton!
//    @IBOutlet weak var registerButton: UIButton!
    
    @IBAction func onResetPassword(_ sender: Any) {
        if emailTextField.text == "" {
            alert(message: "Email can not leave empty")
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
        
        Auth.auth().sendPasswordReset(withEmail: emailTextField.text!) { error in
            alertIndicator.dismiss(animated: true) {
                if error != nil {
                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription,
                                                  preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    let alert = UIAlertController(title: "Reset Password", message: "A password reset link was sent. Click the link in the email to create a new password.",
                                                  preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                        self.dismiss(animated: true, completion: nil)
                    }))
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
    @IBAction func onBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(loginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        emailTextField.delegate = self
        emailTextField.layer.masksToBounds = true
        emailTextField.layer.cornerRadius = 10
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor.white.cgColor
        emailTextField.setLeftPaddingPoints(10)
        emailTextField.setRightPaddingPoints(10)

        emailTextField.textColor = UIColor.white
 
        resetButton.layer.masksToBounds = true
        resetButton.layer.cornerRadius = 10
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if textField == emailTextField {
//            passwordTextField.becomeFirstResponder()
//        }
//        else if textField == passwordTextField {
//            onLogin(textField)
//        }
//        return true
//    }
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        if(textField.isEqual(emailTextField)) {
//            animateViewMoving(up: true, moveValue: 40)
//        } else {
//            animateViewMoving(up: true, moveValue: 60)
//        }
//
//    }
//
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        if(textField.isEqual(emailTextField)) {
//            animateViewMoving(up: false, moveValue: 40)
//        } else {
//            animateViewMoving(up: false, moveValue: 60)
//        }
//    }

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

