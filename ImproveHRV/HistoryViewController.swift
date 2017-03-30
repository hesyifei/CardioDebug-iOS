//
//  HistoryViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 31/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import HealthKit
import Foundation
import Async
import Charts
import RealmSwift

class HistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet var tableView: UITableView!
	@IBOutlet var chartView: LineChartView!

	// MARK: - basic var
	let application = UIApplication.shared
	let defaults = UserDefaults.standard


	var refreshControl: UIRefreshControl!

	var shareAction: UIBarButtonItem!


	var realm: Realm!

	var tableData: [Any]!
	var ecgData: [ECGData]!
	var activityData: [ActivityData]!

	let cellID = "HistoryCell"
	var tagIDs: [String: Int] = [:]               // 謹記不能為0（否則於cell.tag重複）或小於100（可能於其後cell.tag設置後重複）
	var viewWidths: [String: CGFloat] = [:]
	var viewPaddings: [String: CGFloat] = [:]
	var outerViewPaddings: [String: CGFloat] = [:]

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		if let navController = self.navigationController {
			// http://stackoverflow.com/a/18969325/2603230
			navController.navigationBar.setBackgroundImage(UIImage(), for: .default)
			navController.navigationBar.shadowImage = UIImage()
			navController.navigationBar.isTranslucent = true
			navController.navigationBar.tintColor = StoredColor.middleBlue
		}


		tableView.delegate = self
		tableView.dataSource = self

		realm = try! Realm()

		tableData = []


		refreshControl = UIRefreshControl()
		refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		refreshControl.addTarget(self, action: #selector(self.refreshData), for: UIControlEvents.valueChanged)
		self.tableView.addSubview(refreshControl)
		self.tableView.sendSubview(toBack: refreshControl)


		self.navigationItem.title = "History"
		self.navigationItem.rightBarButtonItem = self.editButtonItem

		shareAction = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.shareRecords))
		self.navigationItem.setLeftBarButton(shareAction, animated: true)


		tagIDs["leftView"] = 101
		tagIDs["leftmostImageView"] = 110
		tagIDs["rightView"] = 201
		tagIDs["upperLeftLabel"] = 210
		tagIDs["lowerLeftLabel"] = 211
		tagIDs["upperRightLabel"] = 221

		viewWidths["leftView"] = 45.0

		viewPaddings["leftmostImageView"] = 10.0

		outerViewPaddings["left"] = 10.0
		outerViewPaddings["right"] = 0.0
		outerViewPaddings["top"] = 10.0
		outerViewPaddings["bottom"] = 10.0
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		print("RecordViewController viewWillAppear")

		refreshData()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == ResultViewController.SHOW_RESULT_SEGUE_ID || segue.identifier == ResultViewController.PRESENT_RESULT_MODALLY_SEGUE_ID {
			var willPresent = false
			var destination: ResultViewController? = nil
			if let destinationNavigationController = segue.destination as? UINavigationController {
				if let thisDestination = destinationNavigationController.topViewController as? ResultViewController {
					destination = thisDestination
					willPresent = true
				}
			}
			if let thisDestination = segue.destination as? ResultViewController {
				destination = thisDestination
			}
			if let destination = destination {
				if let indexPath: IndexPath = self.tableView.indexPathForSelectedRow {
					if let cellData = tableData[indexPath.row] as? ECGData {
						// to make sure the newest realm data is gotten
						if let data = realm.objects(ECGData.self).filter("startDate = %@", cellData.startDate).first {
							let passedData = PassECGResult()
							passedData.recordType = data.recordType
							passedData.startDate = data.startDate
							passedData.recordingHertz = data.recordingHertz
							passedData.rawData = data.rawData
							passedData.rrData = data.rrData
							passedData.isNew = false

							destination.passedBackData = { bool in
								if willPresent {
									print("ResultViewController passedBackData \(bool)")
									self.refreshData()
								}
							}

							destination.passedData = passedData
						}
					}
				}
			}
		}
	}

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		self.tableView.setEditing(editing, animated: animated)

		if editing {
			self.shareAction.isEnabled = false
		} else {
			self.shareAction.isEnabled = true
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func refreshData() {
		let allECGData = realm.objects(ECGData.self).sorted(byKeyPath: "startDate", ascending: false)
		//print(allECGData)
		ecgData = Array(allECGData)

		let allActivityData = realm.objects(ActivityData.self).sorted(byKeyPath: "startDate", ascending: false)
		//print(allActivityData)
		activityData = Array(allActivityData)

		var allDataWithTimeDict = [Date: Any]()
		for eachECGData in ecgData {
			allDataWithTimeDict[eachECGData.startDate] = eachECGData
		}
		for eachActivityData in activityData {
			allDataWithTimeDict[eachActivityData.startDate] = eachActivityData
		}

		// TODO: what if user allow writing don't allow reading? What if allow reading don't allow writing? What if don't have healthkit? what if both writing and reading don't allow?
		var bpSystolicResults = [HKSample]()
		var bpDiastolicResults = [HKSample]()
		HealthManager.readAllSamples(HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!) { (bloodPressureSystolicResults, bpSError) -> Void in
			if let error = bpSError {
				print("bloodPressureSystolicResults error: \(error.localizedDescription)")
			} else {
				print(bloodPressureSystolicResults)
				bpSystolicResults = bloodPressureSystolicResults
			}
			HealthManager.readAllSamples(HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!) { (bloodPressureDiastolicResults, bpDError) -> Void in
				if let error = bpDError {
					print("bloodPressureDiastolicResults error: \(error.localizedDescription)")
				} else {
					print(bloodPressureDiastolicResults)
					bpDiastolicResults = bloodPressureDiastolicResults
				}
				for (index, bpSystolicResult) in bpSystolicResults.enumerated() {
					var shouldAdd = true
					#if DEBUG
						if DebugConfig.showBPFromThisAppOnly {
							if bpSystolicResult.source != HKSource.default() {
								shouldAdd = false
							}
						}
					#endif
					if shouldAdd {
						var thisDict: [String: Any] = ["systolic": bpSystolicResult, "diastolic": bpDiastolicResults[index]]
						let allBPRealm = Array(self.realm.objects(BloodPressureData.self).filter("date = %@", bpSystolicResult.startDate))
						if allBPRealm.count == 1 {
							thisDict["heartRate"] = allBPRealm[0].heartRate
						}
						allDataWithTimeDict[bpSystolicResult.startDate] = ["bp": thisDict]
					}
				}
				self.loadDataToTableView(allDataWithTimeDict)
			}
		}

		if !self.ecgData.isEmpty {
			Async.main {
				self.initChart()
			}
		}
	}

	func loadDataToTableView(_ allDataWithTimeDict: [Date: Any]) {
		// http://stackoverflow.com/a/29552821/2603230
		let sortedDictWithValueAndKey = allDataWithTimeDict.sorted{ $0.0.compare($1.0) == .orderedDescending}
		// http://stackoverflow.com/a/31845495/2603230
		let resultantArray = sortedDictWithValueAndKey.map { $0.value }
		//print(resultantArray)

		self.tableData = resultantArray

		self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)

		if self.refreshControl.isRefreshing {
			HelperFunctions.delay(1.0) {
				self.refreshControl.endRefreshing()
			}
		}
	}


	func initChart() {

		chartView.noDataText = "No data available."
		chartView.chartDescription?.text = ""
		chartView.pinchZoomEnabled = false
		//chartView.animate(xAxisDuration: 1.0)


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
		xAxis.labelPosition = .bottom
		xAxis.valueFormatter = ChartDateToStringFormatter()
		xAxis.setLabelCount(3, force: true)


		var userSDNNDataEntries: [ChartDataEntry] = []
		var userLFHFDataEntries: [ChartDataEntry] = []
		var userAVNNDataEntries: [ChartDataEntry] = []

		var LFHFUpperLimitDataEntries: [ChartDataEntry] = []
		var LFHFLowerLimitDataEntries: [ChartDataEntry] = []

		var AVNNUpperLimitDataEntries: [ChartDataEntry] = []
		var AVNNLowerLimitDataEntries: [ChartDataEntry] = []

		var atLeastOneChartDataAvailable = false
		if let _ = ecgData {
			let values = ecgData.reversed()
			for (_, value) in values.enumerated() {
				if let SDNN = value.result["SDNN"], let LFHF = value.result["LF/HF"], let AVNN = value.result["AVNN"] {
					atLeastOneChartDataAvailable = true

					let time = Double(value.startDate.timeIntervalSinceReferenceDate)

					let LFHFUpperLimitDataEntry = ChartDataEntry(x: time, y: 11.6)
					LFHFUpperLimitDataEntries.append(LFHFUpperLimitDataEntry)
					let LFHFLowerLimitDataEntry = ChartDataEntry(x: time, y: 1.1)
					LFHFLowerLimitDataEntries.append(LFHFLowerLimitDataEntry)

					let AVNNUpperLimitDataEntry = ChartDataEntry(x: time, y: 1160)
					AVNNUpperLimitDataEntries.append(AVNNUpperLimitDataEntry)
					let AVNNLowerLimitDataEntry = ChartDataEntry(x: time, y: 785)
					AVNNLowerLimitDataEntries.append(AVNNLowerLimitDataEntry)

					//print("SDNN: \(SDNN) time: \(time)")
					let userSDNNDataEntry = ChartDataEntry(x: time, y: SDNN)
					userSDNNDataEntries.append(userSDNNDataEntry)

					//print("LFHF: \(LFHF) time: \(time)")
					let userLFHFDataEntry = ChartDataEntry(x: time, y: LFHF)
					userLFHFDataEntries.append(userLFHFDataEntry)

					//print("AVNN: \(AVNN) time: \(time)")
					let userAVNNDataEntry = ChartDataEntry(x: time, y: AVNN)
					userAVNNDataEntries.append(userAVNNDataEntry)
				}
			}
		}

		/*let userSDNNDataSet = LineChartDataSet(values: userSDNNDataEntries, label: "Your SDNN")
		userSDNNDataSet.colors = [UIColor.gray]
		userSDNNDataSet.drawCirclesEnabled = false*/

		let userLFHFDataSet = LineChartDataSet(values: userLFHFDataEntries, label: "Your LF/HF")
		userLFHFDataSet.axisDependency = .left
		userLFHFDataSet.colors = [StoredColor.middleBlue]
		userLFHFDataSet.drawCirclesEnabled = true
		userLFHFDataSet.circleRadius = 5
		userLFHFDataSet.circleColors = [StoredColor.middleBlue]
		userLFHFDataSet.mode = .linear
		userLFHFDataSet.lineWidth = 2.0
		//userLFHFDataSet.highlightColor = UIColor.red
		userLFHFDataSet.highlightEnabled = false

		let userAVNNDataSet = LineChartDataSet(values: userAVNNDataEntries, label: "Your AVNN")
		userAVNNDataSet.axisDependency = .right
		userAVNNDataSet.colors = [StoredColor.darkRed]
		userAVNNDataSet.drawCirclesEnabled = true
		userAVNNDataSet.circleRadius = 5
		userAVNNDataSet.circleColors = [StoredColor.darkRed]
		userAVNNDataSet.mode = .linear
		userAVNNDataSet.lineWidth = 2.0
		userAVNNDataSet.highlightColor = UIColor.blue
		userAVNNDataSet.highlightEnabled = false


		let LFHFUpperLimitDataSet = LineChartDataSet(values: LFHFUpperLimitDataEntries, label: nil)
		LFHFUpperLimitDataSet.axisDependency = .left
		LFHFUpperLimitDataSet.colors = [StoredColor.middleBlue.withAlphaComponent(0.3)]
		LFHFUpperLimitDataSet.drawValuesEnabled = false
		LFHFUpperLimitDataSet.drawCirclesEnabled = false
		LFHFUpperLimitDataSet.mode = .linear
		LFHFUpperLimitDataSet.lineWidth = 0.5
		LFHFUpperLimitDataSet.highlightEnabled = false
		/*LFHFUpperLimitDataSet.fillAlpha = 0.1
		LFHFUpperLimitDataSet.fillColor = StoredColor.middleBlue
		LFHFUpperLimitDataSet.drawFilledEnabled = true*/

		let LFHFLowerLimitDataSet = LineChartDataSet(values: LFHFLowerLimitDataEntries, label: nil)
		LFHFLowerLimitDataSet.axisDependency = .left
		LFHFLowerLimitDataSet.colors = [StoredColor.middleBlue.withAlphaComponent(0.3)]
		LFHFLowerLimitDataSet.drawValuesEnabled = false
		LFHFLowerLimitDataSet.drawCirclesEnabled = false
		LFHFLowerLimitDataSet.mode = .linear
		LFHFLowerLimitDataSet.lineWidth = 0.5
		LFHFLowerLimitDataSet.highlightEnabled = false
		/*LFHFLowerLimitDataSet.fillAlpha = 1.0
		LFHFLowerLimitDataSet.fillColor = UIColor.white
		LFHFLowerLimitDataSet.drawFilledEnabled = true*/

		let AVNNUpperLimitDataSet = LineChartDataSet(values: AVNNUpperLimitDataEntries, label: nil)
		AVNNUpperLimitDataSet.axisDependency = .right
		AVNNUpperLimitDataSet.colors = [StoredColor.darkRed.withAlphaComponent(0.3)]
		AVNNUpperLimitDataSet.drawValuesEnabled = false
		AVNNUpperLimitDataSet.drawCirclesEnabled = false
		AVNNUpperLimitDataSet.mode = .linear
		AVNNUpperLimitDataSet.lineWidth = 0.5
		AVNNUpperLimitDataSet.highlightEnabled = false
		//AVNNUpperLimitDataSet.fillAlpha = 0.1
		//AVNNUpperLimitDataSet.fillColor = StoredColor.darkRed
		//AVNNUpperLimitDataSet.drawFilledEnabled = true

		let AVNNLowerLimitDataSet = LineChartDataSet(values: AVNNLowerLimitDataEntries, label: nil)
		AVNNLowerLimitDataSet.axisDependency = .right
		AVNNLowerLimitDataSet.colors = [StoredColor.darkRed.withAlphaComponent(0.3)]
		AVNNLowerLimitDataSet.drawValuesEnabled = false
		AVNNLowerLimitDataSet.drawCirclesEnabled = false
		AVNNLowerLimitDataSet.mode = .linear
		AVNNLowerLimitDataSet.lineWidth = 0.5
		AVNNLowerLimitDataSet.highlightEnabled = false
		//AVNNLowerLimitDataSet.fillAlpha = 1.0
		//AVNNLowerLimitDataSet.fillColor = UIColor.white
		//AVNNLowerLimitDataSet.drawFilledEnabled = true


		if !ecgData.isEmpty && atLeastOneChartDataAvailable {
			let lineChartData = LineChartData(dataSets: [userLFHFDataSet, userAVNNDataSet, LFHFUpperLimitDataSet, LFHFLowerLimitDataSet, AVNNUpperLimitDataSet, AVNNLowerLimitDataSet])
			chartView.data = lineChartData
		} else {
			chartView.data = nil
		}
		chartView.notifyDataSetChanged()
		// only show first two legends
		let legendEntries = chartView.legend.entries
		chartView.legend.entries = Array(legendEntries.prefix(2))
		chartView.legend.resetCustom()
	}


	func shareRecords() {
		let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

		let fileName = NSURL(fileURLWithPath: documentsPath).appendingPathComponent("default.realm")
		if let filePath = fileName?.path {
			let fileManager = FileManager.default
			if fileManager.fileExists(atPath: filePath) {
				let fileData = NSURL(fileURLWithPath: filePath)

				let objectsToShare = [fileData]
				let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

				if let popoverVC = activityVC.popoverPresentationController {
					popoverVC.barButtonItem = self.navigationItem.leftBarButtonItem
				}
				self.present(activityVC, animated: true, completion: nil)
			}
		}
	}


	// MARK: - tableView related
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableData.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		/*** 初始化TableCell開始 ***/
		var cell: UITableViewCell!

		var leftView: UIView!
		var leftmostImageView: UIImageView!

		var rightView: UIView!
		var upperLeftLabel: PaddingLabel!
		var lowerLeftLabel: PaddingLabel!
		var upperRightLabel: PaddingLabel!


		if let reuseCell = tableView.dequeueReusableCell(withIdentifier: cellID) {
			//print("目前Cell \(indexPath.row)已創建過，即將dequeue這個cell")
			cell = reuseCell

			leftView = cell?.contentView.viewWithTag(tagIDs["leftView"]!)
			leftmostImageView = cell?.contentView.viewWithTag(tagIDs["leftmostImageView"]!) as! UIImageView

			rightView = cell?.contentView.viewWithTag(tagIDs["rightView"]!)
			lowerLeftLabel = cell?.contentView.viewWithTag(tagIDs["lowerLeftLabel"]!) as! PaddingLabel
			upperLeftLabel = cell?.contentView.viewWithTag(tagIDs["upperLeftLabel"]!) as! PaddingLabel
			upperRightLabel = cell?.contentView.viewWithTag(tagIDs["upperRightLabel"]!) as! PaddingLabel
		} else {
			//print("目前Cell \(indexPath.row)為nil，即將創建新Cell")

			cell = UITableViewCell(style: .default, reuseIdentifier: cellID)
			let contentView = cell.contentView

			// use addConstraint instead of addConstraints because Swift compile it faster


			/** leftView 開始 **/
			leftView = UIView()
			leftView.tag = tagIDs["leftView"]!
			leftView.backgroundColor = UIColor.clear
			leftView.translatesAutoresizingMaskIntoConstraints = false
			contentView.insertSubview(leftView, at: 0)

			contentView.addConstraint(NSLayoutConstraint(item: leftView, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: outerViewPaddings["left"]!))
			contentView.addConstraint(NSLayoutConstraint(item: leftView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: outerViewPaddings["top"]!))
			contentView.addConstraint(NSLayoutConstraint(item: leftView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -outerViewPaddings["bottom"]!))
			contentView.addConstraint(NSLayoutConstraint(item: leftView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: viewWidths["leftView"]!))            // 寬度=numberLabel+timelineView的寬度


			/** leftmostImageView 開始 **/
			leftmostImageView = UIImageView()
			leftmostImageView.tag = tagIDs["leftmostImageView"]!
			leftmostImageView.translatesAutoresizingMaskIntoConstraints = false
			leftView.addSubview(leftmostImageView)

			contentView.addConstraint(NSLayoutConstraint(item: leftmostImageView, attribute: .leading, relatedBy: .equal, toItem: leftView, attribute: .leading, multiplier: 1.0, constant: viewPaddings["leftmostImageView"]!))
			contentView.addConstraint(NSLayoutConstraint(item: leftmostImageView, attribute: .trailing, relatedBy: .equal, toItem: leftView, attribute: .trailing, multiplier: 1.0, constant: -viewPaddings["leftmostImageView"]!))
			contentView.addConstraint(NSLayoutConstraint(item: leftmostImageView, attribute: .height, relatedBy: .equal, toItem: leftmostImageView, attribute: .width, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: leftmostImageView, attribute: .centerX, relatedBy: .equal, toItem: leftView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: leftmostImageView, attribute: .centerY, relatedBy: .equal, toItem: leftView, attribute: .centerY, multiplier: 1.0, constant: 0.0))


			/** rightView 開始 **/
			rightView = UIView()
			rightView.tag = tagIDs["rightView"]!
			rightView.backgroundColor = UIColor.clear
			rightView.translatesAutoresizingMaskIntoConstraints = false
			contentView.insertSubview(rightView, at: 0)

			contentView.addConstraint(NSLayoutConstraint(item: rightView, attribute: .leading, relatedBy: .equal, toItem: leftView, attribute: .trailing, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: rightView, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: -outerViewPaddings["right"]!))
			contentView.addConstraint(NSLayoutConstraint(item: rightView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: outerViewPaddings["top"]!))
			contentView.addConstraint(NSLayoutConstraint(item: rightView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -outerViewPaddings["bottom"]!))


			/** upperLeftLabel 開始 **/
			upperLeftLabel = PaddingLabel()
			upperLeftLabel.tag = tagIDs["upperLeftLabel"]!
			upperLeftLabel.translatesAutoresizingMaskIntoConstraints = false
			rightView.addSubview(upperLeftLabel)

			contentView.addConstraint(NSLayoutConstraint(item: upperLeftLabel, attribute: .leading, relatedBy: .equal, toItem: rightView, attribute: .leading, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: upperLeftLabel, attribute: .top, relatedBy: .equal, toItem: rightView, attribute: .top, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: upperLeftLabel, attribute: .height, relatedBy: .equal, toItem: rightView, attribute: .height, multiplier: 0.6, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: upperLeftLabel, attribute: .width, relatedBy: .equal, toItem: rightView, attribute: .width, multiplier: 0.65, constant: 0.0))


			/** lowerLeftLabel 開始 **/
			lowerLeftLabel = PaddingLabel()
			lowerLeftLabel.tag = tagIDs["lowerLeftLabel"]!
			lowerLeftLabel.translatesAutoresizingMaskIntoConstraints = false
			rightView.addSubview(lowerLeftLabel)

			contentView.addConstraint(NSLayoutConstraint(item: lowerLeftLabel, attribute: .leading, relatedBy: .equal, toItem: upperLeftLabel, attribute: .leading, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: lowerLeftLabel, attribute: .trailing, relatedBy: .equal, toItem: rightView, attribute: .trailing, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: lowerLeftLabel, attribute: .top, relatedBy: .equal, toItem: upperLeftLabel, attribute: .bottom, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: lowerLeftLabel, attribute: .bottom, relatedBy: .equal, toItem: rightView, attribute: .bottom, multiplier: 1.0, constant: 0.0))



			/** upperRightLabel 開始 **/
			upperRightLabel = PaddingLabel()
			upperRightLabel.tag = tagIDs["upperRightLabel"]!
			upperRightLabel.textAlignment = .right
			upperRightLabel.translatesAutoresizingMaskIntoConstraints = false
			rightView.addSubview(upperRightLabel)

			contentView.addConstraint(NSLayoutConstraint(item: upperRightLabel, attribute: .leading, relatedBy: .equal, toItem: upperLeftLabel, attribute: .trailing, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: upperRightLabel, attribute: .trailing, relatedBy: .equal, toItem: rightView, attribute: .trailing, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: upperRightLabel, attribute: .top, relatedBy: .equal, toItem: rightView, attribute: .top, multiplier: 1.0, constant: 0.0))
			contentView.addConstraint(NSLayoutConstraint(item: upperRightLabel, attribute: .height, relatedBy: .equal, toItem: upperLeftLabel, attribute: .height, multiplier: 1.0, constant: 0.0))



			#if DEBUG
				if DebugConfig.showHistoryVCCellElementsBackground {
					leftmostImageView.backgroundColor = UIColor.brown
					upperLeftLabel.backgroundColor = UIColor.purple
					lowerLeftLabel.backgroundColor = UIColor.orange
					upperRightLabel.backgroundColor = UIColor.yellow
				}
			#endif

		}

		cell.accessoryType = .disclosureIndicator
		cell.separatorInset = UIEdgeInsetsMake(0, outerViewPaddings["left"]!+viewWidths["leftView"]!+PaddingLabel.padding, 0, 0)

		/*** 初始化TableCell結束 ***/



		/*** 修改數據開始 ***/
		let section = indexPath.section
		let row = indexPath.row
		cell.tag = section*1000 + row

		var upperLeftFontSize: CGFloat = 20.0
		var upperLeftColor = UIColor.black
		var upperLeftText = "[...]"
		var upperRightFontSize: CGFloat = 20.0
		var upperRightText = "[...]"
		var thisDate = Date(timeIntervalSinceNow: 0)
		var thisNote = ""

		if let cellECGData = tableData[row] as? ECGData {
			var result = cellECGData.result
			if result.isEmpty {
				// FIXME: weird bug that result cannot be found in cellECGData if PPG is recorded
				// WORKAROUND: reload data from realm
				if let thisData = realm.objects(ECGData.self).filter("startDate = %@", cellECGData.startDate).first {
					result = thisData.result
				}
			}
			if !result.isEmpty {
				if let LFHF = result["LF/HF"] {
					upperLeftText = "LF/HF: \(String(format:"%.2f", LFHF))"
				}
				if let averageBpm = result["AvgHR"] {
					upperRightText = "\(String(format:"%.0f", averageBpm)) bpm"
				}
			}
			thisDate = cellECGData.startDate
			thisNote = cellECGData.note

			upperLeftColor = StoredColor.middleBlue

			if let iconImage = UIImage(named: "CellIcon-ECG") {
				leftmostImageView.image = iconImage
			}
		} else if let cellActivityData = tableData[row] as? ActivityData {
			let cellActivityId = cellActivityData.id
			if let fullData = defaults.object(forKey: RemedyListViewController.DEFAULTS_ACTIVITIES_DATA) as? [String: Any] {
				if let data = fullData["required"] as? [String: Any] {
					if let activityData = data[cellActivityId] as? [String: Any] {
						if let title = activityData["title"] as? String, let icon = activityData["icon"] as? String {
							upperLeftText = "\(title)"

							let duration = cellActivityData.endDate.timeIntervalSince(cellActivityData.startDate)
							let (h, m, _) = HelperFunctions.secondsToHoursMinutesSeconds(Int(duration))
							if h > 0 {
								upperRightText = String(format: "%d h %d min", h, m)
							} else {
								upperRightText = String(format: "%d min", m)
							}

							if let iconImage = icon.imageFromEmoji() {
								leftmostImageView.image = iconImage
							}
						}
					}
				}
			}
			thisDate = cellActivityData.startDate

			upperLeftColor = StoredColor.darkGreen
		} else if let otherData = tableData[row] as? [String: Any] {
			if let bpData = otherData["bp"] as? [String: Any] {
				if let systolicData = bpData["systolic"] as? HKQuantitySample, let diastolicData = bpData["diastolic"] as? HKQuantitySample {
					thisDate = systolicData.startDate
					let unit = HKUnit.millimeterOfMercury()
					let systolicValue = Int(systolicData.quantity.doubleValue(for: unit))
					let diastolicValue = Int(diastolicData.quantity.doubleValue(for: unit))
					upperLeftText = String(format: "%d/%d mmHg", systolicValue, diastolicValue)

					upperLeftColor = StoredColor.darkRed

					if let heartRateData = bpData["heartRate"] as? Double {
						upperRightText = "\(String(format:"%.0f", heartRateData)) bpm"
					} else {
						upperRightText = ""
					}

					if let iconImage = UIImage(named: "CellIcon-BP") {
						leftmostImageView.image = iconImage
					}
				}
			}
		}


		upperLeftLabel.textColor = upperLeftColor
		upperLeftLabel.font = UIFont(name: (upperLeftLabel.font?.fontName)!, size: upperLeftFontSize)
		lowerLeftLabel.textColor = UIColor(netHex: 0x8e9092)
		upperRightLabel.font = UIFont(name: (upperRightLabel.font?.fontName)!, size: upperRightFontSize)


		upperLeftLabel.text = upperLeftText
		var lowerLeftLabelText = "\(DateFormatter.localizedString(from: thisDate, dateStyle: .short, timeStyle: .short))"
		if !thisNote.isEmpty {
			lowerLeftLabelText += " (\(thisNote))"
		}
		lowerLeftLabel.text = lowerLeftLabelText
		upperRightLabel.text = upperRightText

		/*** 修改數據結束 ***/

		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50.0+outerViewPaddings["top"]!+outerViewPaddings["bottom"]!
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let _ = tableData[indexPath.row] as? ECGData {
			if self.traitCollection.horizontalSizeClass == .compact {
				self.performSegue(withIdentifier: ResultViewController.SHOW_RESULT_SEGUE_ID, sender: self)
			} else {
				self.performSegue(withIdentifier: ResultViewController.PRESENT_RESULT_MODALLY_SEGUE_ID, sender: self)
			}

		}
		self.tableView.deselectRow(at: indexPath, animated: true)
	}

	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return false
	}

	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		let row = indexPath.row
		if editingStyle == .delete {
			var successfullyDelete = true
			if let thisECGData = tableData[row] as? ECGData {
				ecgData.remove(object: thisECGData)
				try! realm.write {
					// TODO: consider add Async background and loading indicator (really slow by now)
					thisECGData.cleanAllData()
					realm.delete(thisECGData)
				}
			} else if let thisActivityData = tableData[row] as? ActivityData {
				try! realm.write {
					realm.delete(thisActivityData)
				}
			} else if let otherData = tableData[row] as? [String: Any] {
				if let bpData = otherData["bp"] as? [String: Any] {
					if let systolicData = bpData["systolic"] as? HKQuantitySample, let diastolicData = bpData["diastolic"] as? HKQuantitySample {
						let allBPRealm = Array(realm.objects(BloodPressureData.self).filter("date = %@", systolicData.startDate))
						if allBPRealm.count == 1 {
							try! realm.write {
								print("deleting realm object \(allBPRealm[0])")
								realm.delete(allBPRealm[0])
							}
						}

						if #available(iOS 9.0, *) {
							print([systolicData, diastolicData])
							HealthManager.healthKitStore.delete([systolicData, diastolicData]) { (success, error) -> Void in
								print("Delete BP state: \(success) \(error)")
								if !success {
									HelperFunctions.showAlert(self, title: "Error", message: "Failed to delete!\nPlease delete this record in Health app manually.", completion: nil)
								}
								if (bpData["heartRate"] as? Double) != nil {
									HealthManager.readSampleStoredAt(time: systolicData.startDate, of: HKSampleType.quantityType(forIdentifier: .heartRate)!, needToBeFromCurrentSouce: true) { (returningSample, error) -> Void in
										if let error = error {
											print("Finding heart rate error: \(error)")
											HelperFunctions.showAlert(self, title: "Error", message: "Failed to found this heart record in Health app!\nPlease delete this record in Health app manually.", completion: nil)
										} else if let returningSample = returningSample {
											HealthManager.healthKitStore.delete(returningSample)  { (success, error) -> Void in
												print("Delete HR state: \(success) \(error)")
												if !success {
													HelperFunctions.showAlert(self, title: "Error", message: "Failed to delete heart rate!\nPlease delete this record in Health app manually.", completion: nil)
												}
											}
										}
									}
								}
							}
						} else {
							print("Cannot delete as `delete` only support after iOS 9.0")
						}
					}
				}
				// TODO: what if stored only in realm?
			} else {
				successfullyDelete = false
			}
			if successfullyDelete {
				tableData.remove(at: indexPath.row)
				tableView.deleteRows(at: [indexPath], with: .automatic)
			}

			Async.main {
				self.initChart()
			}
		}
	}
}

class ChartDateToStringFormatter: NSObject, IAxisValueFormatter {
	public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "dd-MM-yyyy HH:mm"
		let date = Date(timeIntervalSinceReferenceDate: TimeInterval(value))
		return formatter.string(from: date)
	}
}
