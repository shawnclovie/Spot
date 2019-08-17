//
//  CGImageSource+.swift
//  Spot
//
//  Created by Shawn Clovie on 20/2/2019.
//  Copyright © 2019 Shawn Clovie. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import ImageIO

extension CGImageSource: SuffixProtocol {}

extension Suffix where Base == CGImageSource {
	
	public var count: Int {
		CGImageSourceGetCount(base)
	}
	
	public var size: CGSize {
		guard let props = CGImageSourceCopyPropertiesAtIndex(base, 0, nil) else {
			return .zero
		}
		let w: NSNumber? = props.spot.unsafeCastValue(forKey: kCGImagePropertyPixelWidth)
		let h: NSNumber? = props.spot.unsafeCastValue(forKey: kCGImagePropertyPixelHeight)
		return CGSize(width: w?.intValue ?? 0, height: h?.intValue ?? 0)
	}
	
	public var orientationRawValue: Int? {
		guard let props = CGImageSourceCopyPropertiesAtIndex(base, 0, nil) else {
			return nil
		}
		guard let v: NSNumber = props.spot.unsafeCastValue(forKey: kCGImagePropertyOrientation) else {
			return nil
		}
		return v.intValue
	}
	
	#if canImport(UIKit)
	public var orientation: UIImage.Orientation? {
		orientationRawValue.flatMap(UIImage.Orientation.init)
	}
	#endif
	
	public var type: CFString? {
		CGImageSourceGetType(base)
	}
}
