//
//  TriangleView.swift
//  ImproveHRV
//
//  Created by Jason Ho on 9/12/2016.
//  Copyright © 2016 Arefly. All rights reserved.
//

import UIKit
import Foundation

class TriangleView: UIView {
	var triangleColor: UIColor!

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = UIColor.clear
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func draw(_ rect: CGRect) {
		guard let context = UIGraphicsGetCurrentContext() else { return }

		context.beginPath()
		context.move(to: CGPoint(x: rect.minX, y: rect.minY))
		context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
		context.addLine(to: CGPoint(x: (rect.maxX / 2.0), y: rect.maxY))
		context.closePath()

		if let _ = triangleColor {
			context.setFillColor(triangleColor.cgColor)
		} else {
			context.setFillColor(UIColor.red.cgColor)
		}
		context.fillPath()
	}
}
