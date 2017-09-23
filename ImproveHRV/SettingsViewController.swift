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

	static let DEFAULTS_DEBUG_ANALYZE_SERVER_ADDRESS = "analyzeServerAddress"

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
				<<< TextRow("Analyze Server Address"){ row in
					row.title = row.tag
					row.value = defaults.string(forKey: Self.DEFAULTS_DEBUG_ANALYZE_SERVER_ADDRESS)
					row.placeholder = "Empty for default"
					}.onChange { row in
						self.defaults.set(row.value!, forKey: Self.DEFAULTS_DEBUG_ANALYZE_SERVER_ADDRESS)
				}
				<<< ButtonRow("Show ANS Disorder Warning") {
					$0.title = $0.tag
					}.cellUpdate { cell, row in
						//cell.textLabel?.textAlignment = .left
					}.onCellSelection { cell, row in
						let destination = self.storyboard?.instantiateViewController(withIdentifier: SimpleResultViewController.VC_STORYBOARD_ID) as! SimpleResultViewController
						destination.isGood = false
						destination.problemData = [
							"description": "<style>a { text-decoration: none; } .lightPink { color: #FA5858; }</style><div style='text-align: center;'><span style='font-size: 200%;'><a href='https://medlineplus.gov/autonomicnervoussystemdisorders.html'>自主神经失调</a></span></div><br />自主神经失调是交感副交感神经的失衡，会影响我们的日常生活并导致各种不同症状（如失眠、消化不良等）。<br /><span class='lightPink'>不健康的生活方式</span>和<span class='lightPink'>长时间工作</span>都有机会导致这一问题，长远更可能导致<span class='lightPink'>自主神经紊乱</span>等问题.<br /><br />为得出更准确的检测结果，请点击“下一步”并回答一些问题。" as AnyObject,
							"result": [
								"3": "您有机会有自主神经失调。我们建议您做<br /><br /><div style='text-align: center;'><span style='font-size: 200%;'>耐力运动</span></div><br /><span style='font-size: 130%;'>耐力运动是指能将您的心跳率提升到60-80%的活动（如跑步、游泳等），每日须做至少20分钟。</span>",
								"1": "由于您在过去四小时曾喝过咖啡或酒，检测结果可能并不准确，我们建议您明天在<b>在不喝咖啡或酒</b>的情况下再测一次。",
								"2": "",
								"0": ""
								] as AnyObject,
							"questions": [
								"您有觉得压力很大么？",
								"您最近有晚睡么？",
								"如果您没有喝咖啡或者酒，请选择“是”，反之请选“否”。"
								] as AnyObject
						]
						/*destination.problemData = [
							"description": "<style>a { text-decoration: none; } .lightPink { color: #FA5858; }</style><div style='text-align: center;'><span style='font-size: 200%;'><a href='https://medlineplus.gov/autonomicnervoussystemdisorders.html'>ANS disorder</a></span></div><br />ANS disorder is the imbalance of sympathetic nervous and parasympathetic nervous which controls the involuntary work of your body (such as digestion and heart rate).<br /><span class='lightPink'>Unhealthy lifestyle</span> and <span class='lightPink'>long working hours</span> may cause this disorder, and leaving it untreated maybe cause <span class='lightPink'>dysfunction of ANS</span>.<br /><br /><span style='font-size: 140%;'>ANS disorder may cause symptoms including <span class='lightPink'>poor digestion</span> and <span class='lightPink'>insomnia</span>.</span><br /><br />To get a more precise detection result, click \"Next\" to answer a few questions." as AnyObject,
							"result": [
								"0": "It is possible that you may have ANS disorder. We suggest you to do<br /><br /><div style='text-align: center;'><span style='font-size: 200%;'>Endurance Exercise</span></div><br /><span style='font-size: 130%;'>Do endurance exercise which heart rate is elevated to 60-80% (e.g. running, swimming) for at least 20 mins every day.</span>",
								"1": "Since you have drunk coffee or alcohol within the last 4 hours, it is possible that the detection result is unrelated to ANS disorder. We suggest you to record and test again tomorrow <b>without</b> drinking any coffee or alcohol.",
								"2": "",
								"3": ""
								] as AnyObject,
							"questions": [
								"Do you feel stressful all the time?",
								"Did you sleep late recently?",
								"Choose \"Yes\" if you did't drink any alcohol or caffeine, and vice versa."
								] as AnyObject
						]*/
						destination.passedBackData = { bool in
							// do nothing
						}
						self.present(destination, animated: true, completion: nil)
				}
			<<< ButtonRow("Show Arrhythmia Warning") {
				$0.title = $0.tag
				}.cellUpdate { cell, row in
					//cell.textLabel?.textAlignment = .left
				}.onCellSelection { cell, row in
					let destination = self.storyboard?.instantiateViewController(withIdentifier: SimpleResultViewController.VC_STORYBOARD_ID) as! SimpleResultViewController
					destination.isGood = false
					destination.problemData = [
						"description": "<style>a { text-decoration: none; }</style><div style='text-align: center;'><span style='font-size: 200%;'><a href='https://medlineplus.gov/autonomicnervoussystemdisorders.html'>Premature atrial contraction (PAC)</a></span></div><br />There may not be any symptom for this disease, however it maybe further develop into more serious arrhythmia if no action is taken.<br /><br />To get a more precise detection result, click \"Next\" to answer a few questions." as AnyObject,
						"result": [
							"0": "Since you have drunk coffee or alcohol within the last 4 hours and are having a cold, it is possible that the detection result is unrelated to the APB. We suggest you to record and test again after your are not sick any more and without</b> drinking any coffee or alcohol.",
							"1": "Since you (a) have drunk coffee or alcohol within the last 4 hours / (b) are having a cold, it is possible that the detection result is unrelated to the APB. We suggest you to record and test again<br />(a) tomorrow <b>without</b> drinking any coffee or alcohol.<br />(b) after your are <b>not</b> sick any more.",
							"2": "In order to alleviate this disease, please seek medical advice as soon as possible."
						] as AnyObject, "questions": [
							"Choose \"Yes\" if you are <b>not</b> having a cold, and vice versa.",
							"Choose \"Yes\" if you <b>did't</b> drink any alcohol or caffeine within the last 4 hours, and vice versa."
						] as AnyObject
					]
					/*destination.problemData = [
						"description": "<style>a { text-decoration: none; }</style><div style='text-align: center;'><span style='font-size: 200%;'><a href='https://medlineplus.gov/autonomicnervoussystemdisorders.html'>房性早搏（APB）</a></span></div><br />您可能没有任何明显的症状，但若无采取措施有可能将会导致更加严重的问题。<br /><br />为得出更准确的检测结果，请点击“下一步”并回答一些问题。" as AnyObject,
						"result": [
							"0": "Since you have drunk coffee or alcohol within the last 4 hours and are having a cold, it is possible that the detection result is unrelated to the APB. We suggest you to record and test again after your are not sick any more and without</b> drinking any coffee or alcohol.",
							"1": "Since you (a) have drunk coffee or alcohol within the last 4 hours / (b) are having a cold, it is possible that the detection result is unrelated to the APB. We suggest you to record and test again<br />(a) tomorrow <b>without</b> drinking any coffee or alcohol.<br />(b) after your are <b>not</b> sick any more.",
							"2": "请前往医院检测并进一步向医生查询。"
							] as AnyObject, "questions": [
								"如果您没有感冒，请选择“是”，反之请选“否”。",
								"如果您近4小时没有喝咖啡或者酒，请选择“是”，反之请选“否”。"
								] as AnyObject
					]*/
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
