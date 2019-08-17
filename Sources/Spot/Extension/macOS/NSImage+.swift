//
//  NSImage+.swift
//  Spot
//
//  Created by Shawn Clovie on 20/02/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

#if canImport(AppKit)
import AppKit

extension NSImage {
	public var scale: CGFloat {
		1.0
	}
	
	public var cgImage: CGImage? {
		cgImage(forProposedRect: nil, context: nil, hints: nil)
	}
}

extension Suffix where Base: NSImage {
	public func encode(as encoding: ImageEncoding) -> Data? {
		base.cgImage?.spot.encode(as: encoding, orientation: .up)
	}
}
#endif
