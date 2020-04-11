//
//  AboutUsViewController.swift
//  Locally
//
//  Created by Mobile World on 6/10/19.
//  Copyright © 2019 TheLastSummer. All rights reserved.
//

import UIKit
import PDFKit

class PrivacyViewController: ViewController {
    @IBOutlet weak var pdfView: PDFView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        pdfView.autoScales = true
        let fileURL = Bundle.main.url(forResource: "termsofservice", withExtension: "pdf")
        pdfView.document = PDFDocument(url: fileURL!)
    }
    @IBAction func onBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

