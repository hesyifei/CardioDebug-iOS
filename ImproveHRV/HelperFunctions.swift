//
//  HelperFunctions.swift
//  ImproveHRV
//
//  Created by Jason Ho on 23/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation

class HelperFunctions {
	static internal func secondsToHoursMinutesSeconds(_ seconds : Int) -> (Int, Int, Int) {
		return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
	}

	static internal func delay(_ delay: Double, closure: @escaping ()->()) {
		let when = DispatchTime.now() + delay
		DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
	}

	static internal func getInchFromWidth() -> Float{
		let bounds = UIScreen.main.bounds

		var width = bounds.size.width
		var height = bounds.size.height
		// 為保證檢測的大小正確
		if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
			width = bounds.size.height
			height = bounds.size.width
		}

		var size: Float = 0.0
		switch (width, height) {
		case (320.0, 480.0):
			size = 3.5
		case (320.0, 568.0):
			size = 4.0
		case (375.0, 667.0):
			size = 4.7
		case (414.0, 736.0):
			size = 5.5
		default:
			size = 99.9
		}

		return size
	}
}
