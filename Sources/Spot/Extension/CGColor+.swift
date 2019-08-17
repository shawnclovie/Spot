//
//  CGColor+.swift
//  Spot
//
//  Created by Shawn Clovie on 3/11/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGColor: SuffixProtocol {}

extension Suffix where Base: CGColor {
	/// Make Image filled the color only
	///
	/// - Parameters:
	///   - width: Image width, 1 by default.
	///   - height: Image height, 1 by default.
	/// - Returns: Filled image, or nil if failed to make context or makeImage().
	public func solidImage(width: Int, height: Int) -> CGImage? {
		CGContext.spot(width: width, height: height) {
			$0.setFillColor(base)
			$0.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))
			return $0.makeImage()
		}
	}
}
