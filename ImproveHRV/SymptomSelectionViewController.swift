//
//  SymptomSelectionViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 8/11/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation

class SymptomSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	static let SHOW_SYMPTOM_SELECTION_SEGUE_ID = "showSymptomSelection"
	
	@IBOutlet var tableView: UITableView!

	var tableData = [[String]]()
	var tableHeader = [String]()

	var passedBackData: ((Bool) -> Void)?


	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Choose all symptoms you felt"

		tableView.delegate = self
		tableView.dataSource = self

		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
		self.navigationItem.setRightBarButton(doneButton, animated: true)


		tableHeader = ["Sleep", "Eat", "Feel"]
		tableData = [
			["hard to fall asleep", "mostly light sleep", "dreamful sleep"],
			["vegetarian", "high fat", "high sugar", "high salt"],
			["tiredness", "dizziness", "headache", "palpitation", "perspire", "eye strain"]
		]
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
		passedBackData?(true)
		navigationController?.dismiss(animated: true, completion: nil)
	}


	// MARK: - tableView related
	func numberOfSections(in tableView: UITableView) -> Int {
		return tableHeader.count
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return tableHeader[section]
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableData[section].count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
		let result = tableData[indexPath.section][indexPath.row]
		cell.textLabel?.text = "\(result)"
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let cell = self.tableView.cellForRow(at: indexPath)
		if cell?.accessoryType == .checkmark {
			cell?.accessoryType = .none
		} else {
			cell?.accessoryType = .checkmark
		}

		self.tableView.deselectRow(at: indexPath, animated: true)
	}
}
