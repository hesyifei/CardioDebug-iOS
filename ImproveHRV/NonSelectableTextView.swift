//
//  NonSelectableTextView.swift
//  ImproveHRV
//
//  Created by Arefly on 1/14/17.
//  Copyright © 2017 Arefly. All rights reserved.
//

import UIKit
import Foundation

class NonSelectableTextView: UITextView {
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		return false
	}

	override func becomeFirstResponder() -> Bool {
		return false
	}
}
