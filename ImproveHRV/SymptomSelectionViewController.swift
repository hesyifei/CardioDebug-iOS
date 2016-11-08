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
	@IBOutlet var tableView: UITableView!

	var tableData = [String]()

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.delegate = self
		tableView.dataSource = self

		tableData = ["BAD", "WORSE"]
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
		if cell?.accessoryType == .checkmark {
			cell?.accessoryType = .none
		} else {
			cell?.accessoryType = .checkmark
		}

		self.tableView.deselectRow(at: indexPath, animated: true)
	}
}
