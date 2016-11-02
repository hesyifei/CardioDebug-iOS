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

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
		self.navigationItem.setRightBarButton(doneButton, animated: true)

		form = Section("Section1")
			<<< SegmentedRow<String>() {
				$0.title = "ActionSheetRow"
				$0.options = ["Male", "Female"]
				$0.value = "Male"    // initially selected
			}
			<<< DecimalRow(){
				$0.title = "Height"
				$0.placeholder = "Enter text here"
			}
			<<< DecimalRow(){
				$0.title = "Weight"
				$0.placeholder = "And numbers here"
			}
			<<< DecimalRow(){
				$0.title = "BMI"
				$0.disabled = true
				$0.value = 999
			}
			<<< DateRow(){
				$0.title = "Birthday"
				$0.value = NSDate(timeIntervalSinceReferenceDate: 0) as Date
			}
			+++ Section("Section2")
			<<< DateRow(){
				$0.title = "Date Row"
				$0.value = NSDate(timeIntervalSinceReferenceDate: 0) as Date
		}
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
}
