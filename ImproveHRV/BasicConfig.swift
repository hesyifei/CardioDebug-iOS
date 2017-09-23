//
//  BasicConfig.swift
//  ImproveHRV
//
//  Created by Jason Ho on 9/12/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation

class BasicConfig {
	// for source code, see http://bitbucket.org/eflyjason/improvehrv-other

	//static let remedyListURL = "http://areflys-mac.local/other/improve-hrv/remedy/"
	static let remedyListURL = "https://app.arefly.com/cardio-debug/remedy/"

	//static let ecgCalculationURL = "http://ec2-54-68-166-131.us-west-2.compute.amazonaws.com:8080/"
	var ecgCalculationURL: String {
		get {
			#if DEBUG
				let debugServerURL = UserDefaults.standard.string(forKey: SettingsViewController.DEFAULTS_DEBUG_ANALYZE_SERVER_ADDRESS)
				if !debugServerURL?.isEmpty {
					return debugServerURL
				}
				return
			#endif
			return "http://aws.arefly.com:8080/"
		}
	}
	//static let ecgCalculationURL = "http://arefly.com/"
	//static let ecgCalculationURL = "http://127.0.0.1/"
}

class StoredColor {
	static let middleBlue = UIColor(netHex: 0x2d7eb9)
	static let darkGreen = UIColor(netHex: 0x19672c)
	static let darkRed = UIColor(netHex: 0xba2e57)
}
