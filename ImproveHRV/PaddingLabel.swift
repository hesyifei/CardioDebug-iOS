//
//  PaddingLabel.swift
//  ImproveHRV
//
//  Created by Arefly on 1/12/17.
//  Copyright © 2017 Arefly. All rights reserved.
//

import UIKit
import Foundation

@IBDesignable
class PaddingLabel: UILabel {
	override func drawText(in rect: CGRect) {
		let insets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
		super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
	}
}
