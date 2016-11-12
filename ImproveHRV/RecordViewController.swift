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
		rightAxis.drawLabelsEnabled = false
		rightAxis.drawGridLinesEnabled = false


		let leftAxis = chartView.leftAxis
		leftAxis.drawLabelsEnabled = false
		leftAxis.drawAxisLineEnabled = true
		leftAxis.drawGridLinesEnabled = true


		let xAxis = chartView.xAxis
		xAxis.drawAxisLineEnabled = true
		xAxis.drawGridLinesEnabled = false
		xAxis.labelPosition = .bottom
		xAxis.valueFormatter = ChartDateToStringFormatter()


		var dataEntries: [ChartDataEntry] = []
		if let values = tableData {
			for (index, value) in values.enumerated() {
				if let SDNN = value.result["SDNN"] {
					print(SDNN)
					let xValue = Double(value.startDate.timeIntervalSinceReferenceDate)
					print("YEP \(xValue)")
					print("NOO \(500030269.186681+Double(index)*0.6)\n")
					//let dataEntry = ChartDataEntry(x: 500030269.186681+Double(index)*0.6, y: SDNN)
					let dataEntry = ChartDataEntry(x: xValue, y: SDNN)
					dataEntries.append(dataEntry)
				}
			}
		}

		let allAverageTimeDataSet = LineChartDataSet(values: dataEntries, label: "Your SDNN")
		allAverageTimeDataSet.colors = [UIColor.gray]
		allAverageTimeDataSet.drawCirclesEnabled = false

		let lineChartData = LineChartData(dataSets: [allAverageTimeDataSet])
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
		formatter.dateFormat = "dd-MM-yyyy"
		let date = Date.init(timeIntervalSinceReferenceDate: TimeInterval(value))
		return formatter.string(from: date)
	}
}
