//
//  SimpleResultViewController.swift
//  ImproveHRV
//
//  Created by Arefly on 18/12/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation
import Async

class SimpleResultViewController: UIViewController {

	// MARK: - static var
	static let SHOW_SIMPLE_RESULT_SEGUE_ID = "showSimpleResultView"

	// MARK: - basic var
	let application = UIApplication.shared

	// MARK: - IBOutlet var
	@IBOutlet var upperLabel: UILabel!
	@IBOutlet var mainLabel: UILabel!
	@IBOutlet var mainTextView: NonSelectableTextView!
	@IBOutlet var leftButton: UIButton!
	@IBOutlet var rightButton: UIButton!

	// MARK: - constant var
	let errorHTMLText = "Error :(<br />Please contact app developer."

	// MARK: - init var
	var currentState = 0
	var numberOfYes = 0

	// MARK: - data var
	var isGood: Bool!
	var problemData: [String: AnyObject]!

	var symptoms = [String]()

	var passedBackData: ((Bool) -> Void)?


	// MARK: - override var
	override var preferredStatusBarStyle: UIStatusBarStyle {
		if isGood == false {
			return .lightContent
		} else {
			return .default
		}
	}

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		if isGood == true {
			self.view.backgroundColor = UIColor.white

			self.upperLabel.text = " "
			self.upperLabel.textColor = UIColor.green

			self.mainLabel.text = "Congrats! You looks fine!"
			self.mainLabel.font = UIFont.systemFont(ofSize: 25)

			let centerParagraphStyle = NSMutableParagraphStyle()
			centerParagraphStyle.alignment = .center

			let attrText = NSAttributedString(string: "✓", attributes: [NSForegroundColorAttributeName: UIColor(netHex: 0x0B610B), NSFontAttributeName: UIFont.systemFont(ofSize: 100), NSParagraphStyleAttributeName: centerParagraphStyle])
			self.mainTextView.attributedText = attrText
		} else {
			print("problemData: \(problemData)")

			self.view.backgroundColor = UIColor(netHex: 0x333333)

			self.leftButton.setTitleColor(.white, for: .normal)
			self.rightButton.setTitleColor(.white, for: .normal)

			self.upperLabel.text = "!"
			self.upperLabel.textColor = UIColor.red

			// TODO: use problemData here
			self.mainLabel.text = "We detected that you may have:"
			self.mainLabel.textColor = UIColor.white

			self.mainTextView.textColor = UIColor.white		// have to put before using any attributedStringFromHTMLToTextView
			self.mainTextView.tintColor = UIColor.white
			if let htmlDescription = problemData["description"] as? String {
				self.mainTextView.setAttributedStringFromHTML(htmlDescription) { _ in }
			} else {
				self.mainTextView.setAttributedStringFromHTML(errorHTMLText) { _ in }
			}

			if let questions = problemData["questions"] as? [String] {
				symptoms = questions
			}
		}

		leftButton.isHidden = true
		leftButton.addTarget(self, action: #selector(self.leftButtonAction), for: .touchUpInside)

		if isGood == true {
			rightButton.setTitle("Done", for: .normal)
		} else {
			rightButton.setTitle("Next", for: .normal)
		}
		rightButton.addTarget(self, action: #selector(self.rightButtonAction), for: .touchUpInside)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - button action
	func leftButtonAction() {
		if currentState > 0 {
			numberOfYes += 1
			appendState()
		}
	}

	func rightButtonAction() {
		appendState()
	}

	func appendState() {
		if isGood == true {
			passedBackData?(true)
			self.dismiss(animated: true, completion: nil)
		} else {
			var firstPageCount = 0
			if symptoms.count == 0 {
				// never do this case when symptoms.count == 0
				firstPageCount = -999
			}
			switch currentState {
			case firstPageCount:
				leftButton.setTitle("Yes", for: .normal)
				leftButton.isHidden = false
				rightButton.setTitle("No", for: .normal)
				mainLabel.text = "Did you feel..."

				mainTextView.setAttributedStringFromHTML(symptoms[currentState]) { _ in }

				upperLabel.text = "?"
				break
			case symptoms.count:
				leftButton.isHidden = true
				rightButton.setTitle("Close", for: .normal)
				mainLabel.text = "Recommendation:"

				if let resultDict = problemData["result"] as? [String: String] {
					if let htmlDescription = resultDict["\(numberOfYes)"] {
						self.mainTextView.setAttributedStringFromHTML(htmlDescription) { _ in }
					} else {
						self.mainTextView.setAttributedStringFromHTML(errorHTMLText) { _ in }
					}
				}

				upperLabel.text = "!"
				break
			case symptoms.count+1:
				passedBackData?(true)
				self.dismiss(animated: true, completion: nil)
				break
			default:
				mainTextView.setAttributedStringFromHTML(symptoms[currentState]) { _ in }
				break
			}
		}
		currentState += 1
	}
	
}
