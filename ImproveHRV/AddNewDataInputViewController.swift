//
//  AddNewDataInputViewController.swift
//  ImproveHRV
//
//  Created by Arefly on 1/15/17.
//  Copyright © 2017 Arefly. All rights reserved.
//

import UIKit
import Foundation
import Async

class AddNewDataInputViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
	// MARK: - static var
	static let SHOW_INPUT_TABLE_VIEW = "showInputTableView"

	let cellID = "inputCell"

	@IBOutlet var tableView: UITableView!

	var viewTitle = ""
	var tableData = [String]()

	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.delegate = self
		tableView.dataSource = self

		self.title = viewTitle

		let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.saveButtonAction))
		self.navigationItem.setRightBarButton(saveButton, animated: true)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func saveButtonAction() {
		// TODO: save data
		self.dismiss(animated: true, completion: nil)
	}

	// MARK: - tableView related
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableData.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = getCell(indexPath)

		cell.titleLabel.text = tableData[indexPath.row]
		cell.textField.text = ""
		cell.textField.keyboardType = .decimalPad

		return cell
	}

	func getCell(_ indexPath: IndexPath) -> TextFieldInputTableCell {
		return self.tableView.dequeueReusableCell(withIdentifier: cellID)! as! TextFieldInputTableCell
	}
}

class TextFieldInputTableCell: UITableViewCell {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var textField: UITextField!

	override var canBecomeFirstResponder: Bool { return true }

	override func becomeFirstResponder() -> Bool {
		return self.textField.becomeFirstResponder()
	}
}
