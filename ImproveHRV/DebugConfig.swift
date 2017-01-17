//
//  DebugConfig.swift
//  ImproveHRV
//
//  Created by Arefly on 1/17/17.
//  Copyright © 2017 Arefly. All rights reserved.
//

import Foundation

#if DEBUG
	class DebugConfig {
		static let skipRecordingAndGetResultDirectly = true

		static func getDebugECGRawData() -> [Int]? {
			var returnArray: [Int]?
			do {
				if let path = Bundle.main.path(forResource: "DebugECGRawData", ofType: "txt"){
					let data = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
					let arrayOfStrings = data.components(separatedBy: "\n")
					returnArray = arrayOfStrings.flatMap({ Int($0) })
				}
			} catch let error {
				// do something with Error
				print("getDebugECGRawData error: \(error)")
			}
			return returnArray
		}

		static let debugRecordDuration: TimeInterval? = nil
	}
#endif
