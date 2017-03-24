//
//  SettingsViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 31/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation
import Async
import Eureka
import VTAcknowledgementsViewController

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
				$0.title = "Birthday (for age calculation)"
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
			+++ Section("About")
			<<< ButtonRow("Acknowledgements") {
				$0.title = $0.tag
				}.cellUpdate { cell, row in
					cell.textLabel?.textAlignment = .left
				}.onCellSelection { cell, row in
					if let acknowledgementsVC = VTAcknowledgementsViewController.acknowledgementsViewController() {
						acknowledgementsVC.headerText = "We love open source software."
						acknowledgementsVC.footerText = nil

						let physioNetAcknowledgement = VTAcknowledgement(title: "PhysioToolkit", text: "Goldberger AL, Amaral LAN, Glass L, Hausdorff JM, Ivanov PCh, Mark RG, Mietus JE, Moody GB, Peng C-K, Stanley HE. PhysioBank, PhysioToolkit, and PhysioNet: Components of a New Research Resource for Complex Physiologic Signals. Circulation 101(23):e215-e220 [Circulation Electronic Pages; http://circ.ahajournals.org/content/101/23/e215.full]; 2000 (June 13).", license: nil)
						acknowledgementsVC.acknowledgements?.insert(physioNetAcknowledgement, at: 0)
						let cardio24Acknowledgement = VTAcknowledgement(title: "cardio24", text: "An Integrated Platform For Cardiac Health Diagnostics\n\nTeam: Instructors: Kuldeep Singh Rajput, Rohan Puri, Maulik Majmudar, M.D., Dr.Ramesh Raskar\nStudents: Harsha Vardhan Pokkalla, Aranya Goswami\n\nSoftware required: MATLAB/Octave\n\nhttps://github.com/redxlab/cardio24", license: nil)
						acknowledgementsVC.acknowledgements?.insert(cardio24Acknowledgement, at: 1)
						let hrvToolkitAcknowledgement = VTAcknowledgement(title: "HRV Toolkit", text: "Background: Joseph E. Mietus, B.S. and Ary L. Goldberger, M.D.\nSoftware and related material: Joseph E. Mietus, B.S.\n\nMargret and H.A. Rey Institute for Nonlinear Dynamics in Physiology and Medicine\nDivision of Interdisciplinary Medicine and Biotechnology and Division of Cardiology\nBeth Israel Deaconess Medical Center/Harvard Medical School, Boston, MA\n\nhttps://www.physionet.org/tutorials/hrv-toolkit/", license: nil)
						acknowledgementsVC.acknowledgements?.insert(hrvToolkitAcknowledgement, at: 2)

						Async.main {
							self.navigationController?.pushViewController(acknowledgementsVC, animated: true)
						}
					}
		}
		#if DEBUG
			form +++ Section("DEBUG ONLY")
			<<< ButtonRow("Show Arrhythmia Warning") {
				$0.title = $0.tag
				}.cellUpdate { cell, row in
					//cell.textLabel?.textAlignment = .left
				}.onCellSelection { cell, row in
					let destination = self.storyboard?.instantiateViewController(withIdentifier: "SimpleResultViewController") as! SimpleResultViewController
					destination.isGood = false
					destination.problemData = [
						"description": "<style>a { text-decoration: none; }</style><div style='text-align: center;'><span style='font-size: 200%;'><a href='https://medlineplus.gov/autonomicnervoussystemdisorders.html'>Atrial Premature Beats (APB)</a></span></div><br />There may not be any symptom for this disease, however it maybe further develop into more serious arrhythmia if no action is taken.<br /><br />To get a more precise detection result, click \"Next\" to answer a few questions." as AnyObject
						, "result": [
						"0": "Since you have drunk coffee or alcohol within the last 4 hours and are having a cold, it is possible that the detection result is unrelated to the APB. We suggest you to record and test again after your are not sick any more and without</b> drinking any coffee or alcohol.",
						"1": "Since you (a) have drunk coffee or alcohol within the last 4 hours / (b) are having a cold, it is possible that the detection result is unrelated to the APB. We suggest you to record and test again<br />(a) tomorrow <b>without</b> drinking any coffee or alcohol.<br />(b) after your are <b>not</b> sick any more.",
						"2": "In order to alleviate this disease, please seek medical advice as soon as possible."
						] as AnyObject, "questions": [
							"Choose \"Yes\" if you are <b>not</b> having a cold, and vice versa.",
							"Choose \"Yes\" if you <b>did't</b> drink any alcohol or caffeine within the last 4 hours, and vice versa."
						] as AnyObject
					]
					destination.passedBackData = { bool in
						// do nothing
					}
					self.present(destination, animated: true, completion: nil)
			}
		#endif
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		let _ = updateBMI()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
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
