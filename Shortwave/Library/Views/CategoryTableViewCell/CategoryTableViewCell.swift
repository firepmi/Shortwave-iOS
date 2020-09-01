//
//  CategoryTableViewCell.swift
//  Shortwave
//
//  Created by mobileworld on 6/5/20.
//  Copyright © 2020 Mobile World. All rights reserved.
//

import UIKit


protocol CategoryTableViewCellDelegate {
    func onCheckBtnClicked(cell:UITableViewCell)
}

class CategoryTableViewCell: UITableViewCell {
    var delegate : CategoryTableViewCellDelegate!
    @IBOutlet private weak var artworkView: BPArtworkView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var progressTrailing: NSLayoutConstraint!
    @IBOutlet private weak var progressView: ItemProgress!
    @IBOutlet private weak var artworkButton: UIButton!
    @IBOutlet weak var artworkWidth: NSLayoutConstraint!
    @IBOutlet weak var artworkHeight: NSLayoutConstraint!
    @IBOutlet weak var itemCollectionView: ItemCollectionView!
    @IBOutlet weak var sortButton: UIButton!
    
    var sortBy: String = "Title"
    var onArtworkTap: (() -> Void)?

    var artwork: UIImage? {
        get {
            return self.artworkView.image
        }
        set {
            self.artworkView.image = newValue

            let ratio = self.artworkView.imageRatio

            self.artworkHeight.constant = ratio > 1 ? 50.0 / ratio : 50.0
            self.artworkWidth.constant = ratio < 1 ? 50.0 * ratio : 50.0
        }
    }

    var title: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    var subtitle: String? {
        get {
            return self.subtitleLabel.text
        }
        set {
            self.subtitleLabel.text = newValue
        }
    }

    var progress: Double {
        get {
            return self.progressView.value
        }
        set {
            self.progressView.value = newValue.isNaN
                ? 0.0
                : newValue
            setAccessibilityLabels()
        }
    }

    var type: BookCellType = .book {
        didSet {
            self.accessoryType = .none
//            switch self.type {
//                case .file:
//                    self.accessoryType = .none
//
//                    self.progressTrailing.constant = 11.0
//                case .playlist:
//                    self.accessoryType = .disclosureIndicator
//
//                    self.progressTrailing.constant = -5.0
//                default:
//                    self.accessoryType = .none
//
//                    self.progressTrailing.constant = 29.0 // Disclosure indicator offset
//            }
        }
    }
    
    

    var playbackState: PlaybackState = PlaybackState.stopped {
        didSet {
            UIView.animate(withDuration: 0.1, animations: {
                switch self.playbackState {
                    case .playing:
                        self.artworkButton.backgroundColor = UIColor.tintColor.withAlpha(newAlpha: 0.3)
                        self.titleLabel.textColor = UIColor.tintColor
                        self.progressView.pieColor = UIColor.tintColor
                    case .paused:
                        self.artworkButton.backgroundColor = UIColor.tintColor.withAlpha(newAlpha: 0.3)
                        self.titleLabel.textColor = UIColor.tintColor
                        self.progressView.pieColor = UIColor.tintColor
                    default:
                        self.artworkButton.backgroundColor = UIColor.clear
                        self.titleLabel.textColor = UIColor.textColor
                        self.progressView.pieColor = UIColor(hex: "8F8E94")
                }
            })
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.setup()
    }

    private func setup() {
        self.accessoryType = .none
        self.selectionStyle = .none
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        self.artworkButton.layer.cornerRadius = 4.0
        self.artworkButton.layer.masksToBounds = true
    }

    @IBAction func checkBtnClicked(_ sender: Any) {
        guard self.delegate != nil else {
            return
        }
        self.delegate.onCheckBtnClicked(cell: self)
    }
    
    @IBAction func onSortButtonClicked(_ sender: Any) {
        let pickerData = [
                ["value": "Title", "display": "Title"],
                ["value": "Author", "display": "Author"]
            ]
        PickerDialog().show(title: "Sort By", options: pickerData, selected: "Title") {
            (value) -> Void in
            self.sortBy = value
            self.sortButton.setTitle("Sort by: \(self.sortBy)", for: .normal)
            self.itemCollectionView.sort(by: value)
        }
    }
    @IBAction func artworkButtonTapped(_ sender: Any) {
        self.onArtworkTap?()
    }
}

// MARK: - Voiceover
extension CategoryTableViewCell {
    private func setAccessibilityLabels() {
        let voiceOverService = VoiceOverService()
        isAccessibilityElement = true
        accessibilityLabel = voiceOverService.bookCellView(type: type,
                                                           title: title,
                                                           subtitle: subtitle,
                                                           progress: progress)
    }
}

