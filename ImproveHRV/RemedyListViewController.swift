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
import MBProgressHUD

class RemedyListViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

	// MARK: - static var
	static let DEFAULTS_CURRENT_ACTIVITY = "currentActivity"
	static let DEFAULTS_ACTIVITIES_DATA = "activitiesData"

	// MARK: - basic var
	let application = UIApplication.shared
	let defaults = UserDefaults.standard

	fileprivate typealias `Self` = RemedyListViewController

	// MARK: - init var
	var webView: WKWebView!

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		// http://stackoverflow.com/q/19143353/2603230
		self.edgesForExtendedLayout = []
		self.navigationController?.navigationBar.isTranslucent = false
		self.automaticallyAdjustsScrollViewInsets = false


		webView = WKWebView()
		webView.navigationDelegate = self

		Async.main {
			self.setWebViewFrame()
			self.view.addSubview(self.webView)
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
				webView.configuration.userContentController.add(self, name: "selectedActivity")
			}
		} else {
			print("ERROR: not enough settings data")
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		Async.main {
			MBProgressHUD.hide(for: self.view, animated: true)
		}
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
			let orient = self.application.statusBarOrientation
			print("orient: \(orient)")
			self.setWebViewFrame()
		}, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
			print("Finish orient")
		})

		super.viewWillTransition(to: size, with: coordinator)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	func setWebViewFrame() {
		webView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
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

	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		if let data = message.body as? [String: Any] {
			print(data)
			defaults.set(data, forKey: Self.DEFAULTS_ACTIVITIES_DATA)
		}
	}

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		Async.main {
			MBProgressHUD.showAdded(to: self.view, animated: true)
		}
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		self.title = self.webView.title
		Async.main {
			MBProgressHUD.hide(for: self.view, animated: true)
		}
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		print("FAILED")
		Async.main {
			MBProgressHUD.hide(for: self.view, animated: true)
		}
	}
}
