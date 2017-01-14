//
//  AddNewDataViewController.swift
//  ImproveHRV
//
//  Created by Arefly on 1/14/17.
//  Copyright © 2017 Arefly. All rights reserved.
//

import UIKit
import Foundation

class AddNewDataViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	// MARK: - static var
	static let PRESENT_ADD_DATA_VIEW = "presentAddDataView"

	@IBOutlet var tableView: UITableView!

	var tableData = [String]()

	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.delegate = self
		tableView.dataSource = self

		self.title = "Add"

		tableData = ["blood pressure", "height", "weight"]

		let closeButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(self.closeButtonAction))
		self.navigationItem.setRightBarButton(closeButton, animated: true)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func closeButtonAction() {
		self.dismiss(animated: true, completion: nil)
	}

	// MARK: - tableView related
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableData.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
		cell.textLabel?.text = tableData[indexPath.row]
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.deselectRow(at: indexPath, animated: true)
	}
}
