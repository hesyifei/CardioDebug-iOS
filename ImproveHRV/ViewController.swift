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
import MBProgressHUD

class ViewController: UIViewController {

	// MARK: - static var
	static let DEFAULTS_ACTIVITY_START_DATE = "activityStartDate"
	static let DEFAULTS_ACTIVITY_END_DATE = "activityEndDate"

	// MARK: - basic var
	let application = UIApplication.shared
	let defaults = UserDefaults.standard

	fileprivate typealias `Self` = ViewController

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

	// MARK: - data var
	let circleBackgroundColor = UIColor.clear
	let circleColor = UIColor(netHex: 0x2E2E2E)
	let disbledCircleColor = UIColor.gray
	let buttonColor = UIColor.white
	let disabledButtonColor = UIColor.gray

	let triangleBackgroundColor = UIColor.clear
	let triangleColor = UIColor(netHex: 0xE6E6E6)


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




		upperButtonOuterView.circleColor = circleColor
		upperButtonOuterView.backgroundColor = circleBackgroundColor
		upperButtonOuterView.addTapGesture(1, target: self, action: #selector(self.clickUpperButton))
		upperButton.setTitleColor(buttonColor, for: .normal)
		upperButton.setTitleColor(disabledButtonColor, for: .disabled)
		upperButton.titleLabel?.textAlignment = .center
		upperButton.titleLabel?.lineBreakMode = .byWordWrapping
		upperButton.setTitle("Start\nActivity", for: .normal)
		upperButton.addTarget(self, action: #selector(self.startActivityAction), for: .touchUpInside)

		middleButtonOuterView.circleColor = circleColor
		middleButtonOuterView.backgroundColor = circleBackgroundColor
		middleButtonOuterView.addTapGesture(1, target: self, action: #selector(self.clickMiddleButton))
		middleButton.setTitleColor(buttonColor, for: .normal)
		middleButton.setTitleColor(disabledButtonColor, for: .disabled)
		middleButton.titleLabel?.textAlignment = .center
		middleButton.titleLabel?.lineBreakMode = .byWordWrapping
		middleButton.setTitle("Finish\nActivity", for: .normal)
		middleButton.addTarget(self, action: #selector(self.finishActivityAction), for: .touchUpInside)

		lowerButtonOuterView.circleColor = circleColor
		lowerButtonOuterView.backgroundColor = circleBackgroundColor
		lowerButtonOuterView.addTapGesture(1, target: self, action: #selector(self.clickLowerButton))
		lowerButton.setTitleColor(buttonColor, for: .normal)
		lowerButton.setTitleColor(disabledButtonColor, for: .disabled)
		lowerButton.titleLabel?.textAlignment = .center
		lowerButton.titleLabel?.lineBreakMode = .byWordWrapping
		lowerButton.setTitle("Record\nECG", for: .normal)




		upperTriangleView.triangleColor = triangleColor
		upperTriangleView.backgroundColor = triangleBackgroundColor

		lowerTriangleView.triangleColor = triangleColor
		lowerTriangleView.backgroundColor = triangleBackgroundColor

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		print("VC viewWillAppear")
		var didSelectActivity = false
		var labelText = ""
		if let currentActivity = defaults.string(forKey: RemedyListViewController.DEFAULTS_CURRENT_ACTIVITY) {
			if let data = defaults.object(forKey: RemedyListViewController.DEFAULTS_ACTIVITIES_DATA) as? [String: Any] {
				if let activityData = data[currentActivity] as? [String: Any] {
					if let title = activityData["title"] as? String, let icon = activityData["icon"] as? String {
						didSelectActivity = true
						labelText = "Selected: \(title) \(icon)"
					}
				}
			}
		}

		if didSelectActivity {
			mainLabel.text = "\(labelText)"
			mainLabel.textColor = UIColor.black

			var startButtonEnabled = true
			var finishButtonEnabled = false
			if let startDate = defaults.object(forKey: Self.DEFAULTS_ACTIVITY_START_DATE) as? Date {
				if let endDate = defaults.object(forKey: Self.DEFAULTS_ACTIVITY_END_DATE) as? Date {
					if (HelperFunctions.isDateSameDay(startDate, endDate)) && (HelperFunctions.isDateSameDay(startDate, Date())) {
						startButtonEnabled = false
						finishButtonEnabled = false
					}
				} else {
					if HelperFunctions.isDateSameDay(startDate, Date()) {
						startButtonEnabled = false
						finishButtonEnabled = true
					}
				}
			}
			upperButton.isEnabled = startButtonEnabled
			middleButton.isEnabled = finishButtonEnabled
		}else{
			mainLabel.text = "Select your activity in \"Remedy\""
			mainLabel.textColor = UIColor.red

			upperButton.isEnabled = false
			middleButton.isEnabled = false
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
		if upperButton.isEnabled {
			Async.main {
				self.upperButton.sendActions(for: .touchUpInside)
			}
		}
	}
	func clickMiddleButton() {
		if middleButton.isEnabled {
			Async.main {
				self.middleButton.sendActions(for: .touchUpInside)
			}
		}
	}
	func clickLowerButton() {
		if lowerButton.isEnabled {
			Async.main {
				self.lowerButton.sendActions(for: .touchUpInside)
			}
		}
	}

	func startActivityAction() {
		defaults.set(Date(), forKey: Self.DEFAULTS_ACTIVITY_START_DATE)
		upperButton.isEnabled = false
		middleButton.isEnabled = true
		showHudWithImage(text: "Started", imageName: "Checkmark")
	}

	func finishActivityAction() {
		if let startDate = defaults.object(forKey: Self.DEFAULTS_ACTIVITY_START_DATE) as? Date {
			if HelperFunctions.isDateSameDay(startDate, Date()) {
				upperButton.isEnabled = false
				middleButton.isEnabled = false
				defaults.set(Date(), forKey: Self.DEFAULTS_ACTIVITY_END_DATE)
				showHudWithImage(text: "Recorded", imageName: "Checkmark")
			}
		}
	}


	func showHudWithImage(text: String, imageName: String) {
		showHudWithImage(text: text, imageName: imageName, afterDelay: 2.0)
	}
	func showHudWithImage(text: String, imageName: String, afterDelay: TimeInterval) {
		Async.main {
			let tickHud = MBProgressHUD.showAdded(to: self.view, animated: true)
			tickHud.mode = .customView
			let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
			tickHud.customView = UIImageView(image: image)
			tickHud.isSquare = true
			tickHud.label.text = text
			tickHud.hide(animated: true, afterDelay: afterDelay)
		}
	}

}
