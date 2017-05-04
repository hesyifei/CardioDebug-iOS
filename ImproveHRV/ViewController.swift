//
//  ViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 31/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation
import UserNotifications
import Async
import MBProgressHUD
import RealmSwift

struct NotificationInfo {
	var time: Date
	var message: String
	var categoryIdentifier: String?
}

class ViewController: UIViewController, UNUserNotificationCenterDelegate {

	// MARK: - static var
	static let DEFAULTS_ACTIVITY_START_DATE = "activityStartDate"
	static let DEFAULTS_ACTIVITY_END_DATE = "activityEndDate"		// maybe it's useless?

	let NOTIFICATION_CATEGORY_DO_REMEDY_ID = "com.arefly.CardioDebug.notification-category.DoRemedy"

	// MARK: - basic var
	let application = UIApplication.shared
	let defaults = UserDefaults.standard

	fileprivate typealias `Self` = ViewController

	// MARK: - IBOutlet var
	@IBOutlet var mainLabel: UILabel!

	@IBOutlet var upperButtonOuterView: CircleView!
	@IBOutlet var upperButton: UIButton!
	@IBOutlet var upperTriangleView: TriangleView!
	@IBOutlet var middleButtonOuterView: CircleView!
	@IBOutlet var middleButton: UIButton!
	@IBOutlet var lowerTriangleView: TriangleView!
	@IBOutlet var lowerButtonOuterView: CircleView!
	@IBOutlet var lowerButton: UIButton!

	// MARK: - init var

	// MARK: - data var
	let circleBackgroundColor = UIColor.clear
	let circleColor = UIColor(netHex: 0x2E2E2E)
	let disbledCircleColor = UIColor.gray
	let buttonColor = UIColor.white
	let disabledButtonColor = UIColor.gray

	let triangleBackgroundColor = UIColor.clear
	let triangleColor = UIColor(netHex: 0xE6E6E6)


	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		if defaults.object(forKey: RemedyListViewController.DEFAULTS_STARTED_OPTIONAL_ACTIVITIES) == nil {
			defaults.set([String](), forKey: RemedyListViewController.DEFAULTS_STARTED_OPTIONAL_ACTIVITIES)
		}
		if defaults.object(forKey: RecordingViewController.DEFAULTS_BLE_DEVICE_NAME) == nil {
			defaults.set("BT05", forKey: RecordingViewController.DEFAULTS_BLE_DEVICE_NAME)
		}
		if defaults.object(forKey: SettingsViewController.DEFAULTS_SEX) == nil {
			defaults.set("Male", forKey: SettingsViewController.DEFAULTS_SEX)
		}
		if defaults.object(forKey: SettingsViewController.DEFAULTS_BIRTHDAY) == nil {
			defaults.set(Date(timeIntervalSinceReferenceDate: 0), forKey: SettingsViewController.DEFAULTS_BIRTHDAY)
		}
		if defaults.object(forKey: SettingsViewController.DEFAULTS_HEIGHT) == nil {
			defaults.set(Double(1.80), forKey: SettingsViewController.DEFAULTS_HEIGHT)
		}
		if defaults.object(forKey: SettingsViewController.DEFAULTS_WEIGHT) == nil {
			defaults.set(Double(70.00), forKey: SettingsViewController.DEFAULTS_WEIGHT)
		}


		self.navigationItem.title = "Cardio Debug"

		if let navController = self.navigationController {
			// http://stackoverflow.com/a/18969325/2603230
			navController.navigationBar.setBackgroundImage(UIImage(), for: .default)
			navController.navigationBar.shadowImage = UIImage()
			navController.navigationBar.isTranslucent = true
			navController.navigationBar.tintColor = StoredColor.middleBlue
		}


		upperButtonOuterView.circleColor = circleColor
		upperButtonOuterView.backgroundColor = circleBackgroundColor
		upperButtonOuterView.addTapGesture(1, target: self, action: #selector(self.clickUpperButton))
		upperButton.setTitleColor(buttonColor, for: .normal)
		upperButton.setTitleColor(disabledButtonColor, for: .disabled)
		upperButton.titleLabel?.textAlignment = .center
		upperButton.titleLabel?.lineBreakMode = .byWordWrapping
		upperButton.setTitle("Start\nActivity", for: .normal)
		upperButton.addTarget(self, action: #selector(self.startActivityAction), for: .touchUpInside)

		middleButtonOuterView.circleColor = circleColor
		middleButtonOuterView.backgroundColor = circleBackgroundColor
		middleButtonOuterView.addTapGesture(1, target: self, action: #selector(self.clickMiddleButton))
		middleButton.setTitleColor(buttonColor, for: .normal)
		middleButton.setTitleColor(disabledButtonColor, for: .disabled)
		middleButton.titleLabel?.textAlignment = .center
		middleButton.titleLabel?.lineBreakMode = .byWordWrapping
		middleButton.setTitle("Finish\nActivity", for: .normal)
		middleButton.addTarget(self, action: #selector(self.finishActivityAction), for: .touchUpInside)

		lowerButtonOuterView.circleColor = circleColor
		lowerButtonOuterView.backgroundColor = circleBackgroundColor
		lowerButtonOuterView.addTapGesture(1, target: self, action: #selector(self.clickLowerButton))
		lowerButton.setTitleColor(buttonColor, for: .normal)
		lowerButton.setTitleColor(disabledButtonColor, for: .disabled)
		lowerButton.titleLabel?.textAlignment = .center
		lowerButton.titleLabel?.lineBreakMode = .byWordWrapping
		lowerButton.setTitle("Record\nECG", for: .normal)




		upperTriangleView.triangleColor = triangleColor
		upperTriangleView.backgroundColor = triangleBackgroundColor

		lowerTriangleView.triangleColor = triangleColor
		lowerTriangleView.backgroundColor = triangleBackgroundColor




		if #available(iOS 10.0, *) {
			let center = UNUserNotificationCenter.current()
			center.requestAuthorization(options: [.alert, .badge, .sound]){ (granted, error) in
				if self.defaults.object(forKey: AppDelegate.DEFAULTS_NOTIFICATION_REGISTERED) == nil {
					self.defaults.set(true, forKey: AppDelegate.DEFAULTS_NOTIFICATION_REGISTERED)
					print("已註冊UserNotification")
				}
			}

			let category = UNNotificationCategory(identifier: NOTIFICATION_CATEGORY_DO_REMEDY_ID, actions: [], intentIdentifiers: [], options: [])
			center.setNotificationCategories([category])

			center.delegate = self
		} else {
			let notificationCategory = UIMutableUserNotificationCategory()
			notificationCategory.identifier = NOTIFICATION_CATEGORY_DO_REMEDY_ID
			notificationCategory.setActions([], for: .minimal)
			notificationCategory.setActions([], for: .default)

			application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: (NSSet(array: [notificationCategory])) as? Set<UIUserNotificationCategory>))
		}

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		print("VC viewWillAppear")
		var didSelectActivity = false
		var labelText = ""
		if let currentActivity = defaults.string(forKey: RemedyListViewController.DEFAULTS_CURRENT_ACTIVITY) {
			if let fullData = defaults.object(forKey: RemedyListViewController.DEFAULTS_ACTIVITIES_DATA) as? [String: Any] {
				if let data = fullData["required"] as? [String: Any] {
					if let activityData = data[currentActivity] as? [String: Any] {
						if let title = activityData["title"] as? String, let icon = activityData["icon"] as? String {
							didSelectActivity = true
							labelText = "Selected: \(title) \(icon)"
						}
					}
				}
			}
		}

		if didSelectActivity {
			mainLabel.text = "\(labelText)"
			mainLabel.textColor = UIColor.black

			var startButtonEnabled = true
			var finishButtonEnabled = false
			if let startDate = defaults.object(forKey: Self.DEFAULTS_ACTIVITY_START_DATE) as? Date {
				if HelperFunctions.isDateSameDay(startDate, Date()) {
					startButtonEnabled = false
					finishButtonEnabled = true
				}
				/*if let endDate = defaults.object(forKey: Self.DEFAULTS_ACTIVITY_END_DATE) as? Date {
					if (HelperFunctions.isDateSameDay(startDate, endDate)) && (HelperFunctions.isDateSameDay(startDate, Date())) {
						//startButtonEnabled = false
						//finishButtonEnabled = false
					}
				}*/
			}
			upperButton.isEnabled = startButtonEnabled
			middleButton.isEnabled = finishButtonEnabled
		} else {
			mainLabel.text = "Select your activity in \"Remedy\""
			mainLabel.textColor = UIColor.red

			upperButton.isEnabled = false
			middleButton.isEnabled = false
		}


		HealthManager.authorizeHealthKit { (success, error) -> Void in
			if success {
				print("success authorizeHealthKit")
			} else {
				print("failed: \(String(describing: error?.localizedDescription))")
			}
		}


		NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	// MARK: - life cycle
	func didEnterBackground() {
		print("準備加載 View Controller 之 didEnterBackground()")

		var notificationsToBeSent = [NotificationInfo]()
		// testing only
		//notificationsToBeSent = addNotificationTo(inputDict: notificationsToBeSent, time: Date().addingTimeInterval(5), message: "Let's start to do an exercise to improve your ANS! :)")

		initNotifications(notificationsToBeSent)
	}


	// MARK: - notification related
	func addNotificationTo(inputDict: [NotificationInfo], time: Date, message: String, categoryIdentifier: String? = nil) -> [NotificationInfo] {
		var dict = inputDict
		if time > Date() {
			dict.append(NotificationInfo(time: time, message: message, categoryIdentifier: categoryIdentifier))
		}
		return dict
	}

	func initNotifications(_ notificationsToBeSent: [NotificationInfo]) {
		if #available(iOS 10.0, *) {
			let notificationCenter = UNUserNotificationCenter.current()
			for info in notificationsToBeSent {
				let date = info.time
				let message = info.message

				let notificationContent = UNMutableNotificationContent()
				notificationContent.body = message
				notificationContent.sound = UNNotificationSound.default()
				if let categoryIdentifier = info.categoryIdentifier {
					notificationContent.categoryIdentifier = categoryIdentifier
				}

				let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: date.timeIntervalSinceNow, repeats: false)
				let notificationRequest = UNNotificationRequest(identifier: "\(date)", content: notificationContent, trigger: notificationTrigger)

				notificationCenter.add(notificationRequest, withCompletionHandler: nil)
			}
		} else {
			for info in notificationsToBeSent {
				let date = info.time
				let message = info.message

				let notification = UILocalNotification()
				notification.fireDate = date
				notification.alertBody = message
				notification.soundName = UILocalNotificationDefaultSoundName
				if let categoryIdentifier = info.categoryIdentifier {
					notification.category = categoryIdentifier
				}

				application.scheduleLocalNotification(notification)
			}
		}
	}

	@available(iOS 10.0, *)
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		print("準備加載 View Controller 之 userNotificationCenter didReceiveNotificationResponse()")

		Async.main {
			self.performSegue(withIdentifier: RemedyListViewController.SHOW_REMEDY_SEGUE_ID, sender: self)
		}

		completionHandler()
	}



	func clickUpperButton() {
		if upperButton.isEnabled {
			Async.main {
				self.upperButton.sendActions(for: .touchUpInside)
			}
		}
	}
	func clickMiddleButton() {
		if middleButton.isEnabled {
			Async.main {
				self.middleButton.sendActions(for: .touchUpInside)
			}
		}
	}
	func clickLowerButton() {
		if lowerButton.isEnabled {
			Async.main {
				self.lowerButton.sendActions(for: .touchUpInside)
			}
		}
	}

	func startActivityAction() {
		defaults.set(Date(), forKey: Self.DEFAULTS_ACTIVITY_START_DATE)
		upperButton.isEnabled = false
		middleButton.isEnabled = true
		showHudWithImage(text: "Started", imageName: "Checkmark")
	}

	func finishActivityAction() {
		if let startDate = defaults.object(forKey: Self.DEFAULTS_ACTIVITY_START_DATE) as? Date, let currentActivity = defaults.string(forKey: RemedyListViewController.DEFAULTS_CURRENT_ACTIVITY) {
			let endDate = Date()
			if HelperFunctions.isDateSameDay(startDate, endDate) {
				defaults.set(endDate, forKey: Self.DEFAULTS_ACTIVITY_END_DATE)

				let realm = try! Realm()
				let activityData = ActivityData()
				activityData.id = currentActivity
				activityData.startDate = startDate
				activityData.endDate = endDate
				try! realm.write {
					realm.add(activityData)
				}

				defaults.set(Date(timeIntervalSinceReferenceDate: 0), forKey: Self.DEFAULTS_ACTIVITY_START_DATE)
				defaults.set(Date(timeIntervalSinceReferenceDate: 1), forKey: Self.DEFAULTS_ACTIVITY_END_DATE)

				showHudWithImage(text: "Recorded", imageName: "Checkmark")

				upperButton.isEnabled = true
				middleButton.isEnabled = false
			}
		}
	}


	func showHudWithImage(text: String, imageName: String) {
		showHudWithImage(text: text, imageName: imageName, afterDelay: 1.5)
	}
	func showHudWithImage(text: String, imageName: String, afterDelay: TimeInterval) {
		Async.main {
			let tickHud = MBProgressHUD.showAdded(to: self.view, animated: true)
			tickHud.mode = .customView
			let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
			tickHud.customView = UIImageView(image: image)
			tickHud.isSquare = true
			tickHud.label.text = text
			tickHud.hide(animated: true, afterDelay: afterDelay)
		}
	}

}
