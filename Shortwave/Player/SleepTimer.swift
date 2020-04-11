//
//  SleepTimerManager.swift
//  BookPlayer
//
//  Created by Florian Pichler on 30.03.18.
//  Copyright © 2018 Florian Pichler.
//

import UIKit
import Foundation

typealias SleepTimerStart = () -> Void
typealias SleepTimerProgress = (Double) -> Void
typealias SleepTimerEnd = (_ cancelled: Bool) -> Void

final class SleepTimer {
    static let shared = SleepTimer()

    let durationFormatter: DateComponentsFormatter = DateComponentsFormatter()

    private var timer: Timer?
    private var onStart: SleepTimerStart?
    private var onProgress: SleepTimerProgress?
    private var onEnd: SleepTimerEnd?

    private let defaultMessage: String = "Pause playback"
    private var alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    private var timeLeft: TimeInterval = 0.0
    private let intervals: [TimeInterval] = [
        300.0,
        600.0,
        900.0,
        1800.0,
        2700.0,
        3600.0
    ]

    // MARK: Internals

    private init() {
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        }
        
        self.durationFormatter.unitsStyle = .positional
        self.durationFormatter.allowedUnits = [ .minute, .second ]
        self.durationFormatter.collapsesLargestUnit = true

        reset()

        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .full
        formatter.allowedUnits = [ .hour, .minute ]

        self.alert.addAction(UIAlertAction(title: "Off", style: .default, handler: { _ in
            self.cancel()
        }))

        for interval in intervals {
            let formattedDuration = formatter.string(from: interval as TimeInterval)!

            self.alert.addAction(UIAlertAction(title: "In \(formattedDuration)", style: .default, handler: { _ in
                self.sleep(in: interval)
            }))
        }

        self.alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }

    private func sleep(in seconds: Double) {
        self.onStart?()
        self.onProgress?(seconds)

        reset()

        self.timeLeft = seconds
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(update), userInfo: nil, repeats: true)

        RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
    }

    private func reset() {
        self.alert.message = defaultMessage

        self.timer?.invalidate()
    }

    private func cancel() {
        reset()

        self.onEnd?(true)
    }

    @objc private func update() {
        self.timeLeft -= 1.0

        self.onProgress?(timeLeft)

        self.alert.message = "Sleeping in \(durationFormatter.string(from: self.timeLeft)!)"

        if self.timeLeft <= 0 {
            self.timer?.invalidate()

            self.onEnd?(false)
        }
    }

    // MARK: Public methods

    func actionSheet(onStart: @escaping SleepTimerStart, onProgress: @escaping SleepTimerProgress, onEnd: @escaping SleepTimerEnd) -> UIAlertController {
        self.onStart = onStart
        self.onEnd = onEnd
        self.onProgress = onProgress

        return alert
    }
}
