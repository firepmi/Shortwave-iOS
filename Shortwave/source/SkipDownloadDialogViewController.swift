//
//  SkipDownloadDialogViewController.swift
//  Shortwave
//
//  Created by mobileworld on 12/14/19.
//  Copyright © 2019 Mobile World. All rights reserved.
//

import UIKit
import SearchTextField

class SkipDownloadDialogViewController: UIViewController {
    
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var checkboxImageView: UIImageView!
    
    var isAppliedForAll = false
    weak var delegate: SkipDialogDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        
        skipButton.layer.masksToBounds = true
        skipButton.layer.cornerRadius = 10
        skipButton.layer.masksToBounds = true
        skipButton.layer.cornerRadius = skipButton.bounds.height/2
        skipButton.layer.borderWidth = 2
        skipButton.layer.borderColor = UIColor(red: 182/255.0, green: 139/255.0, blue: 72/255.0, alpha: 1).cgColor
        
        downloadButton.layer.masksToBounds = true
        downloadButton.layer.cornerRadius = 10
        downloadButton.layer.masksToBounds = true
        downloadButton.layer.cornerRadius = downloadButton.bounds.height/2
        downloadButton.layer.borderWidth = 2
        downloadButton.layer.borderColor = UIColor(red: 182/255.0, green: 139/255.0, blue: 72/255.0, alpha: 1).cgColor
    }
    
    @IBAction func onClose(_ sender: Any) {
        let alert = UIAlertController(title: "Cancel Downloading", message: "Do you want cancel downlod books?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) in
            self.dismiss(animated: true) {
                self.delegate?.onClosedDialog?()
            }
        }))
        alert.addAction(UIAlertAction(title: "No, Keep downloading files", style: .cancel, handler: { (UIAlertAction) in
            
        }))
        self.present(alert, animated: true)        
    }
    @IBAction func onSkip(_ sender: Any) {
        dismiss(animated: true) {
            self.delegate?.onCompletedSkipDialog?(isAppliedForAll: self.isAppliedForAll, isSkiped: true)
        }
    }
    
    @IBAction func onDownload(_ sender: Any) {
        dismiss(animated: true) {
            self.delegate?.onCompletedSkipDialog?(isAppliedForAll: self.isAppliedForAll, isSkiped: false)
        }
    }
    @IBAction func onApplyAll(_ sender: Any) {
        isAppliedForAll = !isAppliedForAll
        if isAppliedForAll {
            checkboxImageView.image = UIImage(named: "btn_check_on.png")
        }
        else {
            checkboxImageView.image = UIImage(named: "btn_check_off.png")
        }
    }
}
@objc
protocol SkipDialogDelegate {
    @objc optional func onCompletedSkipDialog(isAppliedForAll:Bool, isSkiped:Bool)
    @objc optional func onClosedDialog()
}
