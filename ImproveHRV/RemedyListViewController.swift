//
//  RemedyListViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 3/11/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import WebKit
import Foundation
import Async

class RemedyListViewController: UIViewController, WKNavigationDelegate {

	// MARK: - static var
	static let DEFAULTS_CURRENT_ACTIVITY = "currentActivity"

	// MARK: - basic var
	let application = UIApplication.shared
	let defaults = UserDefaults.standard

	fileprivate typealias `Self` = RemedyListViewController

	// MARK: - init var
	var webView: WKWebView!

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		webView = WKWebView()
		webView.navigationDelegate = self

		self.view.addSubview(webView)
		webView.bindFrameToSuperviewBounds()		// it's a custom extension

		Async.main {
			if let rect = self.navigationController?.navigationBar.frame {
				let y = rect.size.height + rect.origin.y
				print(y)
				let edgeInset = UIEdgeInsets(top: y, left: 0, bottom: -y, right: 0)
				self.webView.scrollView.contentInset = edgeInset
				self.webView.scrollView.scrollIndicatorInsets = edgeInset
			}
		}

		if let sex = defaults.string(forKey: SettingsViewController.DEFAULTS_SEX), let _ = defaults.object(forKey: SettingsViewController.DEFAULTS_HEIGHT), let _ = defaults.object(forKey: SettingsViewController.DEFAULTS_WEIGHT), let birthdayObj = defaults.object(forKey: SettingsViewController.DEFAULTS_BIRTHDAY) {

			let ageComponents = Calendar.current.dateComponents([.year], from: birthdayObj as! Date, to: Date())
			let age = ageComponents.year!

			let height = defaults.double(forKey: SettingsViewController.DEFAULTS_HEIGHT)
			let weight = defaults.double(forKey: SettingsViewController.DEFAULTS_WEIGHT)
			let bmi = HelperFunctions.getBMI(height: height, weight: weight)

			var urlString = "http://areflys-mac.local/other/improve-hrv/remedy.php?age=\(age)&sex=\(sex)&bmi=\(bmi)"
			if let currentActivity = defaults.string(forKey: Self.DEFAULTS_CURRENT_ACTIVITY) {
				urlString += "&currentActivity=\(currentActivity)"
			}
			print(urlString)

			if let url = URL(string: urlString) {
				webView.load(URLRequest(url: url))
			}
		} else {
			print("ERROR: not enough settings data")
		}
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

	// MARK: - WKWebView func
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		let url = navigationAction.request.url?.absoluteString
		print("已獲取目前將前往的鏈接：\(url)")
		if let url = url {
			let prefixForAdd = "http://action.is.needed/add/"
			if url.hasPrefix(prefixForAdd) {
				// http://stackoverflow.com/a/33733593/2603230
				let startIndex = url.index(url.startIndex, offsetBy: prefixForAdd.characters.count)
				let selectedRemedy = url.substring(from: startIndex)
				print("selectedRemedy \(selectedRemedy)")

				defaults.set(selectedRemedy, forKey: Self.DEFAULTS_CURRENT_ACTIVITY)

				print("exiting VC")
				_ = self.navigationController?.popViewController(animated: true)
				decisionHandler(.cancel)
				return
			}
		}
		decisionHandler(.allow)
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		self.title = self.webView.title
	}
}
