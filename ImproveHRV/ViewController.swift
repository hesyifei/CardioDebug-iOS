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

	@IBOutlet var mainLabel: UILabel!
	@IBOutlet var mainButton: UIButton!

	var bitalino: BITalinoBLE!

	var timer: Timer!
	var startTime: Date!
	var endTime: Date!

	var rawData: [Int]!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		rawData = []

		bitalino = BITalinoBLE.init(uuid: "1AC1F712-C6FE-4728-9BEF-DBD2A6177D47")
		bitalino.delegate = self
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if bitalino.isConnected {
			if bitalino.isRecording {
				bitalino.stopRecording()
			}
			bitalino.disconnect()
		}

		mainButton.isEnabled = true
		mainButton.setTitle("Connect and Start", for: .normal)
		mainButton.addTarget(self, action: #selector(self.mainButtonAction), for: .touchUpInside)

		mainLabel.text = "Unconnected"
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


	func mainButtonAction() {
		if !bitalino.isConnected {
			mainLabel.text = "Connecting..."
			self.mainButton.isEnabled = false
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
				endTime = startTime.addingTimeInterval(60*5+10)
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

	func stopRecording() {
		bitalino.stopRecording()

		self.mainLabel.text = "Finished"
		mainButton.isEnabled = true

		print(rawData.description)

		self.performSegue(withIdentifier: ResultViewController.SHOW_RESULT_SEGUE_ID, sender: self)
	}

	func timerAction() {
		let timeTill = endTime.timeIntervalSinceNow
		//print(timeTill)
		if timeTill <= 0 {
			mainLabel.text = "00:00"
			if let _ = timer {
				timer?.invalidate()
				timer = nil
			}
			self.stopRecording()
		} else {
			let (h, m, s) = HelperFunctions.secondsToHoursMinutesSeconds(Int(endTime.timeIntervalSinceNow))
			if h > 0 {
				mainLabel.text = String(format: "%d:%02d:%02d", h, m, s)
			} else {
				mainLabel.text = String(format: "%02d:%02d", m, s)
			}
		}
	}


	func bitalinoDidConnect(_ bitalino: BITalinoBLE!) {
		mainLabel.text = "Connected"
		print("Connected")
		HelperFunctions.delay(1.0) {
			self.startRecording()
		}
	}

	func bitalinoDidDisconnect(_ bitalino: BITalinoBLE!) {
		print("Disconnected")
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

}
