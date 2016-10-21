//
//  ViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 21/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import BITalinoBLE

class ViewController: UIViewController, BITalinoBLEDelegate {

	@IBOutlet var stateLabel: UILabel!

	var bitalino: BITalinoBLE!

	var allArr: [Int]!
	var sampleRate: Int!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		allArr = []
		sampleRate = 100

		bitalino = BITalinoBLE.init(uuid: "1AC1F712-C6FE-4728-9BEF-DBD2A6177D47")
		bitalino.delegate = self
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func connectButtonAction(_ sender: AnyObject) {
		if(!bitalino.isConnected){
			stateLabel.text = "..."
			bitalino.scanAndConnect()
		} else{
			bitalino.disconnect()
		}
	}

	@IBAction func startButtonAction(_ sender: AnyObject) {
		if(bitalino.isConnected){
			if(!bitalino.isRecording){
				let inputs: [Int] = [0, 1, 2, 3, 4, 5]

				bitalino.startRecording(fromAnalogChannels: inputs, withSampleRate: sampleRate, numberOfSamples: 50, samplesCompletion: { (frame: BITalinoFrame?) -> Void in
					if let result = frame?.a1 {
						if result != 0 {
							print("\(result)")
							self.allArr.append(result)
						}
					}
				})

			} else{
				bitalino.stopRecording()

				print(allArr.description)
			}
		} else{
			print("NOT CON")
		}
	}


	func bitalinoDidConnect(_ bitalino: BITalinoBLE!) {
		stateLabel.text = "YAYA"
	}

	func bitalinoDidDisconnect(_ bitalino: BITalinoBLE!) {
		stateLabel.text = "NO"
	}

	func bitalinoRecordingStarted(_ bitalino: BITalinoBLE!) {
		print("STARTED")
	}

	func bitalinoRecordingStopped(_ bitalino: BITalinoBLE!) {
		print("ENDED")
	}

	func bitalinoBatteryThresholdUpdated(_ bitalino: BITalinoBLE!) {
		//do
	}

	func bitalinoBatteryDigitalOutputsUpdated(_ bitalino: BITalinoBLE!) {
		//do
	}
	
}
