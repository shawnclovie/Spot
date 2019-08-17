//
//  CGImage+extension.swift
//  Spot
//
//  Created by Shawn Clovie on 28/10/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation
import CoreGraphics
import ImageIO
#if os(iOS)
import MobileCoreServices
import UIKit
#elseif os(macOS)
import CoreServices
#endif

public enum ImageEncoding {
	case gif, png
	case jpeg(quality: CGFloat)
}

extension CGImage: SuffixProtocol {}

extension Suffix where Base: CGImage {
	public func scalingImage(for scale: CGFloat) -> CGImage? {
		resizingImage(to: .init(width: CGFloat(base.width) * scale,
								height: CGFloat(base.height) * scale),
					  scale: 1)
	}
	
	/// Resize image to new size (with no aspect)
	///
	/// - Parameters:
	///   - newSize: New size
	///   - scale: Image scale raito, default is 0, means use main screen's scale.
	///   - alpha: Alpha option, do not support .none on iOS.
	/// - Returns: Resized image
	public func resizingImage(to newSize: CGSize, scale: CGFloat = 0,
							  alpha: CGImageAlphaInfo = .premultipliedFirst,
							  shouldFlipVertical: Bool = false,
							  closure: ((CGContext)->Void)? = nil) -> CGImage? {
		var scale = scale
		if scale == 0 {
			#if canImport(UIKit)
			scale = UIScreen.main.scale
			#else
			scale = 1
			#endif
		}
		let canvasSize = CGSize(width: newSize.width * scale, height: newSize.height * scale)
		if Int(canvasSize.width) == base.width && Int(canvasSize.height) == base.height {
			return base
		}
		return CGContext.spot(width: Int(canvasSize.width), height: Int(canvasSize.height), alpha: alpha) {
			$0.interpolationQuality = .high
			if shouldFlipVertical {
				let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1,
													 tx: 0, ty: canvasSize.height)
				$0.concatenate(flipVertical)
			}
			$0.draw(self.base, in: CGRect(origin: .zero, size: canvasSize))
			closure?($0)
			return $0.makeImage()
		}
	}
	
	#if canImport(UIKit)
	/// Encode image to data, supported format: png, jpg/jpeg, static gif.
	public func encode(as encoding: ImageEncoding, orientation: UIImage.Orientation? = nil, properties: [AnyHashable: Any] = [:]) -> Data? {
		_encode(as: encoding, orientation: (orientation?.rawValue).flatMap(ImageOrientation.init), properties: properties)
	}
	#else
	public func encode(as encoding: ImageEncoding, orientation: ImageOrientation? = nil, properties: [AnyHashable: Any] = [:]) -> Data? {
		_encode(as: encoding, orientation: orientation, properties: properties)
	}
	#endif
	
	private func _encode(as encoding: ImageEncoding, orientation: ImageOrientation? = nil, properties: [AnyHashable: Any] = [:]) -> Data? {
		var properties = properties
		let type: CFString
		switch encoding {
		case .png:
			type = kUTTypePNG
		case .jpeg(let quality):
			type = kUTTypeJPEG
			properties[kCGImageDestinationLossyCompressionQuality] = quality
		case .gif:
			type = kUTTypeGIF
		}
		guard let dataDST = CFDataCreateMutable(kCFAllocatorDefault, 0) else {return nil}
		guard let dest = CGImageDestinationCreateWithData(dataDST, type, 1, nil) else {return nil}
		properties[kCGImagePropertyPixelWidth] = base.width
		properties[kCGImagePropertyPixelHeight] = base.height
		properties[kCGImagePropertyHasAlpha] = base.alphaInfo != .none
		if let value = orientation {
			properties[kCGImagePropertyOrientation] = value.rawValue
		}
		CGImageDestinationAddImage(dest, base, properties as CFDictionary)
		CGImageDestinationFinalize(dest)
		return dataDST as Data
	}
	
	#if canImport(UIKit)
	/// Create new image by new orientation by flip or rotate.
	///
	/// - Parameter orientation: New orientation
	/// - Returns: New image if no error.
	public func oriented(by orientation: UIImage.Orientation) -> CGImage? {
		_oriented(by: ImageOrientation(rawValue: orientation.rawValue) ?? .up)
	}
	#else
	public func oriented(by orientation: ImageOrientation) -> CGImage? {
		_oriented(by: orientation)
	}
	#endif
	
	private func _oriented(by orientation: ImageOrientation) -> CGImage? {
		if orientation == .up {
			return base
		}
		var image: CGImage?
		let width = CGFloat(base.width)
		let height = CGFloat(base.height)
		var canvasWidth = width
		var canvasHeight = height
		switch orientation {
		case .left, .right, .leftMirrored, .rightMirrored:
			(canvasWidth, canvasHeight) = (canvasHeight, canvasWidth)
		default:break
		}
		CGContext.spot(width: Int(canvasWidth), height: Int(canvasHeight)) { ctx in
			// rotate anchor point: right top
			switch orientation {
			case .leftMirrored:
				ctx.rotate(by: -.pi / 2)
				ctx.scaleBy(x: 1, y: -1)
				ctx.translateBy(x: -width, y: -height)
			case .rightMirrored:
				ctx.rotate(by: .pi / 2)
				ctx.scaleBy(x: 1, y: -1)
			case .upMirrored:
				ctx.translateBy(x: width, y: 0)
				ctx.scaleBy(x: -1, y: 1)
			case .downMirrored:
				ctx.translateBy(x: 0, y: height)
				ctx.scaleBy(x: 1, y: -1)
			case .down:
				ctx.translateBy(x: width, y: height)
				ctx.rotate(by: .pi)
			case .right:
				ctx.translateBy(x: 0, y: canvasHeight)
				ctx.rotate(by: -.pi / 2)
			case .left:
				ctx.translateBy(x: canvasWidth, y: 0)
				ctx.rotate(by: .pi / 2)
			case .up:break
			}
			ctx.draw(base, in: CGRect(x: 0, y: 0, width: width, height: height))
			image = ctx.makeImage()
		}
		return image
	}
}
