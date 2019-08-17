//
//  NSBezierPath+.swift
//  Spot
//
//  Created by Shawn Clovie on 16/02/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

#if os(macOS)
import Cocoa

extension NSBezierPath {
	public var cgPath: CGPath? {
		guard elementCount > 0 else {
			return nil
		}
		let path = CGMutablePath()
		var points = [NSPoint]()
		var didClosePath = true
		for index in 0..<elementCount {
			switch element(at: index, associatedPoints: &points) {
			case .moveTo:
				path.move(to: points[0])
			case .lineTo:
				path.addLine(to: points[0])
				didClosePath = false
			case .curveTo:
				path.addCurve(to: points[0], control1: points[1], control2: points[2])
				didClosePath = false
			case .closePath:
				fallthrough
			@unknown default:
				path.closeSubpath()
				didClosePath = true
			}
		}
		if !didClosePath {
			path.closeSubpath()
		}
		return path.copy()
	}
}
#endif
