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
		static let showTouchIndicator = true

		static let skipRecordingAndGetResultDirectly = false

		static let useDebugRawData = false
		static func getDebugRawData() -> [String]? {
			var returnArray: [String]?
			do {
				if let path = Bundle.main.path(forResource: "DebugECGRawData", ofType: "txt"){
					let data = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
					returnArray = data.components(separatedBy: "\n")
				}
			} catch let error {
				// do something with Error
				print("getDebugECGRawData error: \(error)")
			}
			return returnArray
		}

		static let debugRecordDuration: TimeInterval? = nil
		static let ignoreShortestTimeRestriction = false

		static let showBPFromThisAppOnly = false

		static let showHistoryVCCellElementsBackground = false
	}
#endif
