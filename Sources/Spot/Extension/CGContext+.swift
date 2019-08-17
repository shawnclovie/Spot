//
//  CGContext+extension.swift
//  Spot
//
//  Created by Shawn Clovie on 28/10/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import CoreGraphics

extension CGContext {
	public static func spot<T>(width: Int, height: Int,
							   alpha: CGImageAlphaInfo = .premultipliedFirst,
							   invoking: (CGContext)->T?) -> T? {
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		if let ctx = CGContext(data: nil, width: width, height: height,
		                       bitsPerComponent: Int(CHAR_BIT),
		                       bytesPerRow: Int(CHAR_BIT) * (colorSpace.numberOfComponents + 1) / 8 * width,
		                       space: colorSpace,
		                       bitmapInfo: CGBitmapInfo().rawValue | alpha.rawValue) {
			ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))
			return invoking(ctx)
		}
		return nil
	}
}
