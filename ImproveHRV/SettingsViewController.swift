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
import Surge

class SettingsViewController: FormViewController {

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Settings"

		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
		self.navigationItem.setRightBarButton(doneButton, animated: true)

		form +++ Section("Personal Information")
			<<< SegmentedRow<String>("Sex") {
				$0.options = ["Male", "Female"]
				$0.value = "Male"    // initially selected
			}
			<<< DecimalRow("Height"){
				$0.title = "Height (m)"
				$0.formatter = DecimalFormatter()
				}.onChange { row in
					self.updateBMI()
			}
			<<< DecimalRow("Weight"){
				$0.title = "Weight (kg)"
				$0.formatter = nil
				}.onChange { row in
					self.updateBMI()
			}
			<<< DecimalRow("BMI"){
				$0.title = "BMI"
				$0.baseCell.isUserInteractionEnabled = false
				$0.formatter = DecimalFormatter()
			}
			<<< DateRow("Birthday"){
				$0.title = "Birthday"
				$0.cell.detailTextLabel?.textColor = UIColor.black
				$0.value = Date.init(timeIntervalSinceReferenceDate: 0)
		}
		/*+++ Section("Section2")
		<<< DateRow(){
		$0.title = "Date Row"
		$0.value = Date.init(timeIntervalSinceReferenceDate: 0)
		}*/
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

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

	func updateBMI() {
		if let bmiRow = form.rowBy(tag: "BMI") as? DecimalRow, let heightRow = form.rowBy(tag: "Height") as? DecimalRow, let weightRow = form.rowBy(tag: "Weight") as? DecimalRow {
			bmiRow.value = 0
			if let height: Double = heightRow.value, let weight: Double = weightRow.value {
				if weight > 0 && height > 0 {
					let bmi: Double = weight / Surge.pow(height, 2)
					bmiRow.value = bmi
				}
			}
			bmiRow.updateCell()
		}
	}
}
