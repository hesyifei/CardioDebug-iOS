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

		tableView.delegate = self
		tableView.dataSource = self

		realm = try! Realm()

		tableData = []


		refreshControl = UIRefreshControl()
		refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		refreshControl.addTarget(self, action: #selector(self.refreshData), for: UIControlEvents.valueChanged)
		self.tableView.addSubview(refreshControl)
		self.tableView.sendSubview(toBack: refreshControl)


		self.navigationItem.rightBarButtonItem = self.editButtonItem
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
		chartView.animate(xAxisDuration: 1.0)


		let rightAxis = chartView.rightAxis
		rightAxis.drawLabelsEnabled = true
		rightAxis.drawAxisLineEnabled = false
		rightAxis.drawGridLinesEnabled = false


		let leftAxis = chartView.leftAxis
		leftAxis.drawLabelsEnabled = true
		leftAxis.drawAxisLineEnabled = true
		leftAxis.drawGridLinesEnabled = true


		let xAxis = chartView.xAxis
		xAxis.drawAxisLineEnabled = true
		xAxis.drawGridLinesEnabled = false
		xAxis.labelPosition = .bottom
		xAxis.valueFormatter = ChartDateToStringFormatter()


		var userSDNNDataEntries: [ChartDataEntry] = []
		var userAVNNDataEntries: [ChartDataEntry] = []
		if let _ = tableData {
			let values = tableData.reversed()
			for (_, value) in values.enumerated() {
				if let SDNN = value.result["SDNN"] {
					let time = Double(value.startDate.timeIntervalSinceReferenceDate)
					print("SDNN: \(SDNN) time: \(time)")
					let userSDNNDataEntry = ChartDataEntry(x: time, y: SDNN)
					userSDNNDataEntries.append(userSDNNDataEntry)
				}
				if let AVNN = value.result["AVNN"] {
					let time = Double(value.startDate.timeIntervalSinceReferenceDate)
					print("AVNN: \(AVNN) time: \(time)")
					let userAVNNDataEntry = ChartDataEntry(x: time, y: AVNN)
					userAVNNDataEntries.append(userAVNNDataEntry)
				}
			}
		}

		let userSDNNDataSet = LineChartDataSet(values: userSDNNDataEntries, label: "Your SDNN")
		userSDNNDataSet.colors = [UIColor.gray]
		userSDNNDataSet.drawCirclesEnabled = false

		let userAVNNDataSet = LineChartDataSet(values: userAVNNDataEntries, label: "Your AVNN")
		userAVNNDataSet.axisDependency = .right
		userAVNNDataSet.colors = [UIColor.yellow]
		userAVNNDataSet.drawCirclesEnabled = false

		let lineChartData = LineChartData(dataSets: [userSDNNDataSet, userAVNNDataSet])
		chartView.data = lineChartData
	}


	// MARK: - tableView related
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableData.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
		let result = tableData[indexPath.row].result
		if !result.isEmpty {
			if let SDNN = result["SDNN"] {
				cell.textLabel?.text = "SDNN: \(String(format:"%.2f", SDNN))ms"
			}
		}
		cell.detailTextLabel?.text = "\(DateFormatter.localizedString(from: tableData[indexPath.row].startDate, dateStyle: .short, timeStyle: .medium))"
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
		let date = Date.init(timeIntervalSinceReferenceDate: TimeInterval(value))
		return formatter.string(from: date)
	}
}
