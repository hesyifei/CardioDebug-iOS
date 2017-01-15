//
//  HealthManager.swift
//  ImproveHRV
//
//  Created by Arefly on 1/15/17.
//  Copyright © 2017 Arefly. All rights reserved.
//

import HealthKit
import Foundation

class HealthManager {
	static let healthKitStore = HKHealthStore()

	static func authorizeHealthKit(completion completionBlock: @escaping (Bool, Error?) -> Void) {
		let healthKitTypesToRead: Set<HKObjectType> = [
			HKQuantityType.characteristicType(forIdentifier: .biologicalSex)!,
			HKQuantityType.characteristicType(forIdentifier: .dateOfBirth)!,
			HKQuantityType.quantityType(forIdentifier: .height)!,
			HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
			HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
			HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
			HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
		]
		var healthKitTypesToWrite: Set<HKSampleType> = [
			HKObjectType.quantityType(forIdentifier: .heartRate)!,
			HKQuantityType.quantityType(forIdentifier: .height)!,
			HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
			HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
			HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
			HKQuantityType.workoutType(),
		]
		if #available(iOS 10.0, *) {
			healthKitTypesToWrite.insert(HKObjectType.categoryType(forIdentifier: .mindfulSession)!)
		}

		// If the store is not available (for instance, iPad) return an error and don't go on.
		if !HKHealthStore.isHealthDataAvailable() {
			let error = NSError(domain: (Bundle.main.bundleIdentifier)!, code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available in this Device!"])
			completionBlock(false, error)
			return
		}

		healthKitStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { (success, error) -> Void in
			completionBlock(success, error)
		}
	}
}
