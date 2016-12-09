//
//  ActivityData.swift
//  ImproveHRV
//
//  Created by Jason Ho on 9/12/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import Foundation
import RealmSwift

class ActivityData: Object {
	dynamic var id = ""
	dynamic var startDate = Date(timeIntervalSince1970: 1)
	dynamic var endDate = Date(timeIntervalSince1970: 2)
}
