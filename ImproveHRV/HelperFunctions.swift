//
//  HelperFunctions.swift
//  ImproveHRV
//
//  Created by Jason Ho on 23/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import Foundation

class HelperFunctions {
	static internal func secondsToHoursMinutesSeconds(_ seconds : Int) -> (Int, Int, Int) {
		return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
	}

	static internal func delay(_ delay: Double, closure: @escaping ()->()) {
		let when = DispatchTime.now() + delay
		DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
	}
}
