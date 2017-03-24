//
//  Extensions.swift
//  Catnap
//
//  Created by Jason Ho on 30/8/2016.
//  Copyright © 2016年 Arefly. All rights reserved.
//

import UIKit
import Foundation
import Async

extension UIApplication {
	// http://stackoverflow.com/a/30858591/2603230
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
	// http://stackoverflow.com/a/32182866/2603230
	func addTapGesture(_ tapNumber: Int, target: AnyObject, action: Selector) {
		let tap = UITapGestureRecognizer(target: target, action: action)
		tap.numberOfTapsRequired = tapNumber
		addGestureRecognizer(tap)
		isUserInteractionEnabled = true
	}
}


// http://stackoverflow.com/a/24263296/2603230
// http://stackoverflow.com/a/40018698/2603230
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

	func toHexString() -> String {
		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		var a: CGFloat = 0
		getRed(&r, green: &g, blue: &b, alpha: &a)

		let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
		return String(format:"#%06x", rgb)
	}
}


// http://stackoverflow.com/a/39498464/2603230
extension CBCentralManager {

	internal var centralManagerState: CBCentralManagerState  {
		get {
			return CBCentralManagerState(rawValue: state.rawValue) ?? .unknown
		}
	}
}


// http://stackoverflow.com/a/34190968/2603230 and modified (http://stackoverflow.com/a/41519178/2603230)
extension UITextView {
	func setAttributedStringFromHTML(_ htmlCode: String, completionBlock: @escaping (NSAttributedString?) ->()) {

		let inputText = "<body><div>\(htmlCode)</div><style>body { font-family: '\((self.font?.fontName)!)'; font-size:\((self.font?.pointSize)!)px; color: \((self.textColor)!.toHexString()); }</style></body>"
		//print(inputText)

		guard let data = inputText.data(using: String.Encoding.utf16) else {
			print("Unable to decode data from html string: \(self)")
			return completionBlock(nil)
		}

		Async.main {
			if let attributedString = try? NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil) {
				// http://stackoverflow.com/a/27874968/2603230
				self.attributedText = nil
				self.text = ""
				self.insertText("")

				self.attributedText = attributedString
				completionBlock(attributedString)
			} else {
				print("Unable to create attributed string from html string: \(self)")
				completionBlock(nil)
			}
		}
	}
}


extension String {
	// http://stackoverflow.com/a/38809531/2603230
	func imageFromEmoji() -> UIImage? {
		let size = CGSize(width: 60, height: 70)
		UIGraphicsBeginImageContextWithOptions(size, false, 0)
		UIColor.clear.set()
		let rect = CGRect(origin: CGPoint(), size: size)
		UIRectFill(CGRect(origin: CGPoint(), size: size))
		(self as NSString).draw(in: rect, withAttributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 60)])
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}
}


extension Array where Element: Equatable {

	// http://stackoverflow.com/a/30724543/2603230
	// Remove first collection element that is equal to the given `object`:
	mutating func remove(object: Element) {
		if let index = index(of: object) {
			remove(at: index)
		}
	}
}

