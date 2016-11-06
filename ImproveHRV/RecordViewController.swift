//
//  RecordViewController.swift
//  ImproveHRV
//
//  Created by Jason Ho on 31/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation
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
			initChart()
		}
	}


	func initChart() {

		chartView.noDataText = "No chart data available."
		chartView.chartDescription?.text = ""
		chartView.pinchZoomEnabled = false
		chartView.animate(xAxisDuration: 1.0)


		let rightAxis = chartView.rightAxis         // 右側Y軸
		rightAxis.drawLabelsEnabled = true         // 不顯示右側Y軸
		rightAxis.drawGridLinesEnabled = true
		//rightAxis.axisMaximum = 5000.0


		let leftAxis = chartView.leftAxis           // 左側Y軸
		leftAxis.drawLabelsEnabled = true
		leftAxis.drawAxisLineEnabled = true         // 不顯示軸
		leftAxis.drawGridLinesEnabled = true
		//leftAxis.axisMaximum = 5000.0


		let xAxis = chartView.xAxis                 // X軸
		xAxis.drawAxisLineEnabled = true            // 顯示軸
		xAxis.drawGridLinesEnabled = true          // 不於圖表內顯示縱軸線
		xAxis.labelPosition = .bottom
		//xAxis.axisMinimum = tableData[0].startDate.timeIntervalSinceReferenceDate
		xAxis.valueFormatter = ChartDateToStringFormatter()


		var dataEntries: [ChartDataEntry] = []
		if let values = tableData {
			for (index, value) in values.enumerated() {
				if let AVNN = value.result["AVNN"] {
					print(AVNN)
					print("YEP")
					let dataEntry = ChartDataEntry(x: Double(value.startDate.timeIntervalSinceReferenceDate), y: AVNN)
					dataEntries.append(dataEntry)
				}
			}
		}

		let allAverageTimeDataSet = LineChartDataSet(values: dataEntries, label: "Average Time among all")
		allAverageTimeDataSet.colors = [UIColor.red]
		allAverageTimeDataSet.drawCirclesEnabled = true

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
			if let AVNN = result["AVNN"] {
				cell.textLabel?.text = "\(String(format:"%.2f", AVNN))ms"
			}
		}
		cell.detailTextLabel?.text = "\(DateFormatter.localizedString(from: tableData[indexPath.row].startDate, dateStyle: .short, timeStyle: .medium))"
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: ResultViewController.SHOW_RESULT_SEGUE_ID, sender: self)
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
