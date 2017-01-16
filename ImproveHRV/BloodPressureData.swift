//
//  BloodPressureData.swift
//  ImproveHRV
//
//  Created by Arefly on 1/16/17.
//  Copyright © 2017 Arefly. All rights reserved.
//

import Foundation
import RealmSwift

class BloodPressureData: Object {
	dynamic var date = Date(timeIntervalSince1970: 1)
	dynamic var systoloc: Double = 0.0
	dynamic var diastolic: Double = 0.0
}
