//
//  RecordViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 31/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation
import Async
import Charts
import RealmSwift

class RecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet var tableView: UITableView!
	@IBOutlet var chartView: LineChartView!

	var refreshControl: UIRefreshControl!

	var realm: Realm!

	var tableData: [ECGData]!

	// MARK: - override func
	override func viewDidLoad() {
		super.viewDidLoad()

		if let navController = self.navigationController {
			// http://stackoverflow.com/a/18969325/2603230
			navController.navigationBar.setBackgroundImage(UIImage(), for: .default)
			navController.navigationBar.shadowImage = UIImage()
			navController.navigationBar.isTranslucent = true
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

		let shareAction = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.shareRecords))
		self.navigationItem.setLeftBarButton(shareAction, animated: true)
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
		if segue.identifier == ResultViewController.SHOW_RESULT_SEGUE_ID {
			if let destination = segue.destination as? ResultViewController {
				if let indexPath: IndexPath = self.tableView.indexPathForSelectedRow {
					let data = tableData[indexPath.row]

					let passedData = PassECGResult()
					passedData.startDate = data.startDate
					passedData.rawData = data.rawData
					passedData.isNew = false

					destination.passedData = passedData


					self.tableView.deselectRow(at: indexPath, animated: true)
				}
			}
		}
	}

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		self.tableView.setEditing(editing, animated: animated)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func refreshData() {
		let allECGData = realm.objects(ECGData.self).sorted(byProperty: "startDate", ascending: false)
		//print(allECGData)

		tableData = Array(allECGData)

		self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)

		if refreshControl.isRefreshing {
			HelperFunctions.delay(1.0) {
				self.refreshControl.endRefreshing()
			}
		}

		if !tableData.isEmpty {
			Async.main {
				self.initChart()
			}
		}
	}


	func initChart() {

		chartView.noDataText = "No chart data available."
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
		xAxis.drawAxisLineEnabled = true
		xAxis.drawGridLinesEnabled = false
		xAxis.labelPosition = .bottom
		xAxis.valueFormatter = ChartDateToStringFormatter()
		xAxis.setLabelCount(3, force: true)


		var userSDNNDataEntries: [ChartDataEntry] = []
		var userLFHFDataEntries: [ChartDataEntry] = []
		var userAVNNDataEntries: [ChartDataEntry] = []
		if let _ = tableData {
			let values = tableData.reversed()
			for (_, value) in values.enumerated() {
				let time = Double(value.startDate.timeIntervalSinceReferenceDate)
				if let SDNN = value.result["SDNN"] {
					print("SDNN: \(SDNN) time: \(time)")
					let userSDNNDataEntry = ChartDataEntry(x: time, y: SDNN)
					userSDNNDataEntries.append(userSDNNDataEntry)
				}
				if let LFHF = value.result["LF/HF"] {
					print("LFHF: \(LFHF) time: \(time)")
					let userLFHFDataEntry = ChartDataEntry(x: time, y: LFHF)
					userLFHFDataEntries.append(userLFHFDataEntry)
				}
				if let AVNN = value.result["AVNN"] {
					print("AVNN: \(AVNN) time: \(time)")
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
		userLFHFDataSet.colors = [UIColor(netHex: 0xba2e57)]
		userLFHFDataSet.drawCirclesEnabled = true
		userLFHFDataSet.circleRadius = 5
		userLFHFDataSet.circleColors = [UIColor(netHex: 0xba2e57)]
		userLFHFDataSet.mode = .cubicBezier
		userLFHFDataSet.lineWidth = 2.0
		userLFHFDataSet.highlightColor = UIColor.red

		let userAVNNDataSet = LineChartDataSet(values: userAVNNDataEntries, label: "Your AVNN")
		userAVNNDataSet.axisDependency = .right
		userAVNNDataSet.colors = [UIColor(netHex: 0x509ed4)]
		userAVNNDataSet.drawCirclesEnabled = true
		userAVNNDataSet.circleRadius = 5
		userAVNNDataSet.circleColors = [UIColor(netHex: 0x509ed4)]
		userAVNNDataSet.mode = .cubicBezier
		userAVNNDataSet.lineWidth = 2.0
		userAVNNDataSet.highlightColor = UIColor.blue

		let lineChartData = LineChartData(dataSets: [userLFHFDataSet, userAVNNDataSet])
		chartView.data = lineChartData
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

	/*func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
		let result = tableData[indexPath.row].result
		var cellText = "[...]"
		if !result.isEmpty {
			if let SDNN = result["SDNN"] {
				cellText = "SDNN: \(String(format:"%.2f", SDNN))ms"
			}
		}
		cell.textLabel?.text = cellText
		cell.detailTextLabel?.text = "\(DateFormatter.localizedString(from: tableData[indexPath.row].startDate, dateStyle: .short, timeStyle: .medium))"
		return cell
	}*/

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		/*** 初始化TableCell開始 ***/

		let cellID = "HistoryCell"
		let tagIDs: [String: Int] = [               // 謹記不能為0（否則於cell.tag重複）或小於100（可能於其後cell.tag設置後重複）
			"leftView": 100,
			"numberLabel": 120,
			"totalTimeLabel": 121,
			"rightView": 200,
			"timeCurrentLabel": 210,
			"timeReferenceLabel": 211,
			"speedCurrentLabel": 221,
			]

		let viewWidths: [String: CGFloat] = [       // 固定寬度之view
			"numberLabel": 40.0,
			"timelineView": 15.0,
			]
		let viewHeights: [String: CGFloat] = [       // 固定高度之view
			"totalTimeLabel": 20.0,
			]


		var cell: UITableViewCell!

		var leftView: UIView!
		var numberLabel: UILabel!
		var totalTimeLabel: UILabel!

		var rightView: UIView!
		var timeCurrentLabel: PaddingLabel!
		var timeReferenceLabel: PaddingLabel!
		var speedCurrentLabel: PaddingLabel!


		if let reuseCell = tableView.dequeueReusableCell(withIdentifier: cellID) {
			cell = reuseCell


			leftView = cell?.contentView.viewWithTag(tagIDs["leftView"]!)
			numberLabel = cell?.contentView.viewWithTag(tagIDs["numberLabel"]!) as! UILabel
			totalTimeLabel = cell?.contentView.viewWithTag(tagIDs["totalTimeLabel"]!) as! UILabel

			rightView = cell?.contentView.viewWithTag(tagIDs["rightView"]!)
			timeReferenceLabel = cell?.contentView.viewWithTag(tagIDs["timeReferenceLabel"]!) as! PaddingLabel
			timeCurrentLabel = cell?.contentView.viewWithTag(tagIDs["timeCurrentLabel"]!) as! PaddingLabel
			speedCurrentLabel = cell?.contentView.viewWithTag(tagIDs["speedCurrentLabel"]!) as! PaddingLabel
		} else {
			print("目前Cell \(indexPath.row)為nil，即將創建新Cell")

			cell = UITableViewCell(style: .default, reuseIdentifier: cellID)


			/** leftView 開始（為使其供點擊） **/
			leftView = UIView()
			leftView.tag = tagIDs["leftView"]!
			leftView.backgroundColor = UIColor.clear
			leftView.isUserInteractionEnabled = true
			leftView.translatesAutoresizingMaskIntoConstraints = false
			cell.contentView.insertSubview(leftView, at: 0)
			cell.contentView.addConstraints([
				NSLayoutConstraint(item: leftView, attribute: .leading, relatedBy: .equal, toItem: cell.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: leftView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: leftView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: leftView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: viewWidths["numberLabel"]!),            // 寬度=numberLabel+timelineView的寬度
				])


			/** numberLabel 開始 **/
			numberLabel = UILabel()
			numberLabel.tag = tagIDs["numberLabel"]!
			numberLabel.textAlignment = .center
			numberLabel.isUserInteractionEnabled = true
			numberLabel.translatesAutoresizingMaskIntoConstraints = false
			leftView.addSubview(numberLabel)

			cell.contentView.addConstraints([
				NSLayoutConstraint(item: numberLabel, attribute: .leading, relatedBy: .equal, toItem: leftView, attribute: .leading, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: numberLabel, attribute: .top, relatedBy: .equal, toItem: leftView, attribute: .top, multiplier: 1.0, constant: 5),
				NSLayoutConstraint(item: numberLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 6),
				NSLayoutConstraint(item: numberLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: viewWidths["numberLabel"]!),
				])


			/** totalTimeLabel 開始 **/
			totalTimeLabel = UILabel()
			totalTimeLabel.tag = tagIDs["totalTimeLabel"]!
			totalTimeLabel.textAlignment = .center
			totalTimeLabel.isUserInteractionEnabled = true
			totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
			leftView.addSubview(totalTimeLabel)

			cell.contentView.addConstraints([
				NSLayoutConstraint(item: totalTimeLabel, attribute: .leading, relatedBy: .equal, toItem: leftView, attribute: .leading, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: totalTimeLabel, attribute: .top, relatedBy: .equal, toItem: numberLabel, attribute: .bottom, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: totalTimeLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: viewHeights["totalTimeLabel"]!),
				NSLayoutConstraint(item: totalTimeLabel, attribute: .width, relatedBy: .equal, toItem: numberLabel, attribute: .width, multiplier: 1.0, constant: 0.0),
				])



			/** rightView 開始 **/
			rightView = UIView()
			rightView.tag = tagIDs["rightView"]!
			rightView.backgroundColor = UIColor.clear
			rightView.translatesAutoresizingMaskIntoConstraints = false
			cell.contentView.insertSubview(rightView, at: 0)
			cell.contentView.addConstraints([
				NSLayoutConstraint(item: rightView, attribute: .leading, relatedBy: .equal, toItem: leftView, attribute: .trailing, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: rightView, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: rightView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 25.0),
				NSLayoutConstraint(item: rightView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
				])


			/** timeCurrentLabel 開始 **/
			timeCurrentLabel = PaddingLabel()
			timeCurrentLabel.tag = tagIDs["timeCurrentLabel"]!
			timeCurrentLabel.translatesAutoresizingMaskIntoConstraints = false
			rightView.addSubview(timeCurrentLabel)

			cell.contentView.addConstraints([
				NSLayoutConstraint(item: timeCurrentLabel, attribute: .leading, relatedBy: .equal, toItem: rightView, attribute: .leading, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: timeCurrentLabel, attribute: .top, relatedBy: .equal, toItem: rightView, attribute: .top, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: timeCurrentLabel, attribute: .height, relatedBy: .equal, toItem: rightView, attribute: .height, multiplier: 0.6, constant: 0.0),
				NSLayoutConstraint(item: timeCurrentLabel, attribute: .width, relatedBy: .equal, toItem: rightView, attribute: .width, multiplier: 0.5, constant: 0.0),
				])


			/** timeReferenceLabel 開始 **/
			timeReferenceLabel = PaddingLabel()
			timeReferenceLabel.tag = tagIDs["timeReferenceLabel"]!
			timeReferenceLabel.translatesAutoresizingMaskIntoConstraints = false
			rightView.addSubview(timeReferenceLabel)

			cell.contentView.addConstraints([
				NSLayoutConstraint(item: timeReferenceLabel, attribute: .leading, relatedBy: .equal, toItem: timeCurrentLabel, attribute: .leading, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: timeReferenceLabel, attribute: .trailing, relatedBy: .equal, toItem: rightView, attribute: .trailing, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: timeReferenceLabel, attribute: .top, relatedBy: .equal, toItem: timeCurrentLabel, attribute: .bottom, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: timeReferenceLabel, attribute: .bottom, relatedBy: .equal, toItem: rightView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
				])



			/** speedCurrentLabel 開始 **/
			speedCurrentLabel = PaddingLabel()
			speedCurrentLabel.tag = tagIDs["speedCurrentLabel"]!
			speedCurrentLabel.textAlignment = .right
			speedCurrentLabel.translatesAutoresizingMaskIntoConstraints = false
			rightView.addSubview(speedCurrentLabel)

			cell.contentView.addConstraints([
				NSLayoutConstraint(item: speedCurrentLabel, attribute: .leading, relatedBy: .equal, toItem: timeCurrentLabel, attribute: .trailing, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: speedCurrentLabel, attribute: .trailing, relatedBy: .equal, toItem: rightView, attribute: .trailing, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: speedCurrentLabel, attribute: .top, relatedBy: .equal, toItem: rightView, attribute: .top, multiplier: 1.0, constant: 0.0),
				NSLayoutConstraint(item: speedCurrentLabel, attribute: .height, relatedBy: .equal, toItem: timeCurrentLabel, attribute: .height, multiplier: 1.0, constant: 0.0),
				])



			/*
			numberLabel.backgroundColor = UIColor.brownColor()
			totalTimeLabel.backgroundColor = UIColor.lightGrayColor()
			timeCurrentLabel.backgroundColor = UIColor.purpleColor()
			timeReferenceLabel.backgroundColor = UIColor.orangeColor()
			speedCurrentLabel.backgroundColor = UIColor.yellowColor()
			*/

		}



		//timelineView.backgroundColor = UIColor.blueColor()
		//DDLogVerbose("DONE \(cell?.contentView.subviews)")
		/*** 初始化TableCell結束 ***/



		/*** 修改數據開始 ***/
		let section = indexPath.section
		let row = indexPath.row


		numberLabel.font = UIFont(name: (numberLabel.font?.fontName)!, size: 15.0)
		totalTimeLabel.font = UIFont(name: (totalTimeLabel.font?.fontName)!, size: 8.0)

		timeCurrentLabel.font = UIFont(name: (timeCurrentLabel.font?.fontName)!, size: 28.0)
		timeReferenceLabel.textColor = UIColor.gray
		speedCurrentLabel.font = UIFont(name: (speedCurrentLabel.font?.fontName)!, size: 28.0)


		totalTimeLabel.text = "YEP"


		cell.tag = section*1000 + row

		//if(!isBottom){
			numberLabel.text = "#uep"

			timeCurrentLabel.text = "nooo"

			timeReferenceLabel.text = "Ⓐ 02:00    Ⓣ 05:00"

			speedCurrentLabel.text = "HAHA"
		/*}else{
			numberLabel.text = "Ⓑ"
			timeCurrentLabel.text = ""
			timeReferenceLabel.text = ""
			speedCurrentLabel.text = ""
		}*/

		/*** 修改數據結束 ***/

		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 85.0
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.deselectRow(at: indexPath, animated: true)
		self.performSegue(withIdentifier: ResultViewController.SHOW_RESULT_SEGUE_ID, sender: self)
	}

	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return false
	}

	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == .delete) {
			try! realm.write {
				realm.delete(tableData[indexPath.row])
			}
			tableData.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .automatic)

			initChart()
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
