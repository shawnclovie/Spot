//
//  UI+.swift
//  Spot
//
//  Created by Shawn Clovie on 9/10/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

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
}

public enum ImageOrientation: Int {
	case up, down, left, right
	case upMirrored, downMirrored, leftMirrored, rightMirrored
}
