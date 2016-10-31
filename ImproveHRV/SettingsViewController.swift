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
			<<< TextRow(){ row in
				row.title = "Text Row"
				row.placeholder = "Enter text here"
			}
			<<< PhoneRow(){
				$0.title = "Phone Row"
				$0.placeholder = "And numbers here"
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
