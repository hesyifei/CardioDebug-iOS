//
//  RecordingViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 21/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import CoreBluetooth
import Async
import BITalinoBLE
import Charts

enum DeviceType {
	case ble
	case bitalino
}

class RecordingViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, BITalinoBLEDelegate {

	// MARK: - static var
	static let DEFAULTS_BLE_DEVICE_NAME = "bleDeviceName"

	// MARK: - basic var
	let application = UIApplication.shared
	let defaults = UserDefaults.standard

	fileprivate typealias `Self` = RecordingViewController

	// MARK: - IBOutlet var
	@IBOutlet var mainLabel: UILabel!
	@IBOutlet var mainButton: UIButton!
	@IBOutlet var upperLabel: UILabel!

	@IBOutlet var mainButtonOuterView: CircleView!
	@IBOutlet var mainButtonOuterViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet var mainButtonOuterViewCenterYConstraint: NSLayoutConstraint!

	@IBOutlet var chartView: LineChartView!

	// MARK: - init var
	var manager: CBCentralManager!
	var peripheral: CBPeripheral!

	var bitalino: BITalinoBLE!

	var timer: Timer!
	var startTime: Date!
	var endTime: Date!
	var duration: TimeInterval!

	var currentState: Int = 0

	var isConnectedAndRecording: Bool!

	// MARK: - data var
	var rawData: [Int]!

	var deviceType: DeviceType!


	let frequency: Int = 100

	let extraPreTime: TimeInterval = 15.0

	let BITALINO_DEVICE_UUID = "1AC1F712-C6FE-4728-9BEF-DBD2A6177D47"



	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()



		self.title = "Record"




		rawData = []

		deviceType = .ble



		manager = CBCentralManager(delegate: self, queue: nil)

		bitalino = BITalinoBLE.init(uuid: BITALINO_DEVICE_UUID)
		bitalino.delegate = self



		mainLabel.alpha = 0.0
		mainLabel.textColor = getElementColor()

		upperLabel.alpha = 0.0
		upperLabel.textColor = getElementColor()

		mainButtonOuterView.circleColor = getButtonBackgroundColor()
		mainButtonOuterView.backgroundColor = UIColor.clear

		mainButton.setTitleColor(getButtonElementColor(), for: .normal)

		Async.main {
			self.adjustFontSize()
		}


		isConnectedAndRecording = false


		currentState = 0

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if bitalino.isConnected {
			if bitalino.isRecording {
				bitalino.stopRecording()
			}
			bitalino.disconnect()
		}
		isConnectedAndRecording = false


		enableButtons()
		mainButton.setTitle("Start", for: .normal)
		mainButton.addTarget(self, action: #selector(self.mainButtonAction), for: .touchUpInside)
		mainButtonOuterView.addTapGesture(1, target: self, action: #selector(self.mainButtonAction))

		mainLabel.text = "Unconnected"


		NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

		initChart()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
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
			if let destinationNavigationController = segue.destination as? UINavigationController {
				if let destination = destinationNavigationController.topViewController as? ResultViewController {

					//rawData = [525, 522, 527, 527, 520, 526, 523, 531, 532, 535, 534, 536, 538, 541, 540, 548, 544, 544, 543, 532, 519, 505, 486, 476, 467, 463, 460, 468, 487, 515, 506, 492, 478, 483, 475, 478, 488, 508, 502, 497, 497, 498, 500, 506, 507, 506, 502, 511, 508, 516, 508, 513, 515, 521, 519, 524, 519, 525, 501, 518, 504, 497, 499, 556, 595, 540, 476, 441, 468, 499, 518, 528, 521, 528, 526, 535, 527, 530, 525, 533, 534, 543, 538, 547, 529, 535, 538, 544, 537, 532, 515, 502, 483, 477, 463, 470, 464, 470, 475, 479, 485, 489, 493, 497, 493, 501, 499, 502, 501, 504, 503, 505, 504, 506, 504, 509, 503, 508, 505, 510, 504, 511, 510, 527, 515, 515, 523, 522, 526, 530, 526, 483, 486, 494, 499, 509, 504, 505, 552, 592, 530, 470, 438, 472, 495, 517, 522, 531, 537, 515, 521, 523, 519, 529, 527, 547, 545, 556, 548, 526, 524, 526, 528, 531, 530, 520, 501, 488, 472, 467, 461, 465, 465, 474, 477, 487, 484, 484, 487, 494, 492, 498, 497, 500, 501, 510, 503, 501, 504, 504, 505, 509, 509, 513, 508, 509, 509, 513, 512, 513, 511, 515, 510, 509, 510, 519, 519, 526, 520, 524, 520, 511, 504, 508, 505, 508, 505, 562, 592, 525, 460, 440, 472, 519, 526, 513, 511, 521, 523, 528, 527, 528, 527, 531, 530, 537, 531, 541, 537, 543, 543, 542, 535, 535, 517, 506, 481, 474, 468, 476, 448, 462, 467, 475, 470, 487, 487, 499, 490, 499, 492, 507, 502, 513, 502, 501, 497, 499, 494, 507, 502, 507, 500, 507, 509, 515, 515, 519, 514, 520, 513, 520, 503, 508, 505, 512, 507, 511, 552, 599, 528, 463, 444, 467, 492, 517, 515, 528, 526, 523, 520, 526, 526, 527, 526, 532, 529, 542, 532, 541, 541, 546, 531, 539, 522, 516, 492, 486, 473, 473, 463, 467, 471, 477, 477, 491, 487, 493, 486, 499, 498, 495, 494, 507, 496, 504, 499, 508, 500, 509, 503, 513, 508, 514, 510, 512, 514, 515, 509, 515, 517, 524, 521, 524, 519, 517, 503, 504, 504, 511, 505, 568, 585, 513, 453, 441, 485, 505, 518, 523, 524, 527, 525, 533, 527, 524, 525, 526, 529, 534, 537, 536, 545, 548, 545, 543, 539, 528, 514, 496, 485, 471, 460, 456, 462, 469, 476, 481, 483, 484, 492, 494, 494, 496, 498, 502, 500, 495, 502, 500, 500, 504, 504, 507, 513, 507, 495, 510, 510, 511, 507, 512, 511, 520, 510, 512, 519, 532, 523, 523, 523, 515, 504, 505, 505, 505, 504, 539, 594, 478, 560, 429, 489, 510, 458, 521, 522, 527, 528, 529, 528, 534, 532, 533, 535, 533, 532, 537, 537, 546, 543, 543, 541, 534, 529, 517, 485, 480, 460, 461, 459, 472, 471, 481, 474, 481, 486, 494, 491, 499, 486, 506, 495, 497, 493, 509, 507, 509, 500, 509, 499, 507, 499, 515, 511, 518, 503, 510, 514, 516, 520, 523, 519, 517, 518, 504, 500, 508, 508, 512, 514, 578, 587, 506, 432, 449, 474, 510, 516, 521, 519, 526, 525, 534, 526, 531, 523, 532, 530, 539, 535, 543, 541, 549, 539, 542, 533, 535, 508, 497, 479, 473, 457, 467, 462, 473, 470, 483, 481, 495, 487, 492, 491, 497, 497, 507, 495, 507, 498, 515, 492, 506, 494, 510, 504, 514, 504, 510, 508, 518, 510, 526, 517, 529, 512, 507, 498, 506, 499, 507, 499, 572, 591, 530, 439, 446, 469, 504, 514, 527, 518, 530, 523, 538, 522, 530, 520, 532, 527, 540, 534, 548, 538, 550, 539, 544, 530, 532, 511, 500, 472, 473, 461, 470, 466, 473, 471, 478, 474, 494, 495, 499, 495, 500, 492, 508, 495, 515, 489, 499, 496, 499, 502, 512, 505, 505, 502, 512, 505, 515, 509, 516, 521, 525, 523, 523, 502, 508, 502, 511, 504, 511, 568, 597, 508, 452, 434, 479, 503, 525, 520, 524, 524, 522, 519, 528, 523, 532, 526, 539, 533, 542, 537, 551, 548, 547, 539, 542, 516, 519, 489, 488, 471, 468, 459, 469, 467, 477, 469, 485, 484, 494, 488, 497, 492, 498, 491, 498, 499, 504, 505, 500, 502, 509, 503, 506, 503, 511, 505, 508, 512, 511, 502, 514, 509, 522, 517, 527, 526, 519, 507, 511, 498, 512, 501, 549, 594, 548, 470, 434, 461, 494, 513, 529, 521, 536, 525, 525, 519, 535, 527, 533, 529, 537, 538, 548, 542, 545, 542, 546, 540, 534, 518, 504, 481, 476, 462, 463, 462, 468, 470, 478, 476, 487, 489, 496, 493, 501, 496, 507, 496, 499, 500, 504, 499, 505, 500, 510, 504, 512, 508, 508, 505, 508, 509, 514, 512, 531, 522, 524, 513, 508, 502, 511, 501, 502, 507, 579, 592, 522, 432, 451, 470, 503, 518, 529, 521, 532, 519, 535, 527, 529, 544, 530, 529, 532, 517, 533, 543, 556, 551, 536, 511, 516, 505, 494, 477, 471, 461, 476, 470, 471, 465, 479, 483, 498, 479, 497, 490, 492, 496, 502, 500, 509, 507, 512, 508, 500, 502, 515, 502, 512, 500, 512, 512, 512, 506, 514, 509, 520, 512, 521, 522, 527, 520, 524, 508, 511, 503, 509, 503, 515, 572, 596, 512, 452, 435, 477, 518, 527, 512, 529, 523, 524, 518, 527, 527, 534, 529, 536, 533, 541, 536, 547, 543, 545, 540, 543, 531, 531, 491, 481, 473, 457, 453, 465, 466, 477, 477, 489, 484, 497, 487, 489, 494, 497, 503, 503, 499, 509, 495, 491, 502, 504, 504, 508, 508, 509, 511, 507, 505, 499, 509, 512, 512, 518, 517, 518, 526, 520, 520, 522, 517, 512, 506, 510, 511, 502, 529, 588, 559, 482, 422, 455, 490, 515, 523, 526, 526, 527, 526, 527, 527, 528, 531, 532, 535, 538, 537, 547, 540, 544, 539, 544, 534, 528, 510, 493, 468, 465, 458, 463, 467, 471, 470, 485, 479, 490, 486, 490, 489, 492, 493, 500, 497, 502, 498, 502, 503, 514, 508, 508, 508, 509, 503, 508, 510, 507, 501, 510, 517, 529, 521, 529, 521, 509, 502, 507, 502, 504, 524, 595, 581, 496, 426, 453, 480, 507, 518, 525, 525, 537, 528, 525, 521, 524, 523, 530, 531, 536, 534, 543, 542, 547, 541, 541, 529, 527, 503, 500, 476, 473, 462, 461, 460, 460, 469, 477, 486, 490, 491, 496, 494, 497, 496, 501, 502, 505, 504, 499, 500, 499, 500, 507, 504, 508, 505, 509, 512, 526, 543, 518, 504, 516, 508, 502, 504, 508, 524, 500, 586, 577, 524, 448, 424, 459, 496, 518, 528, 523, 521, 527, 525, 528, 530, 534, 534, 529, 536, 541, 547, 542, 537, 542, 545, 541, 534, 518, 501, 481, 467, 455, 459, 467, 468, 471, 477, 483, 487, 492, 492, 496, 499, 499, 502, 500, 502, 503, 503, 504, 506, 504, 507, 509, 508, 509, 510, 512, 519, 515, 515, 520, 519, 521, 520, 515, 508, 508, 505, 508, 500, 536, 597, 560, 480, 427, 458, 491, 519, 524, 522, 524, 526, 527, 529, 532, 531, 530, 533, 536, 540, 540, 544, 548, 550, 545, 545, 536, 526, 508, 485, 469, 454, 457, 460, 467, 473, 479, 481, 483, 486, 487, 494, 496, 497, 499, 499, 499, 502, 503, 501, 505, 507, 504, 506, 508, 509, 508, 511, 510, 519, 521, 521, 519, 518, 504, 505, 502, 506, 498, 521, 587, 588, 502, 427, 446, 479, 503, 520, 519, 523, 525, 524, 524, 527, 527, 530, 534, 536, 536, 538, 538, 545, 542, 541, 537, 534, 525, 508, 484, 463, 459, 461, 463, 475, 473, 470, 475, 483, 483, 494, 496, 496, 500, 497, 492, 500, 498, 500, 503, 502, 504, 504, 502, 504, 505, 502, 506, 516, 518, 525, 517, 515, 508, 507, 499, 506, 503, 514, 577, 596, 521, 437, 444, 474, 503, 523, 522, 524, 525, 527, 528, 531, 529, 533, 533, 535, 534, 539, 542, 543, 542, 544, 540, 539, 527, 512, 492, 480, 463, 461, 462, 467, 472, 481, 484, 489, 491, 494, 493, 497, 497, 500, 499, 503, 504, 504, 502, 505, 505, 505, 504, 506, 507, 510, 509, 510, 513, 516, 517, 526, 523, 525, 519, 507, 504, 507, 503, 504, 511, 573, 588, 507, 438, 441, 480, 507, 519, 524, 521, 526, 524, 530, 527, 531, 527, 531, 531, 537, 539, 542, 544, 547, 545, 545, 536, 530, 512, 495, 476, 467, 459, 463, 463, 470, 473, 480, 483, 488, 489, 496, 496, 498, 495, 498, 498, 501, 501, 507, 500, 508, 504, 508, 505, 507, 504, 510, 505, 512, 509, 516, 523, 526, 519, 519, 506, 507, 502, 506, 503, 511, 571, 599, 515, 442, 435, 479, 503, 522, 522, 529, 525, 526, 527, 529, 527, 532, 530, 536, 534, 537, 539, 546, 541, 545, 540, 537, 526, 513, 491, 480, 463, 464, 462, 469, 468, 480, 476, 485, 486, 490, 491, 500, 496, 498, 497, 502, 495, 502, 500, 506, 500, 504, 500, 514, 500, 508, 511, 523, 516, 522, 513, 511, 505, 508, 501, 507, 510, 577, 591, 527, 439, 452, 468, 499, 512, 518, 517, 526, 522, 528, 520, 527, 525, 534, 523, 534, 532, 544, 539, 541, 540, 544, 536, 528, 505, 493, 474, 467, 463, 470, 467, 480, 486, 485, 484, 490, 496, 510, 500, 497, 488, 492, 492, 503, 503, 518, 513, 511, 507, 512, 507, 516, 522, 523, 523, 521, 512, 507, 507, 507, 500, 504, 533, 595, 558, 496, 435, 465, 491, 519, 511, 518, 523, 527, 526, 531, 522, 532, 522, 531, 528, 536, 534, 541, 535, 543, 537, 540, 527, 520, 499, 486, 470, 468, 457, 471, 465, 477, 472, 485, 480, 489, 484, 491, 479, 483, 484, 492, 489, 507, 507, 518, 511, 508, 508, 512, 511, 516, 518, 520, 524, 532, 519]

					let passedData = PassECGResult()
					passedData.startDate = (startTime ?? Date()).addingTimeInterval(extraPreTime)
					let extraPreTimeDataCount = Int(extraPreTime)*frequency
					if rawData.count-1 > extraPreTimeDataCount {
						rawData.removeSubrange(0...extraPreTimeDataCount)
					}
					print(rawData.description)
					passedData.rawData = rawData
					passedData.isNew = true

					destination.passedData = passedData

					destination.passedBackData = { bool in
						print("ResultViewController passedBackData \(bool)")
						if bool == true {
							Async.main(after: 0.5) {
								self.mainButtonAction()
							}
						}
					}

				}
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	// MARK: - app life cycle related func
	func didEnterBackground() {
		print("didEnterBackground()")
		stopTimer()
		setupViewAndStopRecording(isNormalCondition: false)
		if isConnectedAndRecording == true {
			bitalino.stopRecording()
			print("isConnectedAndRecording true")
			//bitalino.disconnect()
		}
	}


	// MARK: - UI related func
	func initChart() {
		chartView.setViewPortOffsets(left: 0.0, top: 20.0, right: 0.0, bottom: 20.0)

		chartView.isUserInteractionEnabled = false
		chartView.noDataText = "No chart data available."
		chartView.chartDescription?.text = ""
		chartView.scaleXEnabled = false
		chartView.scaleYEnabled = false
		chartView.legend.enabled = false


		let rightAxis = chartView.rightAxis
		rightAxis.drawLabelsEnabled = false
		rightAxis.drawAxisLineEnabled = false
		rightAxis.drawGridLinesEnabled = false


		let leftAxis = chartView.leftAxis
		leftAxis.drawLabelsEnabled = false
		leftAxis.drawAxisLineEnabled = false
		leftAxis.drawGridLinesEnabled = false


		let xAxis = chartView.xAxis
		xAxis.drawAxisLineEnabled = false
		xAxis.drawGridLinesEnabled = false
		xAxis.drawLabelsEnabled = false		// 避免頭暈（太快了）
		//xAxis.labelPosition = .bottom
		//xAxis.valueFormatter = ChartCSDoubleToSecondsStringFormatter()

		let values: [Int] = []

		var dataEntries: [ChartDataEntry] = []
		for (index, value) in values.enumerated() {
			let dataEntry = ChartDataEntry(x: Double(index), y: Double(value))
			dataEntries.append(dataEntry)
		}

		let ecgRawDataSet = LineChartDataSet(values: dataEntries, label: nil)
		ecgRawDataSet.colors = [UIColor.lightGray]
		//ecgRawDataSet.mode = .cubicBezier
		ecgRawDataSet.drawCirclesEnabled = false





		let lineChartData = LineChartData(dataSets: [ecgRawDataSet])
		lineChartData.setDrawValues(false)

		chartView.data = lineChartData
		chartView.data?.highlightEnabled = false
	}



	func mainButtonAction() {
		if currentState < 3 {
			currentState += 1
			//self.performSegue(withIdentifier: ResultViewController.SHOW_RESULT_SEGUE_ID, sender: self)
			setupViewAndStartConnect()
		} else {
			currentState = 0
			self.enableButtons()
		}
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

		self.navigationController?.navigationBar.isUserInteractionEnabled = true
		self.navigationController?.navigationBar.tintColor = self.view.tintColor

		self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
	}

	func disableButtons() {
		mainButton.alpha = 0.5
		mainButton.isEnabled = false
		mainButton.isUserInteractionEnabled = false
		mainButtonOuterView.isUserInteractionEnabled = false

		self.navigationController?.navigationBar.isUserInteractionEnabled = false
		self.navigationController?.navigationBar.tintColor = UIColor.lightGray

		self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
	}

	func setupViewAndStartConnect() {
		print("setupViewAndStartConnect()")

		Async.main {
			self.disableButtons()

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

			self.view.setNeedsUpdateConstraints()
			UIView.animate(withDuration: 1.0, animations: {
				self.view.layoutIfNeeded()
			}, completion: { (complete: Bool) in
				self.startConnect()
				UIView.animate(withDuration: 1.0, animations: {
					self.mainLabel.alpha = 1.0
					self.upperLabel.alpha = 1.0
				}, completion: { (complete: Bool) in
					self.application.isIdleTimerDisabled = true
				})
			})
		}
	}

	func setupViewAndStopRecording(isNormalCondition: Bool) {
		print("setupViewAndStopRecording()")

		// Async main here to make sure the animation is shown
		Async.main {
			self.application.isIdleTimerDisabled = false

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
					//self.setBackgroundColorWithAnimation(self.getBackgroundColor())

					self.stopRecording(isNormalCondition: isNormalCondition)
				})

			})
		}
		
	}

	func startConnect() {
		if deviceType == .bitalino {
			if !bitalino.isConnected {
				mainLabel.text = "Connecting..."
				bitalino.scanAndConnect()
			}
		} else if deviceType == .ble {
			var poweredOn = false
			if #available(iOS 10.0, *) {
				if manager.state == CBManagerState.poweredOn {
					poweredOn = true
				}
			} else {
				if manager.centralManagerState == CBCentralManagerState.poweredOn {
					poweredOn = true
				}
			}
			if poweredOn {
				mainLabel.text = "Connecting..."
				manager.scanForPeripherals(withServices: nil, options: nil)
			} else {
				mainLabel.text = "Please enable BT"
				print("Bluetooth not available")
			}
		}
	}

	func startRecording() {
		var canRecord = true
		if deviceType == .bitalino {
			if !bitalino.isConnected || bitalino.isRecording {
				canRecord = false
			}
		}

		if canRecord {
			//self.mainLabel.text = "Recording..."

			isConnectedAndRecording = true


			timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
			startTime = Date()
			duration = TimeInterval(5*60)+extraPreTime
			endTime = startTime.addingTimeInterval(duration)
			self.timerAction()		// 為避免延遲一秒才開始執行


			if deviceType == .bitalino {
				rawData = []
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
			} else if deviceType == .ble {
				// done in didDiscoverCharacteristicsFor & didUpdateValueFor
			}

		}
	}

	func stopRecording(isNormalCondition: Bool) {
		isConnectedAndRecording = false

		if isNormalCondition {
			if deviceType == .bitalino {
				bitalino.stopRecording()
			} else if deviceType == .ble {
				manager.cancelPeripheralConnection(peripheral)
			}
			//self.mainLabel.text = "Finished"
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


	// MARK: - BLE related func
	// Reference: http://cms.35g.tw/coding/藍牙-ble-corebluetooth-初探/
	//            http://www.kevinhoyt.com/2016/05/20/the-12-steps-of-bluetooth-swift/
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		/*if central.state == CBManagerState.poweredOn {
			central.scanForPeripherals(withServices: nil, options: nil)
		} else {
			print("Bluetooth not available")
		}*/
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		if let name = peripheral.name {
			if name == defaults.string(forKey: Self.DEFAULTS_BLE_DEVICE_NAME) {
				print("Found device \(peripheral.identifier.uuidString)")

				self.manager.stopScan()

				self.peripheral = peripheral
				self.peripheral.delegate = self

				self.manager.connect(peripheral, options: nil)
			}
		}
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		print("Connected to device \(peripheral.name)")
		peripheral.discoverServices(nil)
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		print("Disconnected device \(peripheral.identifier.uuidString)")
		if isConnectedAndRecording == true {
			self.stopTimer()
			mainLabel.text = "Disconnected :("
			HelperFunctions.delay(1.0) {
				self.setupViewAndStopRecording(isNormalCondition: false)
			}
		}
	}


	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		print("didDiscoverServices")
		if let services = peripheral.services {
			print("Services count: \(peripheral.services?.count)")
			for service in services {
				// CBUUID see data in LightBlue
				if service.uuid == CBUUID(string: "FFE0") {
					peripheral.discoverCharacteristics(nil, for: service)
				}
			}
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		print("didDiscoverCharacteristicsFor \(service.uuid)")
		for characteristic in service.characteristics! {
			print("each characteristic: \(characteristic.uuid)")
			// CBUUID see data in LightBlue
			if characteristic.uuid == CBUUID(string: "FFE1") {
				HelperFunctions.delay(1.0) {
					self.startRecording()
					self.rawData = []

					peripheral.setNotifyValue(true, for: characteristic)
				}
			}
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		//print("didUpdateValueFor \(characteristic.uuid)")
		if let value = characteristic.value {
			// http://stackoverflow.com/a/32894672/2603230
			if let utf8Data = String(data: value, encoding: String.Encoding.utf8) {
				//print(utf8Data)
				let someReceivedData = utf8Data.components(separatedBy: " ")
				for eachReceivedData in someReceivedData {
					if !eachReceivedData.isEmpty {
						if let eachReceivedDataInt = Int(eachReceivedData) {
							//print(eachReceivedDataInt)
							self.rawData.append(eachReceivedDataInt)

							let dataSet = self.chartView.data?.getDataSetByIndex(0)
							let index = (dataSet?.entryCount)!
							let value = eachReceivedDataInt
							print("\(index) \(value)")

							let chartEntry = ChartDataEntry(x: Double(index), y: Double(value))
							chartView.data?.addEntry(chartEntry, dataSetIndex: 0)
							chartView.data?.notifyDataChanged()
							chartView.notifyDataSetChanged()

							chartView.setVisibleXRange(minXRange: 300, maxXRange: 300)
							chartView.moveViewToX(Double((chartView.data?.entryCount)!))
						}
					}
				}
			}
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
		if isConnectedAndRecording == true {
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
	/*func getBackgroundColor() -> UIColor {
		//return UIColor(netHex: 0xC8FFC8)
		return UIColor.white
	}*/
	func getElementColor() -> UIColor {
		return UIColor.black
	}

	func getButtonBackgroundColor() -> UIColor {
		return UIColor(netHex: 0x1C1C1C)
	}
	func getButtonElementColor() -> UIColor {
		return UIColor.white
	}

	/*func getElementColorString() -> String {
		return "Black"
	}*/

}
