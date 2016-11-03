//
//  Extensions.swift
//  Catnap
//
//  Created by Jason Ho on 30/8/2016.
//  Copyright © 2016年 Arefly. All rights reserved.
//

import UIKit
import Foundation

extension UIApplication {
	class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
		if let nav = base as? UINavigationController {
			return topViewController(base: nav.visibleViewController)
		}
		if let tab = base as? UITabBarController {
			if let selected = tab.selectedViewController {
				return topViewController(base: selected)
			}
		}
		if let presented = base?.presentedViewController {
			return topViewController(base: presented)
		}
		return base
	}
}


extension UIView {
	func addTapGesture(_ tapNumber: Int, target: AnyObject, action: Selector) {
		let tap = UITapGestureRecognizer (target: target, action: action)
		tap.numberOfTapsRequired = tapNumber
		addGestureRecognizer(tap)
		isUserInteractionEnabled = true
	}

	// http://stackoverflow.com/a/32824659/2603230
	/// Adds constraints to this `UIView` instances `superview` object to make sure this always has the same size as the superview.
	/// Please note that this has no effect if its `superview` is `nil` – add this `UIView` instance as a subview before calling this.
	func bindFrameToSuperviewBounds() {
		guard let superview = self.superview else {
			print("Error! `superview` was nil – call `addSubview(view: UIView)` before calling `bindFrameToSuperviewBounds()` to fix this.")
			return
		}
		self.translatesAutoresizingMaskIntoConstraints = false
		superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
		superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
	}
}


// http://stackoverflow.com/a/24263296/2603230
extension UIColor {
	convenience init(red: Int, green: Int, blue: Int) {
		assert(red >= 0 && red <= 255, "Invalid red component")
		assert(green >= 0 && green <= 255, "Invalid green component")
		assert(blue >= 0 && blue <= 255, "Invalid blue component")

		self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
	}

	convenience init(netHex:Int) {
		self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
	}
}
