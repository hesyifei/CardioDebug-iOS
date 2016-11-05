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

class RemedyListViewController: UIViewController, WKNavigationDelegate {

	var webView: WKWebView!

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		webView = WKWebView()
		webView.navigationDelegate = self

		self.view.addSubview(webView)
		webView.bindFrameToSuperviewBounds()

		let url = URL(string: "http://areflys-mac.local/other/improve-hrv/remedy.php")!
		webView.load(URLRequest(url: url))
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
		switch url! {
		case "http://action.is.needed/add":
			print("exiting VC")
			_ = self.navigationController?.popViewController(animated: true)
			decisionHandler(.cancel)
			break
		default:
			decisionHandler(.allow)
			break
		}
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		self.title = self.webView.title
	}
}
