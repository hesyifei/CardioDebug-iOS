//
//  HealthManager.swift
//  ImproveHRV
//
//  Created by Arefly on 1/15/17.
//  Copyright © 2017 Arefly. All rights reserved.
//

import HealthKit
import Foundation
import Async

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

	static func readAllSamples(_ sampleType: HKSampleType, completion completionBlock: @escaping ([HKSample], Error?) -> Void) {
		let past = Date.distantPast
		let now = Date()
		let mostRecentPredicate = HKQuery.predicateForSamples(withStart: past, end:now, options: [])

		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let limit = Int(HKObjectQueryNoLimit)

		let query = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor]) { (query, results, error) -> Void in

			Async.main {
				if let error = error {
					completionBlock([HKSample](), error)
					return
				}
				completionBlock(results!, nil)
			}
		}
		self.healthKitStore.execute(query)
	}

	static func readSampleStoredAt(time: Date, of sampleType: HKSampleType, needToBeFromCurrentSouce: Bool = false, completion completionBlock: @escaping (HKSample?, Error?) -> Void) {
		let predicate = HKQuery.predicateForSamples(withStart: time.addingTimeInterval(-1), end: time.addingTimeInterval(1), options: [])
		let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { (sampleQuery, results, error) -> Void in
			print("readSampleStoredAt got query results: \(sampleQuery), \(results), \(error)")
			if let error = error {
				completionBlock(nil, error)
				return
			}
			if let result = results?.first {
				//print("result.source: \(result.source), HKSource.default(): \(HKSource.default())")
				var isSuccess = true
				if needToBeFromCurrentSouce {
					if result.source != HKSource.default() {
						isSuccess = false
					}
				}
				if isSuccess {
					completionBlock(result, nil)
					return
				}
			}
			completionBlock(nil, NSError(domain: (Bundle.main.bundleIdentifier)!, code: 2, userInfo: [NSLocalizedDescriptionKey: "No result with this predicate return!"]))
		}
		self.healthKitStore.execute(query)
	}

	// http://stackoverflow.com/q/27268665/2603230
	static func saveHeartRate(date: Date = Date(), heartRate heartRateValue: Double, completion completionBlock: @escaping (Bool, Error?) -> Void) {
		let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
		let quantity = HKQuantity(unit: unit, doubleValue: heartRateValue)
		let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!

		let heartRateSample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)

		self.healthKitStore.save(heartRateSample) { (success, error) -> Void in
			if !success {
				print("An error occured saving the HR sample \(heartRateSample). In your app, try to handle this gracefully. The error was: \(error).")
			}
			completionBlock(success, error)
		}
	}

	// http://stackoverflow.com/q/25642949/2603230
	static func saveBloodPressure(date: Date = Date(), systolic systolicValue: Double, diastolic diastolicValue: Double, completion completionBlock: @escaping (Bool, Error?) -> Void) {
		let unit = HKUnit.millimeterOfMercury()

		let systolicQuantity = HKQuantity(unit: unit, doubleValue: systolicValue)
		let diastolicQuantity = HKQuantity(unit: unit, doubleValue: diastolicValue)

		let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
		let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!

		let systolicSample = HKQuantitySample(type: systolicType, quantity: systolicQuantity, start: date, end: date)
		let diastolicSample = HKQuantitySample(type: diastolicType, quantity: diastolicQuantity, start: date, end: date)

		let objects: Set<HKSample> = [systolicSample, diastolicSample]
		let type = HKObjectType.correlationType(forIdentifier: .bloodPressure)!
		let correlation = HKCorrelation(type: type, start: date, end: date, objects: objects)

		self.healthKitStore.save(correlation) { (success, error) -> Void in
			if !success {
				print("An error occured saving the Blood pressure sample \(systolicSample). In your app, try to handle this gracefully. The error was: \(error).")
			}
			completionBlock(success, error)
		}
	}
}
