//
//  ViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 31/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation
import Async

class ViewController: UIViewController {

	// MARK: - basic var
	let application = UIApplication.shared
	let defaults = UserDefaults.standard

	// MARK: - IBOutlet var
	@IBOutlet var mainLabel: UILabel!

	@IBOutlet var upperButtonOuterView: CircleView!
	@IBOutlet var upperButton: UIButton!
	@IBOutlet var upperTriangleView: TriangleView!
	@IBOutlet var middleButtonOuterView: CircleView!
	@IBOutlet var middleButton: UIButton!
	@IBOutlet var lowerTriangleView: TriangleView!
	@IBOutlet var lowerButtonOuterView: CircleView!
	@IBOutlet var lowerButton: UIButton!

	// MARK: - init var

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		if defaults.object(forKey: RecordingViewController.DEFAULTS_BLE_DEVICE_NAME) == nil {
			defaults.set("BT05", forKey: RecordingViewController.DEFAULTS_BLE_DEVICE_NAME)
		}
		if defaults.object(forKey: SettingsViewController.DEFAULTS_SEX) == nil {
			defaults.set("Male", forKey: SettingsViewController.DEFAULTS_SEX)
		}
		if defaults.object(forKey: SettingsViewController.DEFAULTS_BIRTHDAY) == nil {
			defaults.set(Date(timeIntervalSinceReferenceDate: 0), forKey: SettingsViewController.DEFAULTS_BIRTHDAY)
		}
		if defaults.object(forKey: SettingsViewController.DEFAULTS_HEIGHT) == nil {
			defaults.set(Double(1.80), forKey: SettingsViewController.DEFAULTS_HEIGHT)
		}
		if defaults.object(forKey: SettingsViewController.DEFAULTS_WEIGHT) == nil {
			defaults.set(Double(70.00), forKey: SettingsViewController.DEFAULTS_WEIGHT)
		}


		self.navigationItem.title = "Debug ANS"


		let circleBackgroundColor = UIColor.clear
		let circleColor = UIColor(netHex: 0x2E2E2E)
		let disbledCircleColor = UIColor.gray
		let buttonColor = UIColor.white
		let disabledButtonColor = UIColor.white

		upperButtonOuterView.circleColor = circleColor
		upperButtonOuterView.backgroundColor = circleBackgroundColor
		upperButtonOuterView.addTapGesture(1, target: self, action: #selector(self.clickUpperButton))
		upperButton.setTitleColor(buttonColor, for: .normal)
		upperButton.setTitleColor(disabledButtonColor, for: .disabled)

		middleButtonOuterView.circleColor = circleColor
		middleButtonOuterView.backgroundColor = circleBackgroundColor
		middleButtonOuterView.addTapGesture(1, target: self, action: #selector(self.clickMiddleButton))
		middleButton.setTitleColor(buttonColor, for: .normal)
		middleButton.setTitleColor(disabledButtonColor, for: .disabled)

		lowerButtonOuterView.circleColor = circleColor
		lowerButtonOuterView.backgroundColor = circleBackgroundColor
		lowerButtonOuterView.addTapGesture(1, target: self, action: #selector(self.clickLowerButton))
		lowerButton.setTitleColor(buttonColor, for: .normal)
		lowerButton.setTitleColor(disabledButtonColor, for: .disabled)


		let triangleBackgroundColor = UIColor.clear
		let triangleColor = UIColor(netHex: 0xE6E6E6)

		upperTriangleView.triangleColor = triangleColor
		upperTriangleView.backgroundColor = triangleBackgroundColor

		lowerTriangleView.triangleColor = triangleColor
		lowerTriangleView.backgroundColor = triangleBackgroundColor

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		print("VC viewWillAppear")
		mainLabel.text = "Select your activity in \"Remedy\""
		if let currentActivity = defaults.string(forKey: RemedyListViewController.DEFAULTS_CURRENT_ACTIVITY) {
			if let data = defaults.object(forKey: RemedyListViewController.DEFAULTS_ACTIVITIES_DATA) as? [String: Any] {
				if let activityData = data[currentActivity] as? [String: Any] {
					if let title = activityData["title"] as? String, let icon = activityData["icon"] as? String {
						mainLabel.text = "Selected: \(title) \(icon)"
					}
				}
			}
		}
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	func clickUpperButton() {
		Async.main {
			self.upperButton.sendActions(for: .touchUpInside)
		}
	}
	func clickMiddleButton() {
		Async.main {
			self.middleButton.sendActions(for: .touchUpInside)
		}
	}
	func clickLowerButton() {
		Async.main {
			self.lowerButton.sendActions(for: .touchUpInside)
		}
	}


}
