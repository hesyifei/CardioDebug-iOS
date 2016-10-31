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

	// http://stackoverflow.com/a/31730894/2603230
	dynamic var rawData: [Int] {
		get {
			return _backingRawData.map { $0.value }
		}
		set {
			_backingRawData.removeAll()
			_backingRawData.append(objectsIn: newValue.map({ IntObject(value: [$0]) }))
		}
	}
	let _backingRawData = List<IntObject>()

	override static func ignoredProperties() -> [String] {
		return ["rawData"]
	}
}

class IntObject: Object {
	dynamic var value: Int = 0
}
