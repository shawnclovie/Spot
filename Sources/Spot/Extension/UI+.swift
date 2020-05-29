//
//  UI+.swift
//  Spot
//
//  Created by Shawn Clovie on 9/10/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import CoreGraphics

public enum ViewContentMode: Int {
	case scaleToFill
	
	/// contents scaled to fit with fixed aspect. remainder is transparent
	case scaleAspectFit
	
	/// contents scaled to fill with fixed aspect. some portion of content may be clipped.
	case scaleAspectFill
	
	/// redraw on bounds change (calls -setNeedsDisplay)
	case redraw
	
	/// contents remain same size. positioned adjusted.
	case center
	case top, bottom, left, right
	case topLeft, topRight
	case bottomLeft, bottomRight
	
	public func scale(size: CGSize, toFit fitSize: CGSize) -> CGSize {
		if size == .zero {
			return size
		}
		let raito = CGSize(width: fitSize.width / size.width,
						   height: fitSize.height / size.height)
		var fixedRaito = raito
		switch self {
		case .scaleAspectFit:
			let minRaito = min(raito.width, raito.height)
			fixedRaito.width = minRaito
			fixedRaito.height = minRaito
		case .scaleAspectFill:
			let maxRaito = max(raito.width, raito.height)
			fixedRaito.width = maxRaito
			fixedRaito.height = maxRaito
		default:break
		}
		return CGSize(width: Int(size.width * fixedRaito.width),
					  height: Int(size.height * fixedRaito.height))
	}
}

public enum ImageOrientation: Int {
	case up, down, left, right
	case upMirrored, downMirrored, leftMirrored, rightMirrored
}
