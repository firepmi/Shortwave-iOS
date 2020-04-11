//
//  PlayerViewController.swift
//  BookPlayer
//
//  Created by Gianni Carlo on 7/5/16.
//  Copyright © 2016 Tortuga Power. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import StoreKit
import AVKit

class PlayerViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var closeButtonTop: NSLayoutConstraint!
    @IBOutlet private weak var bottomToolbar: UIToolbar!
    @IBOutlet private weak var speedButton: UIBarButtonItem!
    @IBOutlet private weak var sleepButton: UIBarButtonItem!
    @IBOutlet private var sleepLabel: UIBarButtonItem!
    @IBOutlet private weak var chaptersButton: UIBarButtonItem!
    @IBOutlet private weak var moreButton: UIBarButtonItem!
    @IBOutlet private weak var backgroundImage: UIImageView!
    
    var currentBook: Book!
    private let timerIcon: UIImage = UIImage(named: "toolbarIconTimer")!
    private var pan: UIPanGestureRecognizer!
    
    private weak var controlsViewController: PlayerControlsViewController?
    private weak var metaViewController: PlayerMetaViewController?
    
    let darknessThreshold: CGFloat = 0.2
    
    // MARK: - Lifecycle
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? PlayerControlsViewController {
            self.controlsViewController = viewController
        }
        
        if let viewController = segue.destination as? PlayerMetaViewController {
            self.metaViewController = viewController
        }
        
        if let navigationController = segue.destination as? UINavigationController,
            let viewController = navigationController.viewControllers.first as? ChaptersViewController,
            let currentChapter = self.currentBook.currentChapter {
            
            viewController.chapters = self.currentBook.chapters?.array as? [Chapter]
            viewController.currentChapter = currentChapter
            viewController.didSelectChapter = { selectedChapter in
                // Don't set the chapter, set the new time which will set the chapter in didSet
                // Add a fraction of a second to make sure we start after the end of the previous chapter
                PlayerManager.shared.jumpTo(selectedChapter.start + 0.01)
            }
        }
        
    }
    
    // Prevents dragging the view down from changing the safeAreaInsets.top
    // Note: I'm pretty sure there is a better solution for this that I haven't found yet - @pichfl
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11, *) {
            super.viewSafeAreaInsetsDidChange()
            
            let window = UIApplication.shared.windows[0]
            let insets: UIEdgeInsets = window.safeAreaInsets
            
            self.closeButtonTop.constant = self.view.safeAreaInsets.top == 0.0 ? insets.top : 0
        }
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.post(name: .playerPresented, object: nil, userInfo: nil)
        
        super.viewDidLoad()
        
        self.setupView(book: self.currentBook!)
        
        // Make toolbar transparent
        self.bottomToolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        self.bottomToolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        self.sleepLabel.title = ""
        self.speedButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .semibold)], for: .normal)
        
        // Observers
        NotificationCenter.default.addObserver(self, selector: #selector(self.requestReview), name: .requestReview, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.requestReview), name: .bookEnd, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookChange(_:)), name: .bookChange, object: nil)
        
        // Gestures
        self.pan = UIPanGestureRecognizer(target: self, action: #selector(panAction))
        self.pan.delegate = self
        self.pan.maximumNumberOfTouches = 1
        self.pan.cancelsTouchesInView = true
        
        self.view.addGestureRecognizer(self.pan)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.controlsViewController?.showPlayPauseButton(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.autolockDisabled.rawValue) {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func setupView(book currentBook: Book) {
        self.metaViewController?.book = currentBook
        self.controlsViewController?.book = currentBook
        
        self.speedButton.title = self.formatSpeed(PlayerManager.shared.speed)
        self.speedButton.accessibilityLabel = String(describing: self.formatSpeed(PlayerManager.shared.speed) + " speed")
        
        self.view.backgroundColor = currentBook.artworkColors.background
        self.bottomToolbar.tintColor = currentBook.artworkColors.secondary
        self.closeButton.tintColor = currentBook.artworkColors.secondary
        
        self.updateToolbar()
        
        if currentBook.usesDefaultArtwork {
            self.backgroundImage.isHidden = true
            
            return
        }
        
        let blur = UIBlurEffect(style: currentBook.artworkColors.displayOnDark ? UIBlurEffect.Style.dark : UIBlurEffect.Style.light)
        let blurView = UIVisualEffectView(effect: blur)
        
        blurView.frame = self.view.bounds
        
        self.backgroundImage.addSubview(blurView)
        self.backgroundImage.image = currentBook.artwork
        
        // Apply the blurred view in relation to the brightness and luminance of the background color.
        // This makes darker backgrounds stay interesting
        self.backgroundImage.alpha = 0.1 + min((1 - currentBook.artworkColors.background.luminance) * (1 - currentBook.artworkColors.background.brightness), 0.7)
        
        // Solution thanks to https://forums.developer.apple.com/thread/63166#180445
        self.modalPresentationCapturesStatusBarAppearance = true
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func updateToolbar(_ showTimerLabel: Bool = false, animated: Bool = false) {
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        var items: [UIBarButtonItem] = [
            self.speedButton,
            spacer,
            self.sleepButton
        ]
        
        if showTimerLabel {
            items.append(self.sleepLabel)
        }
        
        if currentBook.hasChapters {
            items.append(spacer)
            items.append(self.chaptersButton)
        }
        
        if #available(iOS 11, *) {
            let avRoutePickerBarButtonItem = UIBarButtonItem(
                customView: AVRoutePickerView(
                    frame: CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)
                )
            )
            
            avRoutePickerBarButtonItem.isAccessibilityElement = true
            avRoutePickerBarButtonItem.accessibilityLabel = "Audio Source"
            items.append(spacer)
            items.append(avRoutePickerBarButtonItem)
        }
        
        items.append(spacer)
        items.append(self.moreButton)
        
        self.bottomToolbar.setItems(items, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return currentBook.artworkColors.displayOnDark ? UIStatusBarStyle.lightContent : UIStatusBarStyle.default
    }
    
    // MARK: - Interface actions
    
    @IBAction func dismissPlayer() {
        self.dismiss(animated: true, completion: nil)
        
        NotificationCenter.default.post(name: .playerDismissed, object: nil, userInfo: nil)
    }
    
    // MARK: - Toolbar actions
    
    @IBAction func setSpeed() {
        var actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        }
        
        let speedOptions: [Float] = [2.5, 2, 1.75, 1.5, 1.25, 1, 0.75]
        
        for speed in speedOptions {
            if speed == PlayerManager.shared.speed {
                actionSheet.addAction(UIAlertAction(title: "\u{00A0} \(speed) ✓", style: .default, handler: nil))
            } else {
                actionSheet.addAction(UIAlertAction(title: "\(speed)", style: .default, handler: { _ in
                    PlayerManager.shared.speed = speed
                    
                    self.speedButton.title = self.formatSpeed(speed)
                }))
            }
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func setSleepTimer() {
        let actionSheet = SleepTimer.shared.actionSheet(
            onStart: {
                self.updateToolbar(true, animated: true)
        },
            onProgress: { (timeLeft: Double) -> Void in
                self.sleepLabel.title = SleepTimer.shared.durationFormatter.string(from: timeLeft)
                if let timeLeft = SleepTimer.shared.durationFormatter.string(from: timeLeft) {
                    self.sleepLabel.accessibilityLabel = String(describing: timeLeft + " remaining until sleep")
                }
        },
            onEnd: { (_ cancelled: Bool) -> Void in
                if !cancelled {
                    PlayerManager.shared.pause()
                }
                
                self.sleepLabel.title = ""
                self.updateToolbar(false, animated: true)
        }
        )
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func showMore() {
        guard PlayerManager.shared.isLoaded else {
            return
        }
        
        var actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        }
        actionSheet.addAction(UIAlertAction(title: "Jump To Start", style: .default, handler: { _ in
            PlayerManager.shared.pause()
            PlayerManager.shared.jumpTo(0.0)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Mark as Finished", style: .default, handler: { _ in
            PlayerManager.shared.pause()
            // Player resets back to 0.0 if currentTime is set to player's duration
            PlayerManager.shared.jumpTo(0.1, fromEnd: true)
            
            self.requestReview()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - Other Methods
    
    @objc func requestReview() {
        // don't do anything if flag isn't true
        guard UserDefaults.standard.bool(forKey: "ask_review") else {
            return
        }
        
        // request for review
        if #available(iOS 10.3, *), UIApplication.shared.applicationState == .active {
            #if RELEASE
            SKStoreReviewController.requestReview()
            #endif
            
            UserDefaults.standard.set(false, forKey: "ask_review")
        }
    }
    
    @objc func bookChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let books = userInfo["books"] as? [Book],
            let book = books.first else {
                return
        }
        
        self.currentBook = book
        
        self.setupView(book: book)
    }
    
    // MARK: - Gesture recognizers
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.pan {
            return limitPanAngle(self.pan, degreesOfFreedom: 45.0, comparator: .greaterThan)
        }
        
        return true
    }
    
    private func updatePresentedViewForTranslation(_ yTranslation: CGFloat) {
        let translation: CGFloat = rubberBandDistance(yTranslation, dimension: self.view.frame.height, constant: 0.55)
        
        self.view?.transform = CGAffineTransform(translationX: 0, y: max(translation, 0.0))
    }
    
    @objc private func panAction(gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.isEqual(self.pan) else {
            return
        }
        
        switch gestureRecognizer.state {
        case .began:
            gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: self.view.superview)
            
        case .changed:
            let translation = gestureRecognizer.translation(in: self.view)
            
            self.updatePresentedViewForTranslation(translation.y)
            
        case .ended, .cancelled, .failed:
            let dismissThreshold: CGFloat = 44.0 * UIScreen.main.nativeScale
            let translation = gestureRecognizer.translation(in: self.view)
            
            if translation.y > dismissThreshold {
                self.dismissPlayer()
                
                return
            }
            
            UIView.animate(
                withDuration: 0.3,
                delay: 0.0,
                usingSpringWithDamping: 0.75,
                initialSpringVelocity: 1.5,
                options: .preferredFramesPerSecond60,
                animations: {
                    self.view?.transform = .identity
            }
            )
            
        default: break
        }
    }
    override func accessibilityPerformEscape() -> Bool {
        dismissPlayer()
        return true
    }
}
