//
//  CircleView.swift
//  Catnap
//
//  Created by Jason Ho on 30/8/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation

class CircleView: UIView {
	var circleColor: UIColor!

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = UIColor.clear
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func draw(_ rect: CGRect) {
		let circleNew = UIBezierPath(ovalIn: rect)
		if let _ = circleColor {
			circleColor.setFill()
		} else {
			UIColor.red.setFill()
		}
		circleNew.fill()
	}
}
