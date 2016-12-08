//
//  SettingsViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 31/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation
import Eureka

class SettingsViewController: FormViewController {

	// MARK: - static var
	static let DEFAULTS_SEX = "sex"
	static let DEFAULTS_BIRTHDAY = "birthday"
	static let DEFAULTS_HEIGHT = "height"
	static let DEFAULTS_WEIGHT = "weight"

	// MARK: - basic var
	let defaults = UserDefaults.standard

	fileprivate typealias `Self` = SettingsViewController

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Settings"

		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
		self.navigationItem.setRightBarButton(doneButton, animated: true)

		form +++ Section("Personal Information")
			<<< SegmentedRow<String>("Sex") {
				$0.options = ["Male", "Female"]
				$0.value = defaults.string(forKey: Self.DEFAULTS_SEX)
				}.onChange { row in
					self.defaults.set(row.value, forKey: Self.DEFAULTS_SEX)
			}
			<<< DecimalRow("Height"){
				$0.title = "Height (m)"
				$0.formatter = DecimalFormatter()
				$0.value = defaults.double(forKey: Self.DEFAULTS_HEIGHT)
				}.onChange { row in
					if self.updateBMI() {
						self.defaults.set(Double(row.value!), forKey: Self.DEFAULTS_HEIGHT)
					}
			}
			<<< DecimalRow("Weight"){
				$0.title = "Weight (kg)"
				$0.formatter = nil
				$0.value = defaults.double(forKey: Self.DEFAULTS_WEIGHT)
				}.onChange { row in
					if self.updateBMI() {
						self.defaults.set(Double(row.value!), forKey: Self.DEFAULTS_WEIGHT)
					}
			}
			<<< DecimalRow("BMI"){
				$0.title = "BMI"
				$0.baseCell.isUserInteractionEnabled = false
				$0.formatter = DecimalFormatter()
			}
			<<< DateRow("Birthday"){
				$0.title = "Birthday"
				$0.cell.detailTextLabel?.textColor = UIColor.black
				$0.value = (defaults.object(forKey: Self.DEFAULTS_BIRTHDAY) as! Date)
				}.cellUpdate { (cell, row) in
					cell.datePicker.maximumDate = Date(timeIntervalSinceNow: -60*60*24)
				}.onChange { row in
					self.defaults.set(row.value! as Date, forKey: Self.DEFAULTS_BIRTHDAY)
			}
			+++ Section("Advanced")
			<<< TextRow("BLE Device Name"){ row in
				row.title = row.tag
				row.value = defaults.string(forKey: RecordingViewController.DEFAULTS_BLE_DEVICE_NAME)
				row.placeholder = "BT05"
				}.onChange { row in
					if row.value != "" {
						self.defaults.set(row.value!, forKey: RecordingViewController.DEFAULTS_BLE_DEVICE_NAME)
					}
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		let _ = updateBMI()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func doneButtonAction() {
		navigationController?.dismiss(animated: true, completion: nil)
	}

	func updateBMI() -> Bool {
		var success = false
		if let bmiRow = form.rowBy(tag: "BMI") as? DecimalRow, let heightRow = form.rowBy(tag: "Height") as? DecimalRow, let weightRow = form.rowBy(tag: "Weight") as? DecimalRow {
			bmiRow.value = 0
			if let height: Double = heightRow.value, let weight: Double = weightRow.value {
				if weight > 0 && height > 0 {
					let bmi: Double = HelperFunctions.getBMI(height: height, weight: weight)
					bmiRow.value = bmi
					success = true
				}
			}
			bmiRow.updateCell()
		}
		return success
	}
}
