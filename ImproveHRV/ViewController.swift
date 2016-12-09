//
//  ViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 31/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - basic var
	let application = UIApplication.shared
	let defaults = UserDefaults.standard

	// MARK: - IBOutlet var
	@IBOutlet var tableView: UITableView!

	// MARK: - init var
	var tableData = [String]()

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


		self.title = "Home"
		self.navigationItem.title = "ANS Debug"

		tableView.delegate = self
		tableView.dataSource = self

		tableData = ["Run", "Swim", "Jump"]
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


	// MARK: - tableView related
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableData.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
		let result = tableData[indexPath.row]
		cell.textLabel?.text = "\(result)"
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let cell = self.tableView.cellForRow(at: indexPath)
		cell?.accessoryType = .checkmark
		cell?.isUserInteractionEnabled = false
		self.tableView.deselectRow(at: indexPath, animated: true)
	}
}
