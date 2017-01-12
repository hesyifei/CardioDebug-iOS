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
	static let padding: CGFloat = 10.0

	override func drawText(in rect: CGRect) {
		let insets = UIEdgeInsets(top: 0, left: PaddingLabel.padding, bottom: 0, right: PaddingLabel.padding)
		super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
	}
}
