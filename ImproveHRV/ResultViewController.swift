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
	var startDate: Date!
	var rawData: [Int]!
	var isNew: Bool!
}

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	static let SHOW_RESULT_SEGUE_ID = "showResult"

	@IBOutlet var tableView: UITableView!
	@IBOutlet var chartView: LineChartView!
	@IBOutlet var debugTextView: UITextView!
	@IBOutlet var upperSegmentedControl: UISegmentedControl!

	// MARK: - basic var
	let application = UIApplication.shared

	var refreshControl: UIRefreshControl!

	var passedData: PassECGResult!
	var tableData = [String]()
	var result = [String: Double]()

	var isPassedDataValid = false

	var isCalculationError = false
	var calculationErrorTitle = "Warning"
	var calculationErrorMessage = ""
	let HRVUnableToAnalyseMessage = "The HRV cannot be analyzed for now. You can connect internet and enter this view again."

	var isPresentSimpleResultNecessary = false

	var isProblemOnPerson = false
	var problemOnPersonData = [String: AnyObject]()


	var passedBackData: ((Bool) -> Void)?


	var sessionManager: SessionManager!


	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		tableView.delegate = self
		tableView.dataSource = self

		refreshControl = UIRefreshControl()
		refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		refreshControl.addTarget(self, action: #selector(self.refreshData), for: UIControlEvents.valueChanged)
		self.tableView.addSubview(refreshControl)
		self.tableView.sendSubview(toBack: refreshControl)


		self.title = "\(DateFormatter.localizedString(from: passedData.startDate!, dateStyle: .medium, timeStyle: .medium))"


		let configuration = URLSessionConfiguration.default
		configuration.urlCache = nil
		sessionManager = Alamofire.SessionManager(configuration: configuration)


		let shareAction = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.shareButtonAction))

		if (self.navigationController?.isBeingPresented)! {
			let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonAction))
			self.navigationItem.setRightBarButton(doneButton, animated: true)

			self.navigationItem.setLeftBarButton(shareAction, animated: true)
		} else {
			self.navigationItem.setRightBarButton(shareAction, animated: true)
		}


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
					print("time too short! \(rawData.count)")
				}
			}
		}

		if isPassedDataValid {
			var addHUDTo: UIView!
			if passedData.isNew == true {
				addHUDTo = self.navigationController?.view
			} else {
				addHUDTo = self.navigationController?.tabBarController?.view
			}
			let loadingHUD = MBProgressHUD.showAdded(to: addHUDTo, animated: true)

			Async.main {
				self.initChart()
			}

			result = [:]

			if self.passedData.isNew == true || force == true {
				self.calculateECGData(self.passedData.rawData) { (successDownloadHRVData: Bool) in
					if !successDownloadHRVData {
						print("ERROR")
					}
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
								self.isCalculationError = true
								self.calculationErrorMessage = "The HRV cannot be analyzed for now. Data is stored and you can connect internet and analyzed it later in Record view."
							}
						} else if force == true {
							if let thisData = realm.objects(ECGData.self).filter("startDate = %@", self.passedData.startDate).first {
								if successDownloadHRVData {
									print("Loaded online HRV. Saving it to local data.")
									if thisData.result != self.result {
										try! realm.write {
											thisData.result = self.result
										}
									}
								} else {
									print("Cannot load online HRV. Reloading local data.")
									self.result = thisData.result
									if self.result.isEmpty {
										self.isCalculationError = true
										self.calculationErrorMessage = self.HRVUnableToAnalyseMessage
									}
								}
							}
						}

						self.updateHRVTableData(isTimeDomain: true)

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
							self.upperSegmentedControl.selectedSegmentIndex = 0

							if self.refreshControl.isRefreshing {
								self.refreshControl.endRefreshing()
							}
					}
				}
			} else {
				let realm = try! Realm()
				if let thisData = realm.objects(ECGData.self).filter("startDate = %@", self.passedData.startDate).first {
					self.result = thisData.result

					self.updateHRVTableData(isTimeDomain: true)

					if self.result.isEmpty {
						HelperFunctions.showAlert(self, title: self.calculationErrorTitle, message: self.HRVUnableToAnalyseMessage) { (_) in () }
					}
					loadingHUD.hide(animated: true)
					self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)

					if refreshControl.isRefreshing {
						self.refreshControl.endRefreshing()
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
		switch sender.selectedSegmentIndex {
		case 0:
			self.updateHRVTableData(isTimeDomain: true)
		case 1:
			self.updateHRVTableData(isTimeDomain: false)
		default:
			break;
		}
		self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)
	}

	func doneButtonAction() {
		if passedData.isNew == true {
			passedBackData?(true)
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


	func updateHRVTableData(isTimeDomain: Bool) {
		tableData = []

		let msUnit = " ms", percentageUnit = " %", ms2Unit = " ms²", bpmUnit = " bpm"

		if isTimeDomain {
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
		let frequencyDomainOrder = ["TOT PWR", "ULF PWR", "VLF PWR", "LF PWR", "HF PWR", "LF/HF"]
		var allKey = frequencyDomainOrder
		if isTimeDomain {
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
					self.tableData.append("\(name)|\(String(format: "%.2f", value))\(unit)")
				}
			}
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
		xAxis.drawAxisLineEnabled = false
		xAxis.drawGridLinesEnabled = true
		xAxis.gridColor = UIColor(netHex: 0xF6CECE)
		xAxis.labelPosition = .bottom
		xAxis.valueFormatter = ChartCSDoubleToSecondsStringFormatter()


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

		chartView.data = lineChartData
		chartView.data?.highlightEnabled = false
		chartView.setVisibleXRangeMinimum(100.0)
		chartView.setVisibleXRangeMaximum(600.0)
		Async.main {
			self.chartView.zoom(scaleX: 0.0001, scaleY: 1, x: 0, y: 0)		// reset scale
			self.chartView.zoom(scaleX: CGFloat(600/200), scaleY: 1, x: 0, y: 0)
			self.chartView.moveViewToX(0)
		}
	}

	func calculateECGData(_ inputValues: [Int], completion completionBlock: @escaping (Bool) -> Void) {

		Async.background {
			let parameters: Parameters = ["ecgRawData": inputValues]

			self.sessionManager.request(BasicConfig.ecgCalculationURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseJSON { response in

				Async.main {
					print(response.request)  // original URL request
					print(response.response) // HTTP URL response
					print(response.data)     // server data
					print(response.result)   // result of response serialization

					self.result = [:]
					var success = false
					if let JSON = response.result.value {
						print("JSON: \(JSON)")
						if let jsonDict = JSON as? [String: AnyObject] {
							if let hrvDict = jsonDict["hrv"] as? [String: [String: AnyObject]] {
								for (hrvKey, hrvValue) in hrvDict {
									// hrvKey is useless for now. maybe useful in the future?
									for (key, value) in hrvValue {
										if let value = value.doubleValue {
											self.result[key] = value
											success = true
										}
									}
								}
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
					completionBlock(success)
				}

			}
		}

	}

}

class ChartCSDoubleToSecondsStringFormatter: NSObject, IAxisValueFormatter {
	// cs = centisecond = 0.01s (as the record is 100Hz)
	public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		return "\(String(format: "%.1f", value/100))s"
	}
}
