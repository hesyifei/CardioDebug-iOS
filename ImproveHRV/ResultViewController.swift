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
import RealmSwift
import MBProgressHUD

class PassECGResult {
	var recordType: RecordType!
	var startDate: Date!
	var recordingHertz: Double!
	var rawData: [Int]!
	var rrData: [Int] = []
	var isNew: Bool!
}

enum UpperTableSegmentedControlSegment: Int {
	case timeDomain = 0
	case frequencyDomain = 1
	case other = 2
}

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	static let SHOW_RESULT_SEGUE_ID = "showResult"
	static let PRESENT_RESULT_MODALLY_SEGUE_ID = "presentResultModally"

	@IBOutlet var tableView: UITableView!
	@IBOutlet var leftChartView: LineChartView!
	@IBOutlet var rightChartView: LineChartView!
	@IBOutlet var debugTextView: UITextView!
	@IBOutlet var upperSegmentedControl: UISegmentedControl!
	@IBOutlet var lowerSegmentedControl: UISegmentedControl!

	// MARK: - basic var
	let application = UIApplication.shared

	var refreshControl: UIRefreshControl!
	var isRightChartInited: Bool!

	var passedData: PassECGResult!
	var tableData = [String]()
	var result = [String: Double]()
	var fftResult = [Double]()

	var isPassedDataValid = false

	var isCalculationError = false
	var calculationErrorTitle = "Warning"
	var calculationErrorMessage = ""
	let HRVUnableToAnalyseMessage = "The HRV cannot be analyzed for now. You can connect internet and enter this view again."

	var isPresentSimpleResultNecessary = false

	var isProblemOnPerson = false
	var problemOnPersonData = [String: AnyObject]()


	var passedBackData: ((Bool) -> Void)?



	let defaultNoteCell = ["Note", "Enter note..."]


	var sessionManager: SessionManager!


	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		tableView.delegate = self
		tableView.dataSource = self

		isRightChartInited = false

		// allow user only to refresh if the record is not new (to avoid bug)
		if self.passedData.isNew == false {
			refreshControl = UIRefreshControl()
			refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
			refreshControl.addTarget(self, action: #selector(self.refreshData), for: UIControlEvents.valueChanged)
			self.tableView.addSubview(refreshControl)
			self.tableView.sendSubview(toBack: refreshControl)
		}


		self.title = "\(DateFormatter.localizedString(from: passedData.startDate!, dateStyle: .medium, timeStyle: .medium))"


		let configuration = URLSessionConfiguration.default
		configuration.urlCache = nil
		sessionManager = Alamofire.SessionManager(configuration: configuration)


		if let navController = self.navigationController {
			navController.navigationBar.tintColor = StoredColor.middleBlue
		}

		let shareAction = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.shareButtonAction))

		if HelperFunctions.isModal(self) {
			let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonAction))
			self.navigationItem.setRightBarButton(doneButton, animated: true)

			self.navigationItem.setLeftBarButton(shareAction, animated: true)
		} else {
			self.navigationItem.setRightBarButton(shareAction, animated: true)
		}

		upperSegmentedControl.tintColor = StoredColor.middleBlue
		lowerSegmentedControl.tintColor = StoredColor.middleBlue


		if self.passedData.recordType == .ppg {
			lowerSegmentedControl.setTitle("PPG Raw Data", forSegmentAt: 0)
			lowerSegmentedControl.setTitle("RR Interval", forSegmentAt: 1)
		}

		//print(passedData.rawData)


		loadDataAndChart(force: false)

		if passedData.isNew == true {
			Async.main {
				self.performSegue(withIdentifier: SymptomSelectionViewController.SHOW_SYMPTOM_SELECTION_SEGUE_ID, sender: self)
			}
		}

	}

	func refreshData() {
		loadDataAndChart(force: true)
	}

	func loadDataAndChart(force: Bool) {
		if let rawData = passedData.rawData, let _ = passedData.startDate, let _ = passedData.isNew {
			if !rawData.isEmpty {
				if rawData.count >= 10*100 {
					isPassedDataValid = true
				} else {
					print("Recording time is too short! (\(rawData.count) < \(10*100))")
					HelperFunctions.showAlert(self, title: "Warning", message: "This record is too short to analyze. Please try to record some new ones.", completion: nil)
					#if DEBUG
						if DebugConfig.ignoreShortestTimeRestriction == true {
							print("[IGNORE LAST MSG] DebugConfig.ignoreShortestTimeRestriction is true")
							isPassedDataValid = true
						}
					#endif
				}
			}
		}

		if isPassedDataValid {
			var addHUDTo: UIView!
			if HelperFunctions.isModal(self) {
				addHUDTo = self.navigationController?.view
			} else {
				addHUDTo = self.navigationController?.tabBarController?.view
			}
			let loadingHUD = MBProgressHUD.showAdded(to: addHUDTo, animated: true)

			Async.main {
				self.lowerSegmentedControl.selectedSegmentIndex = 0
				self.leftChartView.isHidden = false
				self.rightChartView.isHidden = true
				self.initLeftChart()
			}

			result = [:]
			fftResult = []

			if self.passedData.isNew == true || force == true {
				var dataToBeCalculated = self.passedData.rawData
				if self.passedData.recordType == .ppg {
					dataToBeCalculated = self.passedData.rrData
				}
				self.calculateECGData(dataToBeCalculated!, recordType: self.passedData.recordType, hertz: self.passedData.recordingHertz) { (successDownloadHRVData: Bool) in
					if !successDownloadHRVData {
						print("ERROR")
					}
					Async.background {
						let realm = try! Realm()
						if self.passedData.isNew == true {
							let ecgData = ECGData()
							ecgData.recordType = self.passedData.recordType
							ecgData.startDate = self.passedData.startDate
							ecgData.duration = Double(self.passedData.rawData.count)/self.passedData.recordingHertz
							ecgData.recordingHertz = self.passedData.recordingHertz
							ecgData.rawData = self.passedData.rawData
							ecgData.rrData = self.passedData.rrData
							ecgData.result = self.result
							ecgData.fftData = self.fftResult
							try! realm.write {
								realm.add(ecgData)
							}
							if !successDownloadHRVData {
								// TODO: this error not showing when no internet and SSVC (SelectSymptoms) not closed
								self.isCalculationError = true
								self.calculationErrorMessage = "The HRV cannot be analyzed for now. Data is stored and you can connect internet and analyzed it later in Record view."
							}
						} else if force == true {
							if let thisData = realm.objects(ECGData.self).filter("startDate = %@", self.passedData.startDate).first {
								if successDownloadHRVData {
									print("Loaded online HRV. Saving it to local data.")
									if (thisData.result != self.result) || (thisData.fftData != self.fftResult) {
										try! realm.write {
											thisData.result = self.result
											thisData.fftData = self.fftResult
										}
									}
								} else {
									print("Cannot load online HRV. Reloading local data.")
									self.result = thisData.result
									self.fftResult = thisData.fftData
									if self.result.isEmpty {
										self.isCalculationError = true
										self.calculationErrorMessage = self.HRVUnableToAnalyseMessage
									}
								}
							}
						}

						self.updateUpperTableData(.timeDomain)
						self.isRightChartInited = false

						}.main {
							loadingHUD.hide(animated: true)
							self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)

							if self.isCalculationError == true {
								HelperFunctions.showAlert(self, title: self.calculationErrorTitle, message: self.calculationErrorMessage) { (_) in
									self.isCalculationError = false
								}
							} else {
								if self.passedData.isNew == true {
									self.isPresentSimpleResultNecessary = true
									self.performSegue(withIdentifier: SimpleResultViewController.SHOW_SIMPLE_RESULT_SEGUE_ID, sender: self)
								}
							}

							// http://stackoverflow.com/q/5273775/2603230
							self.upperSegmentedControl.selectedSegmentIndex = UpperTableSegmentedControlSegment.timeDomain.rawValue

							if (self.refreshControl) != nil {
								if self.refreshControl.isRefreshing {
									self.refreshControl.endRefreshing()
								}
							}
					}
				}
			} else {
				let realm = try! Realm()
				if let thisData = realm.objects(ECGData.self).filter("startDate = %@", self.passedData.startDate).first {
					self.result = thisData.result
					self.fftResult = thisData.fftData

					self.updateUpperTableData(.timeDomain)

					if self.result.isEmpty {
						HelperFunctions.showAlert(self, title: self.calculationErrorTitle, message: self.HRVUnableToAnalyseMessage) { (_) in () }
					}
					loadingHUD.hide(animated: true)
					self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)

					if (self.refreshControl) != nil {
						if refreshControl.isRefreshing {
							self.refreshControl.endRefreshing()
						}
					}
				}
			}

		} else {
			print("isPassedDataValid false")
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == SymptomSelectionViewController.SHOW_SYMPTOM_SELECTION_SEGUE_ID {
			if let destinationNavigationController = segue.destination as? UINavigationController {
				if let destination = destinationNavigationController.topViewController as? SymptomSelectionViewController {

					destination.passedBackData = { bool in
						print("SymptomSelectionViewController passedBackData \(bool)")
						// checking passedData.isNew should be unnecessary here as SymptomSelectionViewController will be shown only when isNew
						if bool == true {
							if self.isPresentSimpleResultNecessary == true {
								Async.main(after: 0.5) {
									self.performSegue(withIdentifier: SimpleResultViewController.SHOW_SIMPLE_RESULT_SEGUE_ID, sender: self)
								}
							}
						}
					}
					
				}
			}
		}
		if segue.identifier == SimpleResultViewController.SHOW_SIMPLE_RESULT_SEGUE_ID {
			if let destination = segue.destination as? SimpleResultViewController {
				destination.isGood = !self.isProblemOnPerson			// "!" here is important!
				destination.problemData = self.problemOnPersonData
				destination.passedBackData = { bool in
					print("SimpleResultViewController passedBackData \(bool)")
					if bool == true {
						self.isPresentSimpleResultNecessary = false

						if self.isCalculationError == true {
							Async.main(after: 0.5) {
								HelperFunctions.showAlert(self, title: self.calculationErrorTitle, message: self.calculationErrorMessage) { (_) in
									self.isCalculationError = false
								}
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

	@IBAction func hrvSegmentedControlChanged(sender: UISegmentedControl) {
		print("hrvSegmentedControlChanged: \(sender.selectedSegmentIndex)")
		self.updateUpperTableData(UpperTableSegmentedControlSegment(rawValue: sender.selectedSegmentIndex)!)
		self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)
	}

	@IBAction func chartSegmentedControlChanged(sender: UISegmentedControl) {
		print("chartSegmentedControlChanged: \(sender.selectedSegmentIndex)")
		switch sender.selectedSegmentIndex {
		case 0:
			self.leftChartView.isHidden = false
			self.rightChartView.isHidden = true
		case 1:
			if !isRightChartInited {
				self.initRightChart()
				isRightChartInited = true
			}
			self.leftChartView.isHidden = true
			self.rightChartView.isHidden = false
		default:
			break
		}
	}

	func doneButtonAction() {
		if passedData.isNew == true {
			passedBackData?(true)
		} else {
			passedBackData?(false)
		}
		navigationController?.dismiss(animated: true, completion: nil)
	}

	func shareButtonAction() {
		let alert = UIAlertController(title: "Share", message: "Share this ECG and HRV data to:", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Q&A Platform", style: .default, handler: { action in
			print("Clicked Q&A Platform")
		}))
		alert.addAction(UIAlertAction(title: "Other...", style: .default, handler: { action in
			print("Clicked Other...")
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}


	func updateUpperTableData(_ segmentedControlSegment: UpperTableSegmentedControlSegment) {
		tableData = []

		switch segmentedControlSegment {
		case .timeDomain, .frequencyDomain:
			let msUnit = " ms", percentageUnit = " %", ms2Unit = " ms²", bpmUnit = " bpm"

			if segmentedControlSegment == .timeDomain {
				if let avgHR = self.result["AvgHR"] {
					self.tableData.append("Average|\(String(format: "%.0f", avgHR))\(bpmUnit)")
				}
				if let maxHR = self.result["MaxHR"], let minHR = self.result["MinHR"] {
					self.tableData.append("Range|\(String(format: "%.0f", minHR))-\(String(format: "%.0f", maxHR))\(bpmUnit)")
				}
			}


			let fullStringDict = [
				"TOT PWR": "Total HRV Power",
				"ULF PWR": "Ultra-low Frequency Power",
				"VLF PWR": "Very Low Frequency Power",
				"LF PWR": "Low Frequency Power",
				"HF PWR": "High Frequency Power",
				"nHF": "Normalized HF (PNS)",
				"nLF": "Normalized LF (SNS)",
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
				"nHF": "",
				"nLF": "",
				]

			let timeDomainOrder = ["AVNN", "SDSD", "SDNN", "SDANN", "SDNNIDX", "rMSSD", "pNN20", "pNN50"]
			let frequencyDomainOrder = ["LF/HF", "nLF", "nHF", "TOT PWR", "ULF PWR", "VLF PWR", "LF PWR", "HF PWR"]
			var allKey = frequencyDomainOrder
			if segmentedControlSegment == .timeDomain {
				allKey = timeDomainOrder
			}
			for key in allKey {
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
						self.tableData.append("\(name)|\(String(format: "%.2f", value))\(unit) ✅")
					}
				}
			}
			break
		case .other:
			let realm = try! Realm()
			tableData = [defaultNoteCell.joined(separator: "|")]
			if let thisData = realm.objects(ECGData.self).filter("startDate = %@", self.passedData.startDate).first {
				if !thisData.note.isEmpty {
					tableData = ["Note|\(thisData.note)"]
				}
			}
			break
		}

		// if it's still empty...
		if tableData.isEmpty {
			tableData.append("No analysis result available.|")
			tableData.append("Please try to reload!|")
		}
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

		let data = tableData[indexPath.row].components(separatedBy: "|")

		switch UpperTableSegmentedControlSegment(rawValue: self.upperSegmentedControl.selectedSegmentIndex)! {
		case .timeDomain, .frequencyDomain:
			// to make sure this row really have a value
			if data.count == 2 {
				HelperFunctions.showAlert(self, title: "\(data[0])", message: "Description: ...\nNormal Value: ", completion: nil)
			}
			break
		case .other:
			let realm = try! Realm()
			if let thisData = realm.objects(ECGData.self).filter("startDate = %@", self.passedData.startDate).first {
				let noteString = defaultNoteCell[0]
				switch data[0] {
				case noteString:
					let noteAlertController = UIAlertController(title: "Note", message: "Enter anything you want:", preferredStyle: .alert)

					let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
						if let field = noteAlertController.textFields?[0] {
							print("Saving note to local data.")
							try! realm.write {
								thisData.note = field.text!
							}
							self.tableData[0] = "\(noteString)|\(field.text!)"
							self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)
						}
					}

					let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }

					noteAlertController.addTextField { (textField) in
						if data.count == 2 {
							if data[1] != self.defaultNoteCell[1] {
								textField.text = data[1]
							}
						}
						textField.placeholder = "Note..."
						textField.autocapitalizationType = .sentences
					}

					noteAlertController.addAction(confirmAction)
					noteAlertController.addAction(cancelAction)

					Async.main {
						self.present(noteAlertController, animated: true, completion: nil)
					}
				default:
					break
				}
			}
			break
		}
	}


	func initLeftChart() {
		leftChartView.setViewPortOffsets(left: 0.0, top: 20.0, right: 0.0, bottom: 20.0)

		leftChartView.noDataText = "No chart data available."
		leftChartView.chartDescription?.text = ""
		leftChartView.scaleXEnabled = true
		leftChartView.scaleYEnabled = false
		leftChartView.legend.enabled = false
		leftChartView.animate(xAxisDuration: 1.0)


		let rightAxis = leftChartView.rightAxis
		rightAxis.drawLabelsEnabled = false
		rightAxis.drawAxisLineEnabled = false
		rightAxis.drawGridLinesEnabled = false


		let leftAxis = leftChartView.leftAxis
		leftAxis.drawLabelsEnabled = false
		leftAxis.drawAxisLineEnabled = false
		leftAxis.drawGridLinesEnabled = false


		let xAxis = leftChartView.xAxis
		xAxis.drawAxisLineEnabled = false
		xAxis.drawGridLinesEnabled = true
		xAxis.gridColor = UIColor(netHex: 0xF6CECE)
		//xAxis.gridColor = StoredColor.middleBlue
		xAxis.labelPosition = .bottom
		// default is 100Hz (cs = centisecond = 0.01s which is 100Hz)
		xAxis.valueFormatter = ChartDoubleToSecondsStringFormatter(hertz: self.passedData.recordingHertz)


		//let values = passedData.rawData[0...2000]

		/*let inputValues = passedData.rawData!
		var realDataValues: [Double] = []

		for (no, _) in inputValues.enumerated() {
			let first = Double(inputValues[no])/(Surge.pow(2.0, 10.0))
			realDataValues.append((first-1/2)*3.3)
			realDataValues[no] = realDataValues[no]/1.1
		}
		let values = realDataValues*/

		let values = passedData.rawData!

		var dataEntries: [ChartDataEntry] = []
		for (index, value) in values.enumerated() {
			let dataEntry = ChartDataEntry(x: Double(index), y: Double(value))
			dataEntries.append(dataEntry)
		}

		let ecgRawDataSet = LineChartDataSet(values: dataEntries, label: nil)
		ecgRawDataSet.colors = [UIColor.lightGray]
		ecgRawDataSet.mode = .cubicBezier
		ecgRawDataSet.drawCirclesEnabled = false





		let lineChartData = LineChartData(dataSets: [ecgRawDataSet])
		lineChartData.setDrawValues(false)

		leftChartView.data = lineChartData
		leftChartView.data?.highlightEnabled = false
		leftChartView.setVisibleXRangeMinimum(self.passedData.recordingHertz*1)
		leftChartView.setVisibleXRangeMaximum(self.passedData.recordingHertz*6)
		Async.main {
			self.leftChartView.zoom(scaleX: 0.0001, scaleY: 1, x: 0, y: 0)		// reset scale
			self.leftChartView.zoom(scaleX: CGFloat(6/2), scaleY: 1, x: 0, y: 0)
			self.leftChartView.moveViewToX(0)
		}
	}

	func initRightChart() {
		rightChartView.setViewPortOffsets(left: 20.0, top: 10.0, right: 20.0, bottom: 10.0)

		rightChartView.noDataText = "No FFT data available. Please try to reload!"
		rightChartView.chartDescription?.text = ""
		rightChartView.scaleXEnabled = false
		rightChartView.scaleYEnabled = false
		rightChartView.legend.enabled = false
		//rightChartView.animate(xAxisDuration: 1.0)


		let rightAxis = rightChartView.rightAxis
		rightAxis.drawLabelsEnabled = false
		rightAxis.drawAxisLineEnabled = false
		rightAxis.drawGridLinesEnabled = false


		let leftAxis = rightChartView.leftAxis
		leftAxis.drawLabelsEnabled = false
		leftAxis.drawAxisLineEnabled = false
		leftAxis.drawGridLinesEnabled = false


		let xAxis = rightChartView.xAxis
		xAxis.drawLabelsEnabled = false
		xAxis.drawAxisLineEnabled = false
		xAxis.drawGridLinesEnabled = false


		var values = self.fftResult
		if self.passedData.recordType == .ppg {
			values = self.passedData.rrData.map{ Double($0) }
		}

		rightChartView.data = nil
		// doing this can make sure "noDataText" is displayed when values is really empty
		if !values.isEmpty {
			var dataEntries: [ChartDataEntry] = []
			for (index, value) in values.enumerated() {
				let dataEntry = ChartDataEntry(x: Double(index), y: value)
				dataEntries.append(dataEntry)
			}

			let fftDataSet = LineChartDataSet(values: dataEntries, label: nil)
			fftDataSet.colors = [StoredColor.darkRed]
			fftDataSet.mode = .linear
			fftDataSet.drawCirclesEnabled = false

			let lineChartData = LineChartData(dataSets: [fftDataSet])
			lineChartData.setDrawValues(false)

			rightChartView.data = lineChartData
		}
		rightChartView.data?.highlightEnabled = false

		Async.main {
			self.rightChartView.zoom(scaleX: 0.0001, scaleY: 1, x: 0, y: 0)		// reset scale
			self.rightChartView.moveViewToX(0)
		}
	}

	func calculateECGData(_ inputValues: [Int], recordType: RecordType, hertz: Double, completion completionBlock: @escaping (Bool) -> Void) {

		self.application.isIdleTimerDisabled = true

		Async.background {
			var parameters: Parameters = [:]
			if recordType == .ppg {
				parameters["rrData"] = inputValues
			} else {
				parameters["ecgRawData"] = inputValues
			}
			parameters["hertz"] = hertz

			print("parameters: \(parameters)")

			self.sessionManager.request(BasicConfig.ecgCalculationURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseJSON { response in

				Async.main {
					//print(response.request)  // original URL request
					//print(response.response) // HTTP URL response
					//print(response.data)     // server data
					print(response.result)   // result of response serialization

					self.result = [:]
					self.fftResult = []
					var success = false
					if let JSON = response.result.value {
						print("JSON: \(JSON)")
						if let jsonDict = JSON as? [String: AnyObject] {
							if let hrvDict = jsonDict["hrv"] as? [String: [String: AnyObject]] {
								for (_, hrvValue) in hrvDict {
									// hrvKey is useless for now. maybe useful in the future?
									for (key, value) in hrvValue {
										if let value = value.doubleValue {
											self.result[key] = value
											success = true
										}
									}
								}
							}
							if let fftArray = jsonDict["fft"] as? [Double] {
								//print("fftArray: \(fftArray)")
								self.fftResult = fftArray
							}
							if let problemsArray = jsonDict["problems"] as? [AnyObject] {
								if !problemsArray.isEmpty {
									for eachProblem in problemsArray {
										// TODO: what about more than 1 problem?
										if let eachProblem = eachProblem as? [String: AnyObject] {
											self.isProblemOnPerson = true
											self.problemOnPersonData = eachProblem
										}
									}
								}
							}
							if let extraDict = jsonDict["extra"] as? [String: AnyObject] {
								// TODO: to be add
							}
						}
					}
					print("result: \(self.result)")

					self.application.isIdleTimerDisabled = false
					completionBlock(success)
				}

			}
		}

	}

}

class ChartDoubleToSecondsStringFormatter: NSObject, IAxisValueFormatter {
	var hertz: Double!

	init(hertz: Double) {
		self.hertz = hertz
	}

	public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		return "\(String(format: "%.1f", value/self.hertz))s"
	}
}
