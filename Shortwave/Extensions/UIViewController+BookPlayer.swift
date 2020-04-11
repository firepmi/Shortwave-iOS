//
//  UIViewController+BookPlayer.swift
//  BookPlayer
//
//  Created by Florian Pichler on 28.04.18.
//  Copyright © 2018 Tortuga Power. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(_ title: String?, message: String?, style: UIAlertController.Style = .alert) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)

        alert.addAction(okButton)

        self.present(alert, animated: true, completion: nil)
    }

    // utility function to transform seconds to format MM:SS or HH:MM:SS
    func formatTime(_ time: TimeInterval) -> String {
        let durationFormatter = DateComponentsFormatter()

        durationFormatter.unitsStyle = .positional
        durationFormatter.allowedUnits = [ .minute, .second ]
        durationFormatter.zeroFormattingBehavior = .pad
        durationFormatter.collapsesLargestUnit = false

        if abs(time) > 3599.0 {
            durationFormatter.allowedUnits = [ .hour, .minute, .second ]
        }

        return durationFormatter.string(from: time)!
    }

    func formatDuration(_ duration: TimeInterval, unitsStyle: DateComponentsFormatter.UnitsStyle = .short) -> String {
        let durationFormatter = DateComponentsFormatter()

        durationFormatter.unitsStyle = unitsStyle
        durationFormatter.allowedUnits = [ .minute, .second ]
        durationFormatter.collapsesLargestUnit = true

        return durationFormatter.string(from: duration)!
    }

    func formatSpeed(_ speed: Float) -> String {
        return (speed.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(speed))" : "\(speed)") + "×"
    }
}
