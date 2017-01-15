//
//  ProgressCircleView.swift
//  ImproveHRV
//
//  Created by Arefly on 1/15/17.
//  Copyright © 2017 Arefly. All rights reserved.
//

import UIKit
import Foundation

class ProgressCircleView: UIView {
	private var progressCircle = CAShapeLayer()

	init(frame: CGRect, circleColor: UIColor) {
		super.init(frame: frame)

		self.backgroundColor = UIColor.clear

		let centerPoint = CGPoint(x: self.bounds.width / 2, y: self.bounds.width / 2)
		let circleRadius: CGFloat = self.bounds.width / 2 * 0.83
		let circlePath = UIBezierPath(arcCenter: centerPoint, radius: circleRadius, startAngle: CGFloat(-0.5 * M_PI), endAngle: CGFloat(1.5 * M_PI), clockwise: true)

		progressCircle = CAShapeLayer()
		progressCircle.path = circlePath.cgPath
		progressCircle.strokeColor = circleColor.cgColor
		progressCircle.fillColor = UIColor.clear.cgColor
		progressCircle.lineWidth = 8.0
		progressCircle.strokeStart = 0.0
		progressCircle.strokeEnd = 0.0			// default nothing
		self.layer.addSublayer(progressCircle)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	func startAnimation(duration: CFTimeInterval) {
		let animation = CABasicAnimation(keyPath: "strokeEnd")
		animation.fromValue = 0.0
		animation.toValue = 1.0
		animation.duration = duration
		animation.fillMode = kCAFillModeForwards
		animation.isRemovedOnCompletion = false
		progressCircle.add(animation, forKey: "ani")
	}
}
