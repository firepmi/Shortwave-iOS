//
//  DownloadBooksViewController.swift
//  Shortwave
//
//  Created by mobileworld on 11/22/19.
//  Copyright © 2019 Mobile World. All rights reserved.
//

import UIKit
import AMProgressBar
import Alamofire

class DownloadBooksViewController: UIViewController {
    
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalProgressBar: AMProgressBar!
    
    var downloadIndex = -1
    var totalSize:CGFloat = 0
    var totalSizeStr = "0"
    var totalProgress:CGFloat = 0
    var isAppliedForAll = false
    var isSkip = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Download")
        // Do any additional setup after loading the view, typically from a nib.
        navigationController?.setNavigationBarHidden(false, animated:false)
        tableView.tableFooterView = UIView(frame: CGRect.zero)
         //Create back button of type custom
//        let myBackButton:UIButton = UIButton.init(type: .custom)
//        myBackButton.addTarget(self, action: #selector(onBack(sender:)), for: .touchUpInside)
//        myBackButton.setTitle("< Back", for: .normal)
//        myBackButton.setTitleColor(UIColor.init(hex: "#38C6F4"), for: .normal)
//        myBackButton.sizeToFit()

        //Add back button to navigationBar as left Button

//        let myCustomBackButtonItem:UIBarButtonItem = UIBarButtonItem(customView: myBackButton)
//        self.navigationItem.leftBarButtonItem  = myCustomBackButtonItem
        
        NotificationCenter.default.addObserver(self, selector: #selector(onChangedDownloadQueue(_:)), name: .didChangeDownloadQueue, object: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
//        if Globals.downloadBookArray.count == 0 {
////            let alert = UIAlertController(title: "No books", message: "No books in download queue", preferredStyle: .alert)
////            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (UIAlertAction) in
////                self.tableView.reloadData()
////                self.navigationController?.popViewController(animated: true)
////            }))
////            self.present(alert, animated: true)
//        }
//        else {
//            tableView.reloadData()
//            totalProgressBar.configureView()
//            Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(onRefeshState), userInfo: nil, repeats: true)
//        }
        tableView.reloadData()
        totalProgressBar.configureView()
        Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(onRefeshState), userInfo: nil, repeats: true)
    }
    @objc func onRefeshState(){
        if Globals.downloadBookArray.count != tableView.numberOfRows(inSection: 0) {
            tableView.reloadData()
        }
        totalSize = 0
        if Globals.downloadBookArray.count > 0 {
            for i in 1 ..< Globals.downloadBookArray.count {
                totalSize = totalSize + CGFloat(Globals.downloadBookArray[i].size)
            }
            totalSize = totalSize + CGFloat(Globals.downloadBookArray[0].size) * ( 1 - Globals.queueProgress )
            let fmt = NumberFormatter()
            fmt.numberStyle = .decimal
            fmt.groupingSeparator = ","
            totalSizeStr = fmt.string(from: NSNumber(value: Int(totalSize)))!
            descLabel.text = "\(Globals.downloadBookArray.count) Books(\(totalSizeStr)MB) on download queue"
            totalProgressBar.setProgress(progress: Globals.queueProgress, animated: true)
        }
    }
    @objc func onChangedDownloadQueue(_ notification:Notification){
        if Globals.downloadBookArray.count == 0 {
            completeDownload()
        }
        else {
            tableView.reloadData()
        }
    }
    func onUpdateInfo(){
//        if updatedWeek == 0 {
//            return
//        }
//        let user = Auth.auth().currentUser
//        self.ref.child("products").child((user?.uid)!).child("weekly")
//            .child("week\(updatedWeek)").child("product")
//            .child("audio\(updatedAudioID)").setValue(updatedId)
//        self.ref.child("products").child((user?.uid)!).child("weekly")
//            .child("week\(updatedWeek)").child("start_date")
//            .setValue(updatedDate)
//        self.ref.child("products").child((user?.uid)!).child("weekly")
//            .child("week\(updatedWeek)").child("total_value")
//            .setValue(updatedSize)
    }
    func completeDownload(){
        onRefeshState()
        view.makeToast("Completed download")
//        let alert = UIAlertController(title: "Download books", message: "Completed download", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (UIAlertAction) in
//            self.tableView.reloadData()
////            self.navigationController?.popViewController(animated: true)
//        }))
//        self.present(alert, animated: true)
    }
//    @objc func onBack(sender:UIBarButtonItem){
//        onCancelDownload()
//    }
//    func onCancelDownload() {
//        let alert = UIAlertController(title: "Cancel Downloading", message: "Do you want cancel downlod books?", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) in
//            self.downloadIndex = -1
//            if self.downloadRequest != nil {
//                self.downloadRequest.cancel()
//            }
//            self.navigationController?.popViewController(animated: true)
//        }))
//        alert.addAction(UIAlertAction(title: "No, Keep downloading files", style: .cancel, handler: { (UIAlertAction) in
//
//        }))
//        self.present(alert, animated: true)
//    }
}
extension DownloadBooksViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Globals.downloadBookArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID:NSString = "bookCell";
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellID as String)!
        cell.selectionStyle = .none
        
        let titleLabel = cell.viewWithTag(100) as! UILabel
        titleLabel.text = Globals.downloadBookArray[indexPath.row].name
        
        let sizeLabel = cell.viewWithTag(101) as! UILabel
        sizeLabel.text = "\(Globals.downloadBookArray[indexPath.row].size)MB"
                
        let progressBar = cell.viewWithTag(102)
        if indexPath.row == 0 {
            progressBar?.frame = CGRect.init(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height)
        }
        else {
            progressBar?.frame = CGRect.init(x: 0, y: 0, width: 0, height: cell.frame.height)
        }
        let progressLabel = cell.viewWithTag(103) as! UILabel
        progressLabel.text = "\(Int(Globals.downloadBookArray[indexPath.row].progress*100))%"
                
        return cell
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        if editActionsForRowAt.row == 0 {
            return []
        }
        let remove = UITableViewRowAction(style: .normal, title: "Remove") { action, index in
            Globals.downloadBookArray.remove(at: editActionsForRowAt.row)
            NotificationCenter.default.post(name: .didChangeDownloadQueue, object: nil)
        }
        remove.backgroundColor = .lightGray
    
        return [remove]
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
extension Notification.Name {
    static let didChangeDownloadQueue = Notification.Name("didChangeDownloadQueue")
}
    /*
extension DownloadBooksViewController: SkipDialogDelegate {
    func onCompletedSkipDialog(isAppliedForAll: Bool, isSkiped: Bool) {
        self.isAppliedForAll = isAppliedForAll
        self.isSkip = isSkiped
        if isSkiped {
            onSkip()
        }
        else {
            onMakeDownloadRequest()
        }
    }
    
    func onClosedDialog() {
//        onCancelDownload()
        self.downloadIndex = -1
        if self.downloadRequest != nil {
            self.downloadRequest.cancel()
        }
        self.navigationController?.popViewController(animated: true)
    }
}
*/
