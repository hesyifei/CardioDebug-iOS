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

		self.title = NSLocalizedString("SymptomSelection.Title", comment: "Choose all symptoms you felt")

		tableView.delegate = self
		tableView.dataSource = self

		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
		self.navigationItem.setRightBarButton(doneButton, animated: true)


		updateUpperTableData(0)
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



	@IBAction func segmentedControlChanged(sender: UISegmentedControl) {
		print("segmentedControlChanged: \(sender.selectedSegmentIndex)")
		self.updateUpperTableData(sender.selectedSegmentIndex)
		self.tableView.reloadData()
	}

	func updateUpperTableData(_ index: Int) {
		if index == 0 {
			tableHeader = [NSLocalizedString("SymptomSelection.Symptom.Physical.Sleep", comment: "Sleep"), NSLocalizedString("SymptomSelection.Symptom.Physical.Eat", comment: "Eat"), NSLocalizedString("SymptomSelection.Symptom.Physical.Feel", comment: "Feel")]
			tableData = [
				[NSLocalizedString("SymptomSelection.Symptom.Physical.hard to fall asleep", comment: "hard to fall asleep"), NSLocalizedString("SymptomSelection.Symptom.Physical.mostly light sleep", comment: "mostly light sleep"), NSLocalizedString("SymptomSelection.Symptom.Physical.dreamful sleep", comment: "dreamful sleep")],
				[NSLocalizedString("SymptomSelection.Symptom.Physical.vegetarian", comment: "vegetarian"), NSLocalizedString("SymptomSelection.Symptom.Physical.high fat", comment: "high fat"), NSLocalizedString("SymptomSelection.Symptom.Physical.high sugar", comment: "high sugar"), NSLocalizedString("SymptomSelection.Symptom.Physical.high salt", comment: "high salt")],
				[NSLocalizedString("SymptomSelection.Symptom.Physical.tiredness", comment: "tiredness"), NSLocalizedString("SymptomSelection.Symptom.Physical.dizziness", comment: "dizziness"), NSLocalizedString("SymptomSelection.Symptom.Physical.headache", comment: "headache"), NSLocalizedString("SymptomSelection.Symptom.Physical.palpitation", comment: "palpitation"), NSLocalizedString("SymptomSelection.Symptom.Physical.perspire", comment: "perspire"), NSLocalizedString("SymptomSelection.Symptom.Physical.eye strain", comment: "eye strain")]
			]
		} else {
			tableHeader = [""]
			tableData = [
				[NSLocalizedString("SymptomSelection.Symptom.Mental.tense", comment: "tense"), NSLocalizedString("SymptomSelection.Symptom.Mental.angry", comment: "angry"), NSLocalizedString("SymptomSelection.Symptom.Mental.wornout", comment: "wornout"), NSLocalizedString("SymptomSelection.Symptom.Mental.unhappy", comment: "unhappy"), NSLocalizedString("SymptomSelection.Symptom.Mental.proud", comment: "proud"), NSLocalizedString("SymptomSelection.Symptom.Mental.lively", comment: "lively"), NSLocalizedString("SymptomSelection.Symptom.Mental.confused", comment: "confused"), NSLocalizedString("SymptomSelection.Symptom.Mental.sad", comment: "sad"), NSLocalizedString("SymptomSelection.Symptom.Mental.active", comment: "active"), NSLocalizedString("SymptomSelection.Symptom.Mental.on-edge", comment: "on-edge"), NSLocalizedString("SymptomSelection.Symptom.Mental.grouchy", comment: "grouchy"), NSLocalizedString("SymptomSelection.Symptom.Mental.ashamed", comment: "ashamed"), NSLocalizedString("SymptomSelection.Symptom.Mental.energetic", comment: "energetic"), NSLocalizedString("SymptomSelection.Symptom.Mental.hopeless", comment: "hopeless"), NSLocalizedString("SymptomSelection.Symptom.Mental.uneasy", comment: "uneasy"), NSLocalizedString("SymptomSelection.Symptom.Mental.restless", comment: "restless"), NSLocalizedString("SymptomSelection.Symptom.Mental.unable to concentrate", comment: "unable to concentrate"), NSLocalizedString("SymptomSelection.Symptom.Mental.fatigued", comment: "fatigued"), NSLocalizedString("SymptomSelection.Symptom.Mental.competent", comment: "competent"), NSLocalizedString("SymptomSelection.Symptom.Mental.annoyed", comment: "annoyed"), NSLocalizedString("SymptomSelection.Symptom.Mental.discouraged", comment: "discouraged"), NSLocalizedString("SymptomSelection.Symptom.Mental.resentful", comment: "resentful"), NSLocalizedString("SymptomSelection.Symptom.Mental.nervous", comment: "nervous"), NSLocalizedString("SymptomSelection.Symptom.Mental.miserable", comment: "miserable")]
			]
		}
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
