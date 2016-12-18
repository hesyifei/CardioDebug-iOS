//
//  ResultViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 23/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Async
import Alamofire
import Charts
import Surge
import RealmSwift
import MBProgressHUD

class PassECGResult {
	var startDate: Date!
	var rawData: [Int]!
	var isNew: Bool!
}

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	static let SHOW_RESULT_SEGUE_ID = "showResult"

	@IBOutlet var tableView: UITableView!
	@IBOutlet var chartView: LineChartView!
	@IBOutlet var debugTextView: UITextView!

	var passedData: PassECGResult!
	var tableData = [String]()
	var result = [String: Double]()

	var isPassedDataValid = false

	var passedBackData: ((Bool) -> Void)?


	var sessionManager: SessionManager!


	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		tableView.delegate = self
		tableView.dataSource = self

		let configuration = URLSessionConfiguration.default
		configuration.urlCache = nil
		sessionManager = Alamofire.SessionManager(configuration: configuration)

		// FIXME: func to be changed
		let shareAction = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.doneButtonAction))

		if (self.navigationController?.isBeingPresented)! {
			let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonAction))
			self.navigationItem.setRightBarButton(doneButton, animated: true)

			self.navigationItem.setLeftBarButton(shareAction, animated: true)
		} else {
			self.navigationItem.setRightBarButton(shareAction, animated: true)
		}


		if let rawData = passedData.rawData, let _ = passedData.startDate, let _ = passedData.isNew {
			if !rawData.isEmpty {
				if rawData.count >= 10*100 {
					isPassedDataValid = true
				} else {
					print("time too short! \(rawData.count)")
				}
			}
		}

		if isPassedDataValid {
			let loadingHUD = MBProgressHUD.showAdded(to: self.view, animated: true)

			Async.main {
				self.initChart()
			}

			tableData = []
			result = [:]
			self.calculateECGData(self.passedData.rawData) { (successDownloadHRVData: Bool) in
				if !successDownloadHRVData {
					print("ERROR")
				}
				self.getExtraData()
				Async.background {
					let realm = try! Realm()
					if self.passedData.isNew == true {
						let ecgData = ECGData()
						ecgData.startDate = self.passedData.startDate
						ecgData.duration = Double(self.passedData.rawData.count)/100.0
						ecgData.rawData = self.passedData.rawData
						ecgData.result = self.result
						try! realm.write {
							realm.add(ecgData)
						}
						if !successDownloadHRVData {
							HelperFunctions.showAlert(self, title: "Warning", message: "The HRV cannot be analyzed for now. Data is stored and you can connect internet and analyzed it later in Record view.")
						}
					} else {
						if let thisData = realm.objects(ECGData.self).filter("startDate = %@", self.passedData.startDate).first {
							if successDownloadHRVData {
								print("Can load online HRV. Saving it to local data.")
								if thisData.result != self.result {
									try! realm.write {
										thisData.result = self.result
									}
								}
							} else {
								print("Cannot load online HRV. Reloading local data.")
								self.result = thisData.result
							}
						}
					}

					let msUnit = " ms", percentageUnit = " %", ms2Unit = " ms2"
					let fullStringDict = [
						"TOT PWR": "TOT Power",
						"ULF PWR": "Ultra low frequency",
						"VLF PWR": "Very low frequency",
						"LF PWR": "Low frequency",
						"HF PWR": "High frequency",
					]
					let unitDict = [
						"AVNN": msUnit,
						"SDSD": msUnit,
						"SDNN": msUnit,
						"SDANN": msUnit,
						"SDNNIDX": msUnit,
						"rMSSD": msUnit,
						"pNN20": percentageUnit,
						"pNN50": percentageUnit,
						"TOT PWR": ms2Unit,
						"ULF PWR": ms2Unit,
						"VLF PWR": ms2Unit,
						"LF PWR": ms2Unit,
						"HF PWR": ms2Unit,
						"LF/HF": "",
					]
					let timeDomainOrder = ["AVNN", "SDSD", "SDNN", "SDANN", "SDNNIDX", "rMSSD", "pNN20", "pNN50"]
					let frequencyDomainOrder = ["TOTPWR", "ULFPWR", "VLFPWR", "LFPWR", "HFPWR", "LF/HF"]
					for key in timeDomainOrder {
						if let value = self.result[key] {
							if value != 0 {
								var name = key
								if let abbName = fullStringDict[key] {
									name = abbName
								}
								var unit = ""
								if let abbUnit = unitDict[key] {
									unit = abbUnit
								}
								self.tableData.append("\(name)|\(String(format: "%.2f", value))\(unit)")
							}
						}
					}

					}.main {
						loadingHUD.hide(animated: true)
						self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)
				}
			}

		} else {
			print("isPassedDataValid false")
		}


		self.title = "\(DateFormatter.localizedString(from: passedData.startDate!, dateStyle: .medium, timeStyle: .medium))"

		if passedData.isNew == true {
			Async.main {
				self.performSegue(withIdentifier: SymptomSelectionViewController.SHOW_SYMPTOM_SELECTION_SEGUE_ID, sender: self)
			}
		}

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func doneButtonAction() {
		if passedData.isNew == true {
			passedBackData?(true)
		}
		navigationController?.dismiss(animated: true, completion: nil)
	}


	// MARK: - tableView related
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableData.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
		let data = tableData[indexPath.row].components(separatedBy: "|")
		cell.textLabel?.text = data[0]
		cell.detailTextLabel?.text = data[1]
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.deselectRow(at: indexPath, animated: true)
	}


	func initChart() {
		chartView.setViewPortOffsets(left: 0.0, top: 20.0, right: 0.0, bottom: 20.0)

		chartView.noDataText = "No chart data available."
		chartView.chartDescription?.text = ""
		chartView.scaleXEnabled = true
		chartView.scaleYEnabled = false
		chartView.legend.enabled = false
		chartView.animate(xAxisDuration: 1.0)


		let rightAxis = chartView.rightAxis
		rightAxis.drawLabelsEnabled = false
		rightAxis.drawAxisLineEnabled = false
		rightAxis.drawGridLinesEnabled = false


		let leftAxis = chartView.leftAxis
		leftAxis.drawLabelsEnabled = false
		leftAxis.drawAxisLineEnabled = false
		leftAxis.drawGridLinesEnabled = false


		let xAxis = chartView.xAxis
		xAxis.drawAxisLineEnabled = true
		xAxis.drawGridLinesEnabled = false
		xAxis.labelPosition = .bottom
		xAxis.valueFormatter = ChartCSDoubleToSecondsStringFormatter()
		//xAxis.setLabelsToSkip(0)                    // X軸不隱藏任何值（見文檔）


		//let values = passedData.rawData[0...2000]
		let values = passedData.rawData!
		var dataEntries: [ChartDataEntry] = []
		for (index, value) in values.enumerated() {
			let dataEntry = ChartDataEntry(x: Double(index), y: Double(value))
			dataEntries.append(dataEntry)
		}

		let ecgRawDataSet = LineChartDataSet(values: dataEntries, label: nil)
		ecgRawDataSet.colors = [UIColor.lightGray]
		ecgRawDataSet.drawCirclesEnabled = false





		let lineChartData = LineChartData(dataSets: [ecgRawDataSet])
		lineChartData.setDrawValues(false)

		chartView.data = lineChartData
		chartView.data?.highlightEnabled = false
		chartView.setVisibleXRangeMinimum(100.0)
		chartView.setVisibleXRangeMaximum(800.0)
	}

	/*func calculateECGValues(_ inputValues: [Int]) {
		print("values count: \(inputValues.count)")


		// raw data -> mV unit
		/*var realDataValues: [Double] = []

		for (no, _) in inputValues.enumerated() {
			let first = Double(inputValues[no])/(Surge.pow(2.0, 10.0))
			realDataValues.append((first-1/2)*3.3)
			realDataValues[no] = realDataValues[no]/1.1
			//print(values[no])
		}*/


		// reduce noise
		/*values = []

		for (no, _) in realDataValues.enumerated() {
			if no >= 1 && no < realDataValues.count-1-1 {
				values.append((realDataValues[no-1]+realDataValues[no]+realDataValues[no+1])/3)
			}
		}*/

		/*var slopes: [Double] = [0, 0]
		var importantSlopes: [Int] = []

		for (no, _) in values.enumerated() {
			if no > 2 && no < values.count-2 {
				let slope = getSlope(n: no, values: values)
				//print(slope)
				slopes.append(slope)
			}
		}

		let firstMaxI = slopes.prefix(through: 100).max()
		print("firstMaxI: \(firstMaxI)")

		let slope_threshold = (4.0/16.0)*firstMaxI!
		print(slope_threshold)


		for (no, value) in values.enumerated() {
			if no > 2 && no < values.count-1-2-1 {
				let slope = slopes[no]
				let anotherSlope = slopes[no+1]
				if (slope > slope_threshold) && (anotherSlope > slope_threshold) {
					print("importantSlopes append \(no) = \(value)")
					importantSlopes.append(no)
					//break
				}
			}
		}
		importantSlopes.append(importantSlopes[importantSlopes.count-1]+1)
		importantSlopes.append(importantSlopes[importantSlopes.count-1]+10)


		var mostImportantSlopes = [Int]()
		for (no, importantSlope) in importantSlopes.enumerated() {
			if no < importantSlopes.count-1-1 {
				let nextSlope = importantSlopes[no+1]
				let doubleNSlope = importantSlopes[no+2]
				if (nextSlope <= importantSlope+10) && (doubleNSlope > importantSlope+10) {
					print("mostImportantSlopes append \(importantSlope)")
					mostImportantSlopes.append(importantSlope)
				} else {
					print("ignore \(importantSlope)")
				}
			}
		}
		print("mostImportantSlopes: \(mostImportantSlopes)")


		var allMaxRIndex = [Int]()
		for (no, mostImportantSlope) in mostImportantSlopes.enumerated() {


			var startRange = 0
			if (mostImportantSlope-40) > 0 {
				startRange = mostImportantSlope-40
			}

			var endRange = values.count-1
			if (mostImportantSlope+40) < (values.count-1) {
				endRange = mostImportantSlope+40
			}


			let firstMaxRRange = values[startRange..<endRange]
			let firstMinQRange = values[startRange..<endRange]


			let firstMaxR = firstMaxRRange.max()
			let firstMinQ = firstMinQRange.min()

			let firstMaxRIndex = firstMaxRRange.index(of: firstMaxR!)
			let firstMaxQIndex = firstMinQRange.index(of: firstMinQ!)

			allMaxRIndex.append(firstMaxRIndex!)

			print("firstMaxRIndex: \(firstMaxRIndex)")
			print("firstMaxQIndex: \(firstMaxQIndex)")
			print("****")
		}

		print("----")
		print("allMaxRIndex: \(allMaxRIndex)")



		rrDurations = []
		for (no, maxRIndex) in allMaxRIndex.enumerated() {
			if no < allMaxRIndex.count-1 {
				let duration = allMaxRIndex[no+1]-maxRIndex
				if duration > 10 {
					// REMEMBER THIS VALUE NEED TO *10 TO BE RESULT IN MILISECONDS
					rrDurations.append(duration*10)
				} else {
					print("WARNNING !!!!!! LESS THAN 0.1s!!!")
				}
			}
		}
		print("----")
		print("rrDurations (in ms): \(rrDurations)")


		Async.main {
			self.debugTextView.text = "allMaxRIndex: \(allMaxRIndex)\nrrDurations: \(self.rrDurations)"
		}

		rPoints = []
		rPoints.append(allMaxRIndex[0]*10)
		for (no, eachDuration) in rrDurations.enumerated() {
			if no >= 1 {
				rPoints.append(rPoints[no-1]+eachDuration)
			}
		}*/
	}*/


	func calculateECGData(_ inputValues: [Int], completion completionBlock: @escaping (Bool) -> Void) {

		/*let AVNN: Double = Surge.mean(RRDurations)
		print("AVNN: \(AVNN)")
		//resultLabel.text = "RRMean: \(RRMean)"
		tableData.append("AVNN|\(String(format: "%.2f", AVNN))ms")
		result["AVNN"] = AVNN



		var sumInOneMin: Double = 0
		var beatsSumInOneMin: Int = 0
		var beatsEveryMin = [Int]()

		var RRAndMeanRRDiffs = [Double]()
		var RRAndNextRRDiffs = [Double]()
		var RRNextRRAndMeanRRNextRRDiffs = [Double]()
		for (index, eachDuration) in RRDurations.enumerated() {
			RRAndMeanRRDiffs.append(eachDuration-AVNN)

			if index < (RRDurations.count-1) {
				RRAndNextRRDiffs.append(RRDurations[index+1]-eachDuration)

				RRNextRRAndMeanRRNextRRDiffs.append((eachDuration-RRDurations[index+1])-(AVNN-eachDuration))
			}

			if sumInOneMin < 60*1000 {
				sumInOneMin += eachDuration
				beatsSumInOneMin += 1
			} else {
				beatsEveryMin.append(beatsSumInOneMin)
				sumInOneMin = 60*1000-sumInOneMin
				beatsSumInOneMin = 0
			}
		}

		let SDNN: Double = Surge.sqrt(Surge.measq(RRAndMeanRRDiffs))
		print("SDNN: \(SDNN)")
		tableData.append("SDNN|\(String(format: "%.2f", SDNN))ms")
		result["SDNN"] = SDNN

		let rMSSD: Double = Surge.sqrt(Surge.measq(RRAndNextRRDiffs))
		print("rMSSD: \(rMSSD)")
		tableData.append("rMSSD|\(String(format: "%.2f", rMSSD))ms")
		result["rMSSD"] = rMSSD

		let SDSD: Double = Surge.sqrt(Surge.measq(RRNextRRAndMeanRRNextRRDiffs))
		print("SDSD: \(SDSD)")
		tableData.append("SDSD|\(String(format: "%.2f", SDSD))ms")
		result["SDSD"] = SDSD


		print("beatsEveryMin: \(beatsEveryMin)")

		if !beatsEveryMin.isEmpty {
			let slowestBeat = beatsEveryMin.min()!
			let fastestBeat = beatsEveryMin.max()!
			tableData.append("Range|\(slowestBeat)-\(fastestBeat) bpm")


			let averageBeat: Int = lround(Surge.mean(beatsEveryMin.map{ Double($0) }))
			tableData.append("Average|\(averageBeat) bpm")
			result["AverageBPM"] = Double(averageBeat)
		}


		let rawDataDouble = passedData.rawData.map{ Double($0) }

		let FFTTest: [Double] = Surge.fft(rawDataDouble)
		print("FFTTest: \(FFTTest)")

		let dataAverage: Double = Surge.mean(rawDataDouble)
		let FFTTestNEW: [Double] = Surge.fft(passedData.rawData.map{ Double($0)-dataAverage })
		print("FFTTestNEW: \(FFTTestNEW)")*/


		/*let rPointsToBeUploaded: [Double] = rPoints.map { Double($0)/1000.0 }
		let rrDurationsToBeUploaded: [Double] = rrDurations.map { Double($0)/1000.0 }

		print("rPointsToBeUploaded: \(rPointsToBeUploaded)")
		print("rrDurationsToBeUploaded: \(rrDurationsToBeUploaded)")*/

		let parameters: Parameters = ["ecgRawData": inputValues]

		sessionManager.request(BasicConfig.ecgCalculationURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseJSON { response in
			print(response.request)  // original URL request
			print(response.response) // HTTP URL response
			print(response.data)     // server data
			print(response.result)   // result of response serialization

			self.result = [:]
			var success = false
			if let JSON = response.result.value {
				print("JSON: \(JSON)")
				if let jsonDict = JSON as? [String: AnyObject] {
					for (key, value) in jsonDict {
						if let value = value.doubleValue {
							self.result[key] = value
							success = true
						}
					}
				}
			}
			print("result: \(self.result)")
			completionBlock(success)
		}

	}

	func getExtraData() {

	}

	/*func calculateExtraData() {
		/*var sumInOneMin: Int = 0
		var beatsSumInOneMin: Int = 0
		var beatsEveryMin = [Int]()

		for eachDuration in self.rrDurations {
			if sumInOneMin < 60*1000 {
				sumInOneMin += eachDuration
				beatsSumInOneMin += 1
			} else {
				beatsEveryMin.append(beatsSumInOneMin)
				sumInOneMin = 60*1000-sumInOneMin
				beatsSumInOneMin = 0
			}
		}

		print("beatsEveryMin: \(beatsEveryMin)")

		if !beatsEveryMin.isEmpty {
			let averageBeat: Int = lround(Surge.mean(beatsEveryMin.map{ Double($0) }))
			self.tableData.append("Average|\(averageBeat) bpm")

			let slowestBeat = beatsEveryMin.min()!
			let fastestBeat = beatsEveryMin.max()!
			self.tableData.append("Range|\(slowestBeat)-\(fastestBeat) bpm")
		}*/
	}*/

	/*func getSlope(n: Int, values: [Double]) -> Double {
		let one = Double(-2*values[n-2])
		let two = Double(values[n-1])
		let three = Double(values[n+1])
		let four = Double(2*values[n+2])
		
		return one-two+three+four
	}*/
	
}

class ChartCSDoubleToSecondsStringFormatter: NSObject, IAxisValueFormatter {
	// cs = centisecond = 0.01s (as the record is 100Hz)
	public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		return "\(String(format: "%.1f", value/100))s"
	}
}
