//
//  ECGData.swift
//  ImproveHRV
//
//  Created by Jason Ho on 31/10/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import Foundation
import RealmSwift

class ECGData: Object {
	dynamic var startDate = Date(timeIntervalSince1970: 1)
	dynamic var duration: Double = 0.0

	dynamic var result: [String: Double] {
		get {
			if _resultKeys.isEmpty { return [:] } // Empty dict = default; change to other if desired
			else {
				var ret: [String: Double] = [:]
				let _ = Array(0..<(_resultKeys.count)).map{ ret[_resultKeys[$0].value] = _resultValues[$0].value }
				return ret
			}
		}
		set {
			_resultKeys.removeAll()
			_resultValues.removeAll()
			_resultKeys.append(objectsIn: newValue.keys.map({ StringObject(value: [$0]) }))
			_resultValues.append(objectsIn: newValue.values.map({ DoubleObject(value: [$0]) }))
		}
	}
	var _resultKeys = List<StringObject>();
	var _resultValues = List<DoubleObject>();


	// http://stackoverflow.com/a/31730894/2603230
	dynamic var rawData: [Int] {
		get {
			return _ecgRawData.map { $0.value }
		}
		set {
			_ecgRawData.removeAll()
			_ecgRawData.append(objectsIn: newValue.map({ IntObject(value: [$0]) }))
		}
	}
	let _ecgRawData = List<IntObject>()

	dynamic var fftData: [Double] {
		get {
			return _fftRawData.map { $0.value }
		}
		set {
			_fftRawData.removeAll()
			_fftRawData.append(objectsIn: newValue.map({ DoubleObject(value: [$0]) }))
		}
	}
	let _fftRawData = List<DoubleObject>()

	override static func ignoredProperties() -> [String] {
		return ["rawData", "fftData", "result"]
	}

	func cleanAllData() {
		self.realm?.delete(_ecgRawData)
		rawData = []

		self.realm?.delete(_fftRawData)
		fftData = []

		self.realm?.delete(_resultKeys)
		self.realm?.delete(_resultValues)
		result = [:]
	}
}

class IntObject: Object {
	dynamic var value: Int = 0
}

class DoubleObject: Object {
	dynamic var value: Double = 0.0
}

class StringObject: Object {
	dynamic var value: String = ""
}
