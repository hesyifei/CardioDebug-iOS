//
//  WarningViewController.swift
//  ImproveHRV
//
//  Created by Arefly on 18/12/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation

class WarningViewController: UIViewController {

	// MARK: - static var
	static let SHOW_WARNING_SEGUE_ID = "showWarningView"

	// MARK: - basic var
	let application = UIApplication.shared
	let defaults = UserDefaults.standard

	// MARK: - IBOutlet var
	@IBOutlet var mainLabel: UILabel!
	@IBOutlet var mainTextView: UITextView!
	@IBOutlet var leftButton: UIButton!
	@IBOutlet var rightButton: UIButton!

	// MARK: - init var

	// MARK: - data var



	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

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
	
}
