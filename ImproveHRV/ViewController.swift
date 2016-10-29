//
//  ViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 21/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Async
import BITalinoBLE
import Charts

class ViewController: UIViewController, BITalinoBLEDelegate {

	// MARK: - basic var
	let application = UIApplication.shared

	// MARK: - IBOutlet var
	@IBOutlet var mainLabel: UILabel!
	@IBOutlet var mainButton: UIButton!
	@IBOutlet var upperLabel: UILabel!

	@IBOutlet var mainButtonOuterView: CircleView!
	@IBOutlet var mainButtonOuterViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet var mainButtonOuterViewCenterYConstraint: NSLayoutConstraint!

	// MARK: - init var
	var bitalino: BITalinoBLE!

	var timer: Timer!
	var startTime: Date!
	var endTime: Date!

	// MARK: - data var
	var rawData: [Int]!


	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()


		rawData = []


		bitalino = BITalinoBLE.init(uuid: "1AC1F712-C6FE-4728-9BEF-DBD2A6177D47")
		bitalino.delegate = self


		self.view.backgroundColor = getBackgroundColor()

		mainLabel.textColor = getElementColor()
		mainLabel.alpha = 0.0

		upperLabel.alpha = 0.0
		upperLabel.textColor = getElementColor()

		mainButtonOuterView.circleColor = getButtonBackgroundColor()
		mainButtonOuterView.backgroundColor = UIColor.clear

		mainButton.setTitleColor(getButtonElementColor(), for: .normal)

		Async.main {
			self.adjustFontSize()
		}

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if bitalino.isConnected {
			if bitalino.isRecording {
				bitalino.stopRecording()
			}
			bitalino.disconnect()
		}


		enableButtons()
		mainButton.setTitle("Start", for: .normal)
		mainButton.addTarget(self, action: #selector(self.mainButtonAction), for: .touchUpInside)
		mainButtonOuterView.addTapGesture(1, target: self, action: #selector(self.mainButtonAction))

		mainLabel.text = "Unconnected"
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
			let orient = self.application.statusBarOrientation

			self.adjustFontSize()

			self.adjustAppropriateMainButtonOuterViewHeightConstraintConstantToSmallSize()
			self.view.layoutIfNeeded()

		}, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
			// Finish Transition
		})

		super.viewWillTransition(to: size, with: coordinator)
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == ResultViewController.SHOW_RESULT_SEGUE_ID {
			if let destination = segue.destination as? ResultViewController {
				destination.rawData = self.rawData
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	// MARK: - UI related func
	func mainButtonAction() {
		setupViewAndStartConnect()
	}


	func adjustFontSize() {
		print("adjustFontSize()")
		let screenSize: CGRect = UIScreen.main.bounds

		var basicFontSizeBasedOnScreenHeight = screenSize.height
		if UIDevice.current.userInterfaceIdiom == .phone {
			if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
				// Value is based on test
				basicFontSizeBasedOnScreenHeight = basicFontSizeBasedOnScreenHeight * 1.7
			}
			if HelperFunctions.getInchFromWidth() == 3.5 {
				if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
					// Value is based on test
					basicFontSizeBasedOnScreenHeight = basicFontSizeBasedOnScreenHeight * 1.3
				}
			}
		}
		if UIDevice.current.userInterfaceIdiom == .pad {
			if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
				// Value is based on test
				basicFontSizeBasedOnScreenHeight = basicFontSizeBasedOnScreenHeight * 0.8
			}
		}

		mainLabel.font = UIFont(name: (mainLabel.font?.fontName)!, size: basicFontSizeBasedOnScreenHeight*0.09)
		upperLabel.font = UIFont(name: (mainLabel.font?.fontName)!, size: basicFontSizeBasedOnScreenHeight*0.03)
		mainButton.titleLabel!.font = UIFont(name: (mainButton.titleLabel!.font?.fontName)!, size: basicFontSizeBasedOnScreenHeight*0.025)
	}

	func adjustAppropriateMainButtonOuterViewHeightConstraintConstantToSmallSize() {
		print("adjustAppropriateMainButtonOuterViewHeightConstraintConstantToSmallSize()")
			var constantToBeSet: CGFloat = 0.0
			if UIDevice.current.userInterfaceIdiom == .phone {
				if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
					// Value is based on test
					constantToBeSet = 25
				}
			}
			if UIDevice.current.userInterfaceIdiom == .pad {
				if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
					// Value is based on test
					constantToBeSet = -25
				}
			}
			mainButtonOuterViewHeightConstraint.constant = constantToBeSet
	}


	func enableButtons() {
		mainButton.alpha = 1.0
		mainButton.isEnabled = true
		mainButton.isUserInteractionEnabled = true
		mainButtonOuterView.isUserInteractionEnabled = true
	}

	func disableButtons() {
		mainButton.alpha = 0.5
		mainButton.isEnabled = false
		mainButton.isUserInteractionEnabled = false
		mainButtonOuterView.isUserInteractionEnabled = false
	}

	func setupViewAndStartConnect() {
		print("setupViewAndStartConnect()")

		Async.main {
			self.view.layoutIfNeeded()

			let constantToBeLower: [Float: CGFloat] = [
				3.5: 45.0,
				4.0: 60.0,
				4.7: 70.0,
				5.5: 80.0,
				99.9: 80.0
			]
			self.mainButtonOuterViewCenterYConstraint.constant = self.mainLabel.frame.height / 2.0 + constantToBeLower[HelperFunctions.getInchFromWidth()]!
			self.adjustAppropriateMainButtonOuterViewHeightConstraintConstantToSmallSize()

			//self.mainButton.setTitle(NSLocalizedString("Main.Button.MainButton.Stop", comment: "Stop"), for: .normal)

			self.disableButtons()

			self.view.setNeedsUpdateConstraints()
			UIView.animate(withDuration: 1.0, animations: {
				self.view.layoutIfNeeded()
			}, completion: { (complete: Bool) in
				self.startConnect()
				UIView.animate(withDuration: 1.0, animations: {
					self.mainLabel.alpha = 1.0
					self.upperLabel.alpha = 1.0
				}, completion: { (complete: Bool) in
					// DO NOTHING
				})
			})
		}
	}

	func setupViewAndStopRecording(isNormalCondition: Bool) {

		// Async main here to make sure the animation is shown
		Async.main {
			UIView.animate(withDuration: 1.0, animations: {
				self.mainLabel.alpha = 0.0
				self.upperLabel.alpha = 0.0
			}, completion: { (complete: Bool) in

				// make sure that the labels are really transparent
				self.mainLabel.alpha = 0.0
				self.upperLabel.alpha = 0.0


				self.view.layoutIfNeeded()
				self.mainButtonOuterViewCenterYConstraint.constant = 0
				self.mainButtonOuterViewHeightConstraint.constant = 50
				//self.mainButton.setTitle(NSLocalizedString("Main.Button.MainButton.Start", comment: "Start"), for: .normal)

				self.view.setNeedsUpdateConstraints()
				UIView.animate(withDuration: 1.0, animations: {
					self.view.layoutIfNeeded()
				}, completion: { (complete: Bool) in
					self.setBackgroundColorWithAnimation(self.getBackgroundColor())

					self.stopRecording(isNormalCondition: isNormalCondition)
				})

			})
		}
		
	}

	func startConnect() {
		if !bitalino.isConnected {
			mainLabel.text = "Connecting..."
			bitalino.scanAndConnect()
		}
	}

	func startRecording() {
		if bitalino.isConnected {
			if !bitalino.isRecording {
				rawData = []

				//self.mainLabel.text = "Recording..."

				timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
				startTime = Date.init()
				endTime = startTime.addingTimeInterval(10)
				self.timerAction()		// 為避免延遲一秒才開始執行


				bitalino.startRecording(fromAnalogChannels: [0, 1, 2, 3, 4, 5], withSampleRate: 100, numberOfSamples: 50, samplesCompletion: { (frame: BITalinoFrame?) -> Void in
					if let result = frame?.a1 {
						if result != 0 {
							print("\(result)")
							self.rawData.append(result)
						} else {
							print("0 SO SAD")
						}
					}
				})
			}
		}
	}

	func stopRecording(isNormalCondition: Bool) {
		if isNormalCondition {
			bitalino.stopRecording()

			//self.mainLabel.text = "Finished"

			print(rawData.description)

			self.performSegue(withIdentifier: ResultViewController.SHOW_RESULT_SEGUE_ID, sender: self)
		} else {
			print("not NormalCondition")
		}

		self.enableButtons()
	}

	func timerAction() {
		let timeTill = endTime.timeIntervalSinceNow
		//print(timeTill)
		if timeTill <= 0 {
			self.stopTimer()
			self.setupViewAndStopRecording(isNormalCondition: true)
		} else {
			let (h, m, s) = HelperFunctions.secondsToHoursMinutesSeconds(Int(endTime.timeIntervalSinceNow))
			if h > 0 {
				mainLabel.text = String(format: "%d:%02d:%02d", h, m, s)
			} else {
				mainLabel.text = String(format: "%02d:%02d", m, s)
			}
		}
	}

	func stopTimer() {
		mainLabel.text = "00:00"
		if let _ = timer {
			timer?.invalidate()
			timer = nil
		}
	}


	// MARK: - bitalino related func
	func bitalinoDidConnect(_ bitalino: BITalinoBLE!) {
		mainLabel.text = "Connected :)"
		print("Connected")
		HelperFunctions.delay(1.0) {
			self.startRecording()
		}
	}

	func bitalinoDidDisconnect(_ bitalino: BITalinoBLE!) {
		print("Disconnected")
		if !mainButton.isEnabled {
			self.stopTimer()
			mainLabel.text = "Disconnected :("
			HelperFunctions.delay(1.0) {
				self.setupViewAndStopRecording(isNormalCondition: false)
			}
		}
		//mainLabel.text = "NO"
	}

	func bitalinoRecordingStarted(_ bitalino: BITalinoBLE!) {
		//print("Recording Started")
	}

	func bitalinoRecordingStopped(_ bitalino: BITalinoBLE!) {
		HelperFunctions.delay(1.0) {
			bitalino.disconnect()
		}
	}

	func bitalinoBatteryThresholdUpdated(_ bitalino: BITalinoBLE!) {
		//do
	}

	func bitalinoBatteryDigitalOutputsUpdated(_ bitalino: BITalinoBLE!) {
		//do
	}



	// MARK: - helper func
	func setBackgroundColorWithAnimation(_ color: UIColor, duration: TimeInterval = 0.2) {
		if self.view.backgroundColor != color {
			UIView.animate(withDuration: duration, animations: { () -> Void in
				self.view.backgroundColor = color
			})
		}
	}


	// MARK: - style func
	func getBackgroundColor() -> UIColor {
		return UIColor(netHex: 0xC8FFC8)
	}
	func getElementColor() -> UIColor {
		return UIColor.black
	}

	func getButtonBackgroundColor() -> UIColor {
		return UIColor(netHex: 0x1C1C1C)
	}
	func getButtonElementColor() -> UIColor {
		return UIColor.white
	}

	func getElementColorString() -> String {
		return "Black"
	}

}
