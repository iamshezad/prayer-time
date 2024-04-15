//
//  Extensions.swift
//  PrayerTimes
//
//  Created by Admin on 23/03/24.
//

import UIKit

//UIView Extension
extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
}
